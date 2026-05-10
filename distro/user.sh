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
    printf "\033[0m\n"
    printf "     \033[32mA modded gui version of ubuntu for Termux\033[0m\n"
    printf "\033[0m\n"
}

# -----------------------------------------------------------------------------
# sudo_setup: Update apt and install essential packages inside Ubuntu.
# Includes sudo, wget, locales, dialog, and tzdata for timezone support.
# -----------------------------------------------------------------------------
sudo_setup() {
    echo -e "\n${R} [${W}-${R}]${C} Installing Sudo..."${W}
    apt update -y
    apt install sudo -y
    apt install wget apt-utils locales-all dialog tzdata -y
    echo -e "\n${R} [${W}-${R}]${G} Sudo Successfully Installed !"${W}
}

# -----------------------------------------------------------------------------
# login: Prompt for a username and password, create the user with sudo rights,
# write the proot login command to the Termux `ubuntu` launcher, and install gui.sh.
# -----------------------------------------------------------------------------
login() {
    banner

    # Read username (must be lowercase, no spaces)
    read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Username [Lowercase] : \e[0m\e[1;96m\en' user
    echo -e "${W}"

    # Read password
    read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Password : \e[0m\e[1;96m\en' pass
    echo -e "${W}"

    # Create user with bash as default shell and add to sudo group
    useradd -m -s "$(which bash)" "${user}"
    usermod -aG sudo "${user}"
    echo "${user}:${pass}" | chpasswd

    # Grant passwordless sudo to this user
    echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

    # Overwrite the Termux `ubuntu` launcher with a proper proot login command
    # --bind /dev/null:/proc/sys/kernel/cap_last_last  : avoids capability read errors
    # --shared-tmp                                      : share /tmp with Termux
    # --fix-low-ports                                   : allow binding to ports <1024
    echo "proot-distro login --user $user ubuntu --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp --fix-low-ports" \
        > /data/data/com.termux/files/usr/bin/ubuntu

    # FIX: make the launcher executable (was commented out in original)
    chmod +x /data/data/com.termux/files/usr/bin/ubuntu

    # Copy or download gui.sh into the new user's home directory
    if [[ -e '/data/data/com.termux/files/home/senestro-ubuntu/distro/gui.sh' ]]; then
        cp /data/data/com.termux/files/home/senestro-ubuntu/distro/gui.sh /home/$user/gui.sh
        chmod +x /home/$user/gui.sh
    else
        wget -q --show-progress https://raw.githubusercontent.com/senestro-ubuntu/senestro-ubuntu/master/distro/gui.sh
        mv -vf gui.sh /home/$user/gui.sh
        chmod +x /home/$user/gui.sh
    fi

    clear
    echo
    echo -e "\n${R} [${W}-${R}]${G} Restart your Termux & Type ${C}ubuntu"${W}
    echo -e "\n${R} [${W}-${R}]${G} Then Type ${C}sudo bash gui.sh "${W}
    echo
}

# --- Main execution order ---
banner
sudo_setup
login
