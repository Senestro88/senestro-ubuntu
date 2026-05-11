#!/bin/bash
# =============================================================================
# senestro-ubuntu/distro/user.sh
# Run INSIDE the Ubuntu proot container (as root) via: bash user.sh
# Creates a sudo user, sets password, and installs gui.sh for that user.
# =============================================================================

# ANSI color codes
R="$(printf '\033[1;31m')"   # Red
G="$(printf '\033[1;32m')"   # Green
Y="$(printf '\033[1;33m')"   # Yellow
W="$(printf '\033[1;37m')"   # White
C="$(printf '\033[1;36m')"   # Cyan

# -----------------------------------------------------------------------------
# banner: Display the project header
# -----------------------------------------------------------------------------
banner() {
    clear
    printf "\033[33m    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  \033[0m\n"
    printf "\033[36m    |  | |__] |  | |\\ |  |  |  |    |\\/| |  | |  \\ \033[0m\n"
    printf "\033[32m    |__| |__] |__| | \\|  |  |__|    |  | |__| |__/ \033[0m\n"
    echo
    printf "\033[32m Ubuntu GUI environment for Termux\033[0m\n"
    printf "\033[0m\n"
}

# -----------------------------------------------------------------------------
# sudo_setup: Update apt and install essential packages inside Ubuntu.
# Includes sudo, wget, locales, dialog, and tzdata for timezone support.
# -----------------------------------------------------------------------------
sudo_setup() {
    echo -e "\n${R} [${W}-${R}]${C} Installing required packages inside Ubuntu..."${W}
    apt update -y
    apt install sudo -y
    apt install wget apt-utils locales-all dialog tzdata -y
    echo -e "\n${R} [${W}-${R}]${G} Required packages installed successfully."${W}
}

# -----------------------------------------------------------------------------
# install_desktop: Install XFCE4 as root so Termux-X11 can launch the desktop
# without needing a sudo user. This runs before user creation intentionally —
# x11start-senestro-ubuntu logs in as root (proot-distro login ubuntu, no
# --user flag), so XFCE4 must be present at the root level.
# -----------------------------------------------------------------------------
install_desktop() {
    banner
    echo -e "\n${R} [${W}-${R}]${C} Installing XFCE4 desktop (required for Termux-X11)..."${W}
    apt update -y
    apt install -y --no-install-recommends xfce4 xfce4-goodies dbus-x11
    echo -e "\n${R} [${W}-${R}]${G} XFCE4 installed successfully."${W}
}

# -----------------------------------------------------------------------------
# set_root_password: Prompt the user to set a password for the root account.
# Required so that su/sudo operations work correctly inside the container and
# so the root desktop session is protected.
# -----------------------------------------------------------------------------
set_root_password() {
    banner
    echo -e "\n${R} [${W}-${R}]${C} Set a password for the root (su) account."${W}
    echo -e " ${Y} This is used for su/sudo inside Ubuntu.\n"${W}

    while true; do
        read -s -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Enter root password: \e[0m\e[1;96m' root_pass
        echo
        read -s -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Confirm root password: \e[0m\e[1;96m' root_pass2
        echo -e "${W}"
        if [[ "$root_pass" == "$root_pass2" ]]; then
            echo "root:${root_pass}" | chpasswd
            echo -e "\n${R} [${W}-${R}]${G} Root password set successfully."${W}
            break
        else
            echo -e "\n${Y} [!] Passwords do not match. Please try again.\n"${W}
        fi
    done
}

# -----------------------------------------------------------------------------
# login: Prompt for a username and password, create the user with sudo rights,
# write the proot login command to the Termux `ubuntu` launcher, and install gui.sh.
# -----------------------------------------------------------------------------
login() {
    banner

    # Read username (must be lowercase, no spaces)
    read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Enter a username (lowercase, no spaces): \e[0m\e[1;96m\en' user
    echo -e "${W}"

    # Read password (hidden input)
    read -s -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Enter a password: \e[0m\e[1;96m' pass
    echo -e "${W}"

    # Create user with bash as default shell and add to sudo group
    useradd -m -s "$(which bash)" "${user}"
    usermod -aG sudo "${user}"
    echo "${user}:${pass}" | chpasswd

    # Grant passwordless sudo to this user
    echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

    # Overwrite the Termux `senestro-ubuntu` launcher with a proper proot login command
    # --bind /dev/null:/proc/sys/kernel/cap_last_last  : avoids capability read errors
    # --shared-tmp                                      : share /tmp with Termux
    # --fix-low-ports                                   : allow binding to ports <1024 (optional, version-dependent)
    #
    # Detect whether this proot-distro build supports --fix-low-ports before using it.
    FIXPORTS_FLAG=""
    if proot-distro login --help 2>&1 | grep -q 'fix-low-ports'; then
        FIXPORTS_FLAG="--fix-low-ports"
    fi
    echo "proot-distro login --user $user ubuntu --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp $FIXPORTS_FLAG" \
        > /data/data/com.termux/files/usr/bin/senestro-ubuntu

    # FIX: make the launcher executable (was commented out in original)
    chmod +x /data/data/com.termux/files/usr/bin/senestro-ubuntu

    # Copy or download gui.sh into the new user's home directory
    if [[ -e '/data/data/com.termux/files/home/senestro-ubuntu/distro/gui.sh' ]]; then
        cp /data/data/com.termux/files/home/senestro-ubuntu/distro/gui.sh /home/$user/gui.sh
        chmod +x /home/$user/gui.sh
    else
        wget -q --show-progress https://raw.githubusercontent.com/Senestro88/senestro-ubuntu/refs/heads/main/distro/gui.sh
        mv -vf gui.sh /home/$user/gui.sh
        chmod +x /home/$user/gui.sh
    fi

    clear
    echo
    echo -e "\n${R} [${W}-${R}]${G} Restart Termux, then run ${C}senestro-ubuntu"${W}
    echo -e "\n${R} [${W}-${R}]${G} Next, run ${C}sudo bash gui.sh"${W}
    echo
}

# --- Main execution order ---
banner
sudo_setup
install_desktop
set_root_password
login