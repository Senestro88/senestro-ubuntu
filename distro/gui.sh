#!/bin/bash
# =============================================================================
# senestro-ubuntu/distro/gui.sh
# Run INSIDE Ubuntu as the sudo user: `sudo bash gui.sh`
# Installs XFCE4 desktop, media players, themes, fonts, wallpapers,
# and configures PulseAudio sound forwarding.
# =============================================================================

# ANSI color codes
R="$(printf '\033[1;31m')"   # Red
G="$(printf '\033[1;32m')"   # Green
Y="$(printf '\033[1;33m')"   # Yellow
W="$(printf '\033[1;37m')"   # White
C="$(printf '\033[1;36m')"   # Cyan

# Detect CPU architecture (e.g. aarch64, armv7l, x86_64)
arch=$(uname -m)

# Resolve the first sudo user (used for home directory operations later)
username=$(getent group sudo | awk -F ':' '{print $4}' | cut -d ',' -f1)

# -----------------------------------------------------------------------------
# check_root: Abort if not running as root (required for apt and user installs)
# -----------------------------------------------------------------------------
check_root() {
	if [ "$(id -u)" -ne 0 ]; then
		echo -ne " ${R}This script must be run as root. Please use: sudo bash gui.sh\n\n"${W}
		exit 1
	fi
}

# -----------------------------------------------------------------------------
# banner: Display the project ASCII header
# -----------------------------------------------------------------------------
banner() {
	clear
	cat <<- EOF
		${Y}    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  
		${C}    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \ 
		${G}    |__| |__] |__| | \|  |  |__|    |  | |__| |__/ 
	EOF
	echo
	echo -e "${G} Ubuntu GUI environment for Termux\n"
}

# -----------------------------------------------------------------------------
# note: Print post-install instructions for starting the desktop
# -----------------------------------------------------------------------------
note() {
	banner
	echo -e " ${G} [-] Installation completed successfully.\n"${W}
	sleep 1
	cat <<- EOF
		 ${G}[-] Termux-X11 Mode:
		 ${G}    Exit Ubuntu, then run ${C}x11start-senestro-ubuntu${G} in Termux.
		 ${G}    Run ${C}x11stop-senestro-ubuntu${G} in Termux to stop the session.

		 ${C}Install the Termux-X11 companion app on your Android device.

		 ${C}Run ${C}x11start-senestro-ubuntu${G} in Termux, then open the Termux-X11 app to view the desktop.

		 ${C}Your Ubuntu GUI is ready to use.${W}
	EOF
}

# -----------------------------------------------------------------------------
# package: Install core desktop packages via apt.
# udisks2 needs special handling: its postinst script fails inside proot,
# so we blank it out and run dpkg --configure manually, then hold the package
# to prevent apt from trying to re-run its postinst on upgrades.
# -----------------------------------------------------------------------------
package() {
	banner
	echo -e "${R} [${W}-${R}]${C} Checking required packages..."${W}
	apt-get update -y

	# Install udisks2 separately — its postinst fails in proot containers
	apt install udisks2 -y
	rm /var/lib/dpkg/info/udisks2.postinst        # Remove the broken postinst
	echo "" > /var/lib/dpkg/info/udisks2.postinst  # Replace with empty no-op
	dpkg --configure -a                            # Finish pending configurations
	apt-mark hold udisks2                          # Prevent future postinst re-runs

	# Core desktop packages
	# - xfce4 / xfce4-goodies: lightweight desktop environment
	# - fonts-beng / fonts-beng-extra: Bengali font support
	# - at-spi2-core: accessibility infrastructure (required by some XFCE components)
	# - apt-transport-https: allows apt to use HTTPS sources
	packs=(sudo gnupg2 curl nano git xz-utils at-spi2-core xfce4 xfce4-goodies \
		xfce4-terminal librsvg2-common menu inetutils-tools dialog exo-utils \
		dbus-x11 fonts-beng fonts-beng-extra gtk2-engines-murrine gtk2-engines-pixbuf \
		apt-transport-https xorg-xserver-xephyr)

	echo -e "\n${R} [${W}-${R}]${G} Installing packages: ${Y}${packs[*]}${W}\n"
	apt-get install -y --no-install-recommends "${packs[@]}"

	apt-get update -y
	apt-get upgrade -y
}

# -----------------------------------------------------------------------------
# install_apt: Generic helper to install one or more apt packages by name.
# Skips packages already found in PATH.
# -----------------------------------------------------------------------------
install_apt() {
	for apt in "$@"; do
		[[ $(command -v "$apt") ]] && \
			echo "${Y}${apt} is already installed.${W}" || {
			echo -e "${G}Installing ${Y}${apt}${W}"
			apt install -y "${apt}"
		}
	done
}

# -----------------------------------------------------------------------------
# install_media: Interactive menu to select and install a media player.
# -----------------------------------------------------------------------------
install_media() {
	banner
	cat <<- EOF
		${Y} ---${G} Media Player ${Y}---

		${C} [${W}1${C}] MPV Media Player (Recommended)
		${C} [${W}2${C}] VLC Media Player
		${C} [${W}3${C}] Both (MPV + VLC)
		${C} [${W}4${C}] Skip! (Default)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" PLAYER_OPTION
	{ banner; sleep 1; }

	# Install selected media player
	if [[ ${PLAYER_OPTION} == 1 ]]; then
		install_apt "mpv"
	elif [[ ${PLAYER_OPTION} == 2 ]]; then
		install_apt "vlc"
	elif [[ ${PLAYER_OPTION} == 3 ]]; then
		install_apt "mpv" "vlc"
	else
		echo -e "${Y} [!] Skipping media player installation.\n"
		sleep 1
	fi
}

# -----------------------------------------------------------------------------
# downloader: Download file from $2 to path $1 with retry logic.
# --insecure: skips SSL verification (needed in some proot environments).
# -----------------------------------------------------------------------------
downloader() {
	local path="$1"
	local url="$2"
	[[ -e "$path" ]] && rm -rf "$path"
	echo "Downloading $(basename "$path")..."
	curl --progress-bar --insecure --fail \
		 --retry-connrefused --retry 3 --retry-delay 2 \
		 --location --output "${path}" "${url}"
}

# -----------------------------------------------------------------------------
# sound_fix: Prepend `bash ~/.sound` to the ubuntu Termux launcher so that
# PulseAudio forwarding is started when the container is entered.
# DISPLAY and PULSE_SERVER are set only in x11start-senestro-ubuntu, not in
# /etc/profile, to avoid PulseAudio warnings on every plain login.
# -----------------------------------------------------------------------------
sound_fix() {
	# Prepend sound startup to the Termux `senestro-ubuntu` launcher
	echo "$(echo "bash ~/.sound" | cat - /data/data/com.termux/files/usr/bin/senestro-ubuntu)" \
		> /data/data/com.termux/files/usr/bin/senestro-ubuntu
}

# -----------------------------------------------------------------------------
# rem_theme: Remove unused XFCE themes to reduce disk usage.
# FIX: original used `type -p` (checks PATH for executables) on theme directory
#      names — theme names are never in PATH, so the check always failed and
#      nothing was deleted. Corrected to use `[ -d ... ]` (directory existence).
# -----------------------------------------------------------------------------
rem_theme() {
	theme=(Bright Daloa Emacs Moheli Retro Smoke)
	for rmi in "${theme[@]}"; do
		# Remove the theme directory if it exists (was: wrongly using type -p)
		[ -d "/usr/share/themes/$rmi" ] && rm -rf "/usr/share/themes/${rmi}"
	done
}

# -----------------------------------------------------------------------------
# rem_icon: Remove unused icon sets to reduce disk usage.
# FIX: same type -p bug as rem_theme — corrected to [ -d ... ].
# -----------------------------------------------------------------------------
rem_icon() {
	icons=(hicolor LoginIcons ubuntu-mono-light)
	for rmf in "${icons[@]}"; do
		# Remove the icon directory if it exists (was: wrongly using type -p)
		[ -d "/usr/share/icons/$rmf" ] && rm -rf "/usr/share/icons/${rmf}"
	done
}

# -----------------------------------------------------------------------------
# config: Download and apply themes, icons, wallpapers, and fonts.
# Also imports a GPG key for future use, runs final system upgrade, and cleans up.
# -----------------------------------------------------------------------------
config() {
	banner
	sound_fix

	# Import a GPG key used by some packages during upgrade.
	# FIX: apt-key is deprecated and removed in Ubuntu 22.04+.
	# Replaced with gpg --keyserver fetch written directly to /etc/apt/trusted.gpg.d/.
	gpg --no-default-keyring \
	    --keyring /etc/apt/trusted.gpg.d/ubuntu-archive-extra.gpg \
	    --keyserver keyserver.ubuntu.com \
	    --recv-keys 3B4FE6ACC0B21F32

	yes | apt upgrade

	# Install theme build dependencies
	yes | apt install gtk2-engines-murrine gtk2-engines-pixbuf sassc optipng inkscape libglib2.0-dev-bin

	# Back up the default XFCE wallpaper before replacing it
	mv -vf /usr/share/backgrounds/xfce/xfce-verticals.png \
		/usr/share/backgrounds/xfce/xfceverticals-old.png

	# Create a temporary working directory for downloads
	temp_folder=$(mktemp -d -p "$HOME")
	{ banner; sleep 1; cd "$temp_folder"; }

	echo -e "${R} [${W}-${R}]${C} Downloading required configuration files...\n"${W}
	downloader "fonts.tar.gz"           "https://raw.githubusercontent.com/Senestro88/assets/refs/heads/main/senestro-ubuntu/fonts.tar.gz"
	downloader "icons.tar.gz"           "https://raw.githubusercontent.com/Senestro88/assets/refs/heads/main/senestro-ubuntu/icons.tar.gz"
	downloader "wallpaper.tar.gz"       "https://raw.githubusercontent.com/Senestro88/assets/refs/heads/main/senestro-ubuntu/wallpaper.tar.gz"
	downloader "gtk-themes.tar.gz"      "https://raw.githubusercontent.com/Senestro88/assets/refs/heads/main/senestro-ubuntu/gtk-themes.tar.gz"
	downloader "ubuntu-settings.tar.gz" "https://raw.githubusercontent.com/Senestro88/assets/refs/heads/main/senestro-ubuntu/ubuntu-settings.tar.gz"

	echo -e "${R} [${W}-${R}]${C} Extracting downloaded archives...\n"${W}
	tar -xvzf fonts.tar.gz           -C "/usr/local/share/fonts/"
	tar -xvzf icons.tar.gz           -C "/usr/share/icons/"
	tar -xvzf wallpaper.tar.gz       -C "/usr/share/backgrounds/xfce/"
	tar -xvzf gtk-themes.tar.gz      -C "/usr/share/themes/"
	tar -xvzf ubuntu-settings.tar.gz -C "/home/$username/"

	# Clean up temp download directory
	rm -fr "$temp_folder"

	echo -e "${R} [${W}-${R}]${C} Removing unused themes and icons..."${W}
	rem_theme
	rem_icon

	echo -e "${R} [${W}-${R}]${C} Rebuilding the font cache...\n"${W}
	fc-cache -fv

	echo -e "${R} [${W}-${R}]${C} Performing final system upgrade...\n"${W}
	apt update
	yes | apt upgrade
	apt clean
	yes | apt autoremove
}

# --- Main execution order ---
check_root
package
install_media
config
note
