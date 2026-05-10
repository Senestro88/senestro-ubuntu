#!/bin/bash
# =============================================================================
# senestro-ubuntu/setup.sh
# Main entry point. Run this in Termux to install Ubuntu via proot-distro.
# Steps: install Termux packages → install Ubuntu distro → fix sound → setup env
# =============================================================================

# ANSI color codes for terminal output
R="$(printf '\033[1;31m')"   # Red
G="$(printf '\033[1;32m')"   # Green
Y="$(printf '\033[1;33m')"   # Yellow
B="$(printf '\033[1;34m')"   # Blue
C="$(printf '\033[1;36m')"   # Cyan
W="$(printf '\033[1;37m')"   # White

# Absolute path of this script's directory (handles symlinks safely)
CURR_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

# Root of the proot-distro Ubuntu installation inside Termux
UBUNTU_DIR="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

# -----------------------------------------------------------------------------
# banner: Clear screen and print the project ASCII header
# -----------------------------------------------------------------------------
banner() {
	clear
	cat <<- EOF
		${Y}    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  
		${C}    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \ 
		${G}    |__| |__] |__| | \|  |  |__|    |  | |__| |__/ 

	EOF
	echo -e "${G}     A modded gui version of ubuntu for Termux\n\n"${W}
}

# -----------------------------------------------------------------------------
# package: Ensure required Termux packages are installed.
# Required: pulseaudio (sound), proot-distro (Ubuntu container)
# -----------------------------------------------------------------------------
package() {
	banner
	echo -e "${R} [${W}-${R}]${C} Checking required packages..."${W}

	# Request storage access if not already granted
	[ ! -d '/data/data/com.termux/files/home/storage' ] && \
		echo -e "${R} [${W}-${R}]${C} Setting up Storage.."${W} && \
		termux-setup-storage

	if [[ $(command -v pulseaudio) && $(command -v proot-distro) ]]; then
		# Both packages already present — skip install
		echo -e "\n${R} [${W}-${R}]${G} Packages already installed."${W}
	else
		# Upgrade existing packages first, then install missing ones
		yes | pkg upgrade
		packs=(pulseaudio proot-distro)
		for x in "${packs[@]}"; do
			type -p "$x" &>/dev/null || {
				echo -e "\n${R} [${W}-${R}]${G} Installing package : ${Y}$x${C}"${W}
				yes | pkg install "$x"
			}
		done
	fi
}

# -----------------------------------------------------------------------------
# distro: Install the Ubuntu proot-distro image if not already present.
# Exits early (0) if already installed.
# -----------------------------------------------------------------------------
distro() {
	echo -e "\n${R} [${W}-${R}]${C} Checking for Distro..."${W}
	termux-reload-settings

	if [[ -d "$UBUNTU_DIR" ]]; then
		# Already installed — nothing to do
		echo -e "\n${R} [${W}-${R}]${G} Distro already installed."${W}
		exit 0
	else
		proot-distro install ubuntu
		termux-reload-settings
	fi

	# Verify installation succeeded
	if [[ -d "$UBUNTU_DIR" ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Installed Successfully !!"${W}
	else
		echo -e "\n${R} [${W}-${R}]${G} Error Installing Distro !\n"${W}
		exit 1
	fi
}

# -----------------------------------------------------------------------------
# sound: Write PulseAudio startup commands to ~/.sound
# These are sourced later by gui.sh's sound_fix() inside the Ubuntu container.
# Note: module-aaudio-sink is Android-specific; it will be ignored on non-Android hosts.
# -----------------------------------------------------------------------------
sound() {
	echo -e "\n${R} [${W}-${R}]${C} Fixing Sound Problem..."${W}

	# Create ~/.sound if it doesn't exist
	[ ! -e "$HOME/.sound" ] && touch "$HOME/.sound"

	# Load Android audio sink module (Android/Termux only)
	echo "pacmd load-module module-aaudio-sink" >> "$HOME/.sound"

	# Start PulseAudio as a daemon that never exits on idle
	echo "pulseaudio --start --exit-idle-time=-1" >> "$HOME/.sound"

	# Expose PulseAudio over TCP on localhost for the VNC session
	echo "pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >> "$HOME/.sound"
}

# -----------------------------------------------------------------------------
# downloader: Download a file from $2 and save to path $1.
# Removes existing file at $1 before downloading.
# Uses curl with retry logic; --insecure skips SSL verification (needed in some Termux envs).
# -----------------------------------------------------------------------------
downloader() {
	local path="$1"
	local url="$2"

	# Remove stale file if it exists
	[ -e "$path" ] && rm -rf "$path"

	echo "Downloading $(basename "$path")..."
	curl --progress-bar --insecure --fail \
		 --retry-connrefused --retry 3 --retry-delay 2 \
		 --location --output "${path}" "${url}"
	echo
}

# -----------------------------------------------------------------------------
# setup_vnc: Copy or download vncstart and vncstop launcher scripts.
# Prefers local distro/ copies; falls back to downloading from GitHub.
# -----------------------------------------------------------------------------
setup_vnc() {
	# --- vncstart ---
	if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/vncstart" ]]; then
		cp -f "$CURR_DIR/distro/vncstart" "$UBUNTU_DIR/usr/local/bin/vncstart"
	else
		downloader "$CURR_DIR/vncstart" "https://raw.githubusercontent.com/senestro-ubuntu/senestro-ubuntu/master/distro/vncstart"
		mv -f "$CURR_DIR/vncstart" "$UBUNTU_DIR/usr/local/bin/vncstart"
	fi

	# --- vncstop ---
	if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/vncstop" ]]; then
		cp -f "$CURR_DIR/distro/vncstop" "$UBUNTU_DIR/usr/local/bin/vncstop"
	else
		downloader "$CURR_DIR/vncstop" "https://raw.githubusercontent.com/senestro-ubuntu/senestro-ubuntu/master/distro/vncstop"
		mv -f "$CURR_DIR/vncstop" "$UBUNTU_DIR/usr/local/bin/vncstop"
	fi

	# Make both scripts executable
	chmod +x "$UBUNTU_DIR/usr/local/bin/vncstart"
	chmod +x "$UBUNTU_DIR/usr/local/bin/vncstop"
}

# -----------------------------------------------------------------------------
# permission: Install user.sh inside Ubuntu, create the `ubuntu` launcher,
# set timezone, and print final instructions.
# -----------------------------------------------------------------------------
permission() {
	banner
	echo -e "${R} [${W}-${R}]${C} Setting up Environment..."${W}

	# Copy or download user.sh (user/GUI setup script run inside Ubuntu)
	if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/user.sh" ]]; then
		cp -f "$CURR_DIR/distro/user.sh" "$UBUNTU_DIR/root/user.sh"
	else
		downloader "$CURR_DIR/user.sh" "https://raw.githubusercontent.com/senestro-ubuntu/senestro-ubuntu/master/distro/user.sh"
		mv -f "$CURR_DIR/user.sh" "$UBUNTU_DIR/root/user.sh"
	fi
	chmod +x "$UBUNTU_DIR/root/user.sh"

	# Set up VNC launcher scripts inside Ubuntu
	setup_vnc

	# Mirror the host Android timezone into the Ubuntu container
	echo "$(getprop persist.sys.timezone)" > "$UBUNTU_DIR/etc/timezone"

	# Create the `ubuntu` shortcut command in Termux's PATH
	echo "proot-distro login ubuntu" > "$PREFIX/bin/ubuntu"
	chmod +x "$PREFIX/bin/ubuntu"

	termux-reload-settings

	if [[ -e "$PREFIX/bin/ubuntu" ]]; then
		banner
		cat <<- EOF
			${R} [${W}-${R}]${G} Ubuntu-22.04 (CLI) is now Installed on your Termux
			${R} [${W}-${R}]${G} Restart your Termux to Prevent Some Issues.
			${R} [${W}-${R}]${G} Type ${C}ubuntu${G} to run Ubuntu CLI.
			${R} [${W}-${R}]${G} If you Want to Use UBUNTU in GUI MODE then ,
			${R} [${W}-${R}]${G} Run ${C}ubuntu${G} first & then type ${C}bash user.sh${W}
		EOF
		# Sleep before exit so the user can read the message; exit 0 = success
		{ echo; sleep 2; exit 0; }
	else
		echo -e "\n${R} [${W}-${R}]${G} Error Installing Distro !"${W}
		exit 1
	fi
}

# --- Main execution order ---
package
distro
sound
permission
