#!/bin/bash
# =============================================================================
# senestro-ubuntu/distro/gui.sh
# Run INSIDE Ubuntu as the sudo user: `sudo bash gui.sh`
# Installs XFCE4 desktop, TigerVNC, optional browsers, IDEs, media players,
# themes, fonts, wallpapers, and configures PulseAudio sound forwarding.
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
	echo -e "${G} Ubuntu GUI environment for Termux\n"
}

# -----------------------------------------------------------------------------
# note: Print post-install instructions for connecting via VNC Viewer
# -----------------------------------------------------------------------------
note() {
	banner
	echo -e " ${G} [-] Installation completed successfully.\n"${W}
	sleep 1
	cat <<- EOF
		 ${G}[-] Run ${C}vncstart${G} to start the VNC server.
		 ${G}[-] Run ${C}vncstop${G} to stop the VNC server.

		 ${C}Install VNC Viewer on your Android device.

		 ${C}Open VNC Viewer and tap the + button.

		 ${C}Enter the address localhost:1 and assign any name to the connection.

		 ${C}Set the picture quality to High for the best visual experience.

		 ${C}Tap Connect and enter your VNC password when prompted.

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

	# Core desktop + VNC packages
	# - xfce4 / xfce4-goodies: lightweight desktop environment
	# - tigervnc-*: VNC server for remote GUI access
	# - fonts-beng / fonts-beng-extra: Bengali font support
	# - at-spi2-core: accessibility infrastructure (required by some XFCE components)
	# - apt-transport-https: allows apt to use HTTPS sources
	packs=(sudo gnupg2 curl nano git xz-utils at-spi2-core xfce4 xfce4-goodies \
		xfce4-terminal librsvg2-common menu inetutils-tools dialog exo-utils \
		tigervnc-standalone-server tigervnc-common tigervnc-tools dbus-x11 \
		fonts-beng fonts-beng-extra gtk2-engines-murrine gtk2-engines-pixbuf \
		apt-transport-https)

	for hulu in "${packs[@]}"; do
		type -p "$hulu" &>/dev/null || {
			echo -e "\n${R} [${W}-${R}]${G} Installing package : ${Y}$hulu${W}"
			apt-get install "$hulu" -y --no-install-recommends
		}
	done

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
# install_vscode: Add Microsoft's apt repo and install Visual Studio Code.
# Note: VSCode is x86_64 / arm64 / armhf only — may be buggy on some ARM builds.
# Patches code.desktop to add --no-sandbox (required in proot containers).
# -----------------------------------------------------------------------------
install_vscode() {
	[[ $(command -v code) ]] && echo "${Y}Visual Studio Code is already installed.${W}" || {
		echo -e "${G}Installing ${Y}Visual Studio Code${W}"

		# Import Microsoft GPG key and add their apt repository
		curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
		install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
		echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
			> /etc/apt/sources.list.d/vscode.list
		apt update -y
		apt install code -y

		# Apply desktop entry patch to add --no-sandbox flag (required in proot)
		echo "Applying desktop entry patch..."
		curl -fsSL https://raw.githubusercontent.com/Senestro88/senestro-ubuntu/refs/heads/main/patches/code.desktop \
			> /usr/share/applications/code.desktop
		echo -e "${C} Visual Studio Code installed successfully.\n${W}"
	}
}

# -----------------------------------------------------------------------------
# install_sublime: Add Sublime Text's apt repo and install Sublime Text.
# Recommended for arm64/aarch64 where VSCode may be unstable.
# -----------------------------------------------------------------------------
install_sublime() {
	[[ $(command -v subl) ]] && echo "${Y}Sublime Text is already installed.${W}" || {
		apt install gnupg2 software-properties-common --no-install-recommends -y
		echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
		curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/sublime.gpg 2> /dev/null
		apt update -y
		apt install sublime-text -y
		echo -e "${C} Sublime Text Editor installed successfully.\n${W}"
	}
}

# -----------------------------------------------------------------------------
# install_chromium: Install Chromium browser.
# Uses the standard Ubuntu apt repository (chromium package).
# Patches the .desktop entry to add --no-sandbox (required in proot/non-root).
# NOTE: Removed deprecated Debian buster repo and deprecated apt-key usage.
# -----------------------------------------------------------------------------
install_chromium() {
	[[ $(command -v chromium) ]] && echo "${Y}Chromium is already Installed!${W}\n" || {
		echo -e "${G}Installing ${Y}Chromium${W}"

		# Remove any conflicting snap-managed chromium packages
		apt purge chromium* chromium-browser* snapd -y

		apt-get update -y
		apt install chromium-browser -y

		# Patch .desktop file to add --no-sandbox so Chromium works inside proot
		sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop 2>/dev/null
		sed -i 's/chromium-browser %U/chromium-browser --no-sandbox %U/g' /usr/share/applications/chromium-browser.desktop 2>/dev/null
		echo -e "${G} Chromium installed successfully.\n${W}"
	}
}

# -----------------------------------------------------------------------------
# install_firefox: Install Firefox via the Mozilla Team PPA.
# Delegates to firefox.sh which handles PPA setup and key import.
# -----------------------------------------------------------------------------
install_firefox() {
	[[ $(command -v firefox) ]] && echo "${Y}Firefox is already Installed!${W}\n" || {
		echo -e "${G}Installing ${Y}Firefox${W}"
		bash <(curl -fsSL "https://raw.githubusercontent.com/Senestro88/senestro-ubuntu/refs/heads/main/distro/firefox.sh")
		echo -e "${G} Firefox Installed Successfully\n${W}"
	}
}

# -----------------------------------------------------------------------------
# install_softwares: Interactive menu to select browser, IDE, and media player.
# FIX: arch check condition changed from || (always true) to && (correct logic).
#      With ||, the IDE menu showed even on armhf/armv7 — now correctly hidden.
# -----------------------------------------------------------------------------
install_softwares() {
	banner
	cat <<- EOF
		${Y} ---${G} Select Browser ${Y}---

		${C} [${W}1${C}] Firefox (Default)
		${C} [${W}2${C}] Chromium
		${C} [${W}3${C}] Both (Firefox + Chromium)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" BROWSER_OPTION
	banner

	# Only show IDE options on 64-bit architectures (armhf/armv7 not supported)
	# FIX: was [[ ... || ... ]] which is always true; corrected to [[ ... && ... ]]
	[[ ("$arch" != 'armhf') && ("$arch" != *'armv7'*) ]] && {
		cat <<- EOF
			${Y} ---${G} Select IDE ${Y}---

			${C} [${W}1${C}] Sublime Text Editor (Recommended)
			${C} [${W}2${C}] Visual Studio Code
			${C} [${W}3${C}] Both (Sublime + VSCode)
			${C} [${W}4${C}] Skip! (Default)

		EOF
		read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" IDE_OPTION
		banner
	}

	cat <<- EOF
		${Y} ---${G} Media Player ${Y}---

		${C} [${W}1${C}] MPV Media Player (Recommended)
		${C} [${W}2${C}] VLC Media Player
		${C} [${W}3${C}] Both (MPV + VLC)
		${C} [${W}4${C}] Skip! (Default)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" PLAYER_OPTION
	{ banner; sleep 1; }

	# Install selected browser
	if [[ ${BROWSER_OPTION} == 2 ]]; then
		install_chromium
	elif [[ ${BROWSER_OPTION} == 3 ]]; then
		install_firefox
		install_chromium
	else
		install_firefox   # Default: Firefox
	fi

	# Install selected IDE (only on supported architectures)
	[[ ("$arch" != 'armhf') && ("$arch" != *'armv7'*) ]] && {
		if [[ ${IDE_OPTION} == 1 ]]; then
			install_sublime
		elif [[ ${IDE_OPTION} == 2 ]]; then
			install_vscode
		elif [[ ${IDE_OPTION} == 3 ]]; then
			install_sublime
			install_vscode
		else
			echo -e "${Y} [!] Skipping IDE installation.\n"
			sleep 1
		fi
	}

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
# sound_fix: Wire PulseAudio sound from Termux into the Ubuntu session.
# Prepends `bash ~/.sound` to the ubuntu launcher so sound starts on login.
# Also exports DISPLAY and PULSE_SERVER for the X/VNC session.
# -----------------------------------------------------------------------------
sound_fix() {
	# Prepend sound startup to the Termux `ubuntu` launcher
	echo "$(echo "bash ~/.sound" | cat - /data/data/com.termux/files/usr/bin/ubuntu)" \
		> /data/data/com.termux/files/usr/bin/ubuntu

	# Set the VNC display environment variable for all sessions
	echo 'export DISPLAY=":1"' >> /etc/profile

	# Point PulseAudio client to the Termux TCP server
	echo "export PULSE_SERVER=127.0.0.1" >> /etc/profile

	source /etc/profile
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

	# Import a GPG key used by some packages during upgrade
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32

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
install_softwares
config
note
