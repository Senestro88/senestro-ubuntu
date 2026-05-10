#!/bin/bash
# =============================================================================
# senestro-ubuntu/remove.sh
# Removes the Ubuntu proot-distro installation and cleans up Termux state.
# Run from Termux (NOT inside Ubuntu).
# =============================================================================

# ANSI color codes
R="$(printf '\033[1;31m')"   # Red
G="$(printf '\033[1;32m')"   # Green
Y="$(printf '\033[1;33m')"   # Yellow
B="$(printf '\033[1;34m')"   # Blue
C="$(printf '\033[1;36m')"   # Cyan
W="$(printf '\033[1;37m')"   # White

# -----------------------------------------------------------------------------
# banner: Print the project header
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
# package: Remove the Ubuntu distro image, its cache, the `ubuntu` launcher,
# and clean up the PulseAudio sound lines written by setup.sh.
# -----------------------------------------------------------------------------
package() {
    echo -e "${R} [${W}-${R}]${C} Purging packages..."${W}

    # Remove Ubuntu proot image and its cached download
    proot-distro remove ubuntu && proot-distro clear-cache

    # Remove the `ubuntu` shortcut from Termux PATH
    rm -rf "$PREFIX/bin/ubuntu"

    # Remove PulseAudio daemon line from ~/.sound
    sed -i '/pulseaudio --start --exit-idle-time=-1/d' ~/.sound

    # Remove PulseAudio TCP module line from ~/.sound
    sed -i '/pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1/d' ~/.sound

    echo -e "${R} [${W}-${R}]${C} Purging Completed !"${W}
}

# --- Main execution order ---
banner
package
