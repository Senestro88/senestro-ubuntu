#!/bin/bash
# =============================================================================
# senestro-ubuntu/uninstall.sh
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
    echo
    printf "\033[32m Ubuntu GUI environment for Termux\033[0m\n"
    printf "\033[0m\n"
}

# -----------------------------------------------------------------------------
# confirm: Ask the user to confirm before proceeding with removal
# -----------------------------------------------------------------------------
confirm() {
    printf "${Y} [${W}!${Y}]${W} This will remove the Ubuntu installation and clean up Termux state.\n"
    printf "${Y} [${W}?${Y}]${W} Are you sure you want to continue? [y/N] "
    read -r answer
    case "$answer" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) printf "${R} [${W}-${R}]${C} Aborted.\n"${W}; exit 0 ;;
    esac
}

# -----------------------------------------------------------------------------
# ask_clear_cache: After removing the Ubuntu rootfs, ask whether to also wipe
# the proot-distro download cache. Keeping it means a reinstall can skip the
# Ubuntu tarball download; clearing it frees the disk space.
# -----------------------------------------------------------------------------
ask_clear_cache() {
    echo
    printf "${Y} [${W}?${Y}]${W} Do you want to clear the proot-distro download cache?\n"
    printf "${C}    Keeping it allows a future reinstall to reuse the already-downloaded Ubuntu tarball.\n"
    printf "${C}    Clearing it frees the disk space but the tarball will be re-downloaded on next install.\n"
    printf "${Y} [${W}?${Y}]${W} Clear cache? [y/N] "
    read -r cache_answer
    case "$cache_answer" in
        [yY][eE][sS]|[yY])
            echo -e "${R} [${W}-${R}]${C} Clearing proot-distro cache..."${W}
            proot-distro clear-cache
            echo -e "${G} [${W}-${G}]${C} Cache cleared."${W}
            ;;
        *)
            echo -e "${Y} [!] Keeping proot-distro cache. A future reinstall will reuse it."${W}
            ;;
    esac
}

# -----------------------------------------------------------------------------
# package: Remove the Ubuntu distro image, the `senestro-ubuntu` launcher,
# the x11 scripts, and clean up the PulseAudio sound lines written by install.sh.
# -----------------------------------------------------------------------------
package() {
    echo -e "${R} [${W}-${R}]${C} Removing Ubuntu installation and cleaning up..."${W}

    # Remove the Ubuntu proot rootfs (does NOT clear the download cache)
    proot-distro remove ubuntu

    # Ask separately whether to wipe the cached Ubuntu tarball
    ask_clear_cache

    # Remove Termux launcher and x11 scripts from Termux PATH
    rm -f "$PREFIX/bin/senestro-ubuntu"
    rm -f "$PREFIX/bin/x11start-senestro-ubuntu"
    rm -f "$PREFIX/bin/x11stop-senestro-ubuntu"

    # Remove PulseAudio daemon line from ~/.sound
    sed -i '/pulseaudio --start --exit-idle-time=-1/d' ~/.sound

    # Remove PulseAudio TCP module line from ~/.sound
    sed -i '/pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1/d' ~/.sound

    echo -e "${R} [${W}-${R}]${C} Uninstallation completed successfully."${W}
}

# --- Main execution order ---
banner
confirm
package
