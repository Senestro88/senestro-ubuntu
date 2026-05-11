## Changelog

## [2.1.9] - 11-MAY-2026

### Removed
- `gui.sh`: removed `install_softwares()`, `install_vscode()`, `install_sublime()`, `install_chromium()`, and `install_firefox()` functions entirely. Browser and IDE selection is no longer part of the GUI setup; users may install these manually as needed.
- `gui.sh`: the interactive software selection menu (browser + IDE choices) has been replaced by `install_media()` — a focused prompt offering only MPV, VLC, both, or skip.
- `gui.sh`: file header comment updated to reflect the narrower scope (no browsers or IDEs listed).

### Changed
- `uninstall.sh`: `proot-distro remove ubuntu` and `proot-distro clear-cache` are now two separate steps. After removing the Ubuntu rootfs, the user is prompted: **"Clear proot-distro cache?"** Saying no preserves the downloaded Ubuntu tarball so a future reinstall skips the download; saying yes frees the disk space. Previously the cache was always wiped unconditionally.
- `README.md`: removed feature bullets for Chromium, Firefox, Visual Studio Code, and Sublime Text. Updated the `gui.sh` step description to mention the media player prompt. Added a dedicated **Uninstallation** section describing the `uninstall.sh` steps including the new cache prompt. Version badge updated to 2.1.9.

---

## [2.1.8] - 11-MAY-2026

### Removed
- VNC support dropped entirely. `vncstart`, `vncstop`, and all TigerVNC packages (`tigervnc-standalone-server`, `tigervnc-common`, `tigervnc-tools`) are no longer installed, copied, or referenced. Termux-X11 is the sole desktop display method going forward.
  - `gui.sh`: removed `tigervnc-standalone-server`, `tigervnc-common`, `tigervnc-tools` from `packs[]` in `package()`; rewrote `note()` to show Termux-X11 instructions only; updated `sound_fix()` comment; updated file header comment.
  - `install.sh`: removed `setup_vnc()` function and its call in `permission()`; updated `sound()` comment ("VNC session" → "X11 session").
  - `README.md`: removed VNC feature bullet; removed VNC mode section; removed `vncstart` and `vncstop` rows from Quick Reference table; updated version badge to 2.1.8.

---

## [2.1.7] - 11-MAY-2026

### Added
- `/sdcard` (Android shared storage) is now bound into Ubuntu at `/sdcard` across all proot-distro login calls:
  - `install.sh` `permission()`: `mkdir -p "$UBUNTU_DIR/sdcard"` creates the mountpoint in the rootfs at install time so proot never errors on a missing target; the bootstrap `senestro-ubuntu` launcher now includes `--bind /sdcard:/sdcard`.
  - `user.sh` `login()`: the permanent `senestro-ubuntu` launcher written after user creation now includes `--bind /sdcard:/sdcard`.
  - `x11start-senestro-ubuntu`: all four `proot-distro login ubuntu` calls (machine-id read, machine-id write, XFCE4 preflight check, XFCE4 desktop launch) now include `--bind /sdcard:/sdcard`.

---

## [2.1.6] - 11-MAY-2026

### Added
- `user.sh`: new `install_desktop()` function — installs `xfce4`, `xfce4-goodies`, and `dbus-x11` as root before user creation. Required because `x11start-senestro-ubuntu` logs into Ubuntu as root (`proot-distro login ubuntu`, no `--user` flag), so XFCE4 must be present at root level independently of `gui.sh`.
- `user.sh`: new `set_root_password()` function — prompts for the root account password (with confirmation loop) and applies it via `chpasswd` before the sudo user is created. Ensures `su`/`sudo` work correctly inside the container from the first login.

### Changed
- `user.sh`: user password prompt in `login()` now uses `read -s` (hidden input) instead of plain `read`, consistent with the new root password prompt.
- `user.sh`: main execution order updated to `sudo_setup → install_desktop → set_root_password → login`.

---

## [2.1.5] - 11-MAY-2026

### Fixed
- `gui.sh`: replaced deprecated `apt-key adv --keyserver ... --recv-keys` in `config()` with the modern `gpg --no-default-keyring --keyring /etc/apt/trusted.gpg.d/ubuntu-archive-extra.gpg --keyserver ... --recv-keys` equivalent. `apt-key` was removed in Ubuntu 22.04+ and caused a `command not found` error during setup.

---

## [2.1.4] - 11-MAY-2026

### Fixed
- `install.sh`: `package()` previously skipped all installs if only `pulseaudio` and `proot-distro` were found, silently leaving `termux-x11-nightly` and `qt5-qttools` uninstalled on existing setups. The check now iterates all required packages (`pulseaudio`, `proot-distro`, `termux-x11-nightly`, `qt5-qttools`) and only skips if every one is present. `x11-repo` is also always enabled first so `termux-x11-nightly` is resolvable regardless.

---

## [2.1.3] - 11-MAY-2026

### Fixed
- `x11start-senestro-ubuntu`: added preflight check for `termux-x11` — exits early with clear install instructions (`pkg install x11-repo && pkg install termux-x11-nightly`) if the binary is missing instead of failing mid-launch with a cryptic error.
- `x11start-senestro-ubuntu`: added preflight check for `startxfce4` inside Ubuntu — exits early with instructions to run `sudo bash gui.sh` if XFCE4 is not installed yet.
- `user.sh`: `--fix-low-ports` flag in the generated `senestro-ubuntu` launcher is now applied conditionally — detected at runtime via `proot-distro login --help`; silently omitted on older proot-distro builds that do not support it, fixing the `fix-low-ports: inaccessible or not found` error on launch.

---

## [2.1.2] - 11-MAY-2026

### Changed
- `uninstall.sh` now removes `senestro-ubuntu`, `x11start-senestro-ubuntu`, and `x11stop-senestro-ubuntu` from `$PREFIX/bin` instead of the old `ubuntu` launcher.
- Switched from `rm -rf` to `rm -f` for individual bin file removal in `uninstall.sh` (safer for single-file deletion).

---

## [2.1.0] - 11-MAY-2026

### Added
- Termux-X11 support: `x11start-senestro-ubuntu` and `x11stop-senestro-ubuntu` scripts for low-latency native display.
- `termux-x11-nightly` added to Termux package installs in `install.sh`.
- `xorg-xserver-xephyr` added to Ubuntu package installs in `gui.sh` (required by Termux-X11).
- Skip option for browser selection in `install_softwares` (previously only IDE and media player had skip).

### Changed
- Main Termux launcher renamed from `ubuntu` to `senestro-ubuntu` for clarity and to avoid conflicts.
- `x11start` and `x11stop` renamed to `x11start-senestro-ubuntu` and `x11stop-senestro-ubuntu`.
- `DISPLAY` and `PULSE_SERVER` env vars moved out of `/etc/profile` — now set only in `x11start-senestro-ubuntu` to prevent PulseAudio warnings on every plain login.
- `package()` in `gui.sh` now installs all core packages in a single `apt-get install` call instead of a per-package loop, with a full package list printed before install.
- README updated: all commands reflect new names, Quick Reference table now includes a `Where` column distinguishing Termux vs. inside Ubuntu commands.

### Fixed
- PulseAudio "No daemon running" warnings appearing on every `senestro-ubuntu` login (caused by `PULSE_SERVER` being exported globally in `/etc/profile`).

---

## [2.0.0] - 2023-01-20

### Added
- Optional selection of browser, IDE, and media player during setup (reduces storage consumption).
- Code optimization and improved overall stability.
- Breeze Hacked cursor theme.
- Kora icon theme.
- Custom default configuration for an enhanced out-of-the-box desktop experience.
- Additional wallpapers.
- Nerd Fonts support.
- Various other improvements.

### Changed
- Revised installer interface.
- Updated default wallpaper.
- Updated default font.
- Updated default desktop theme.

### Fixed
- Firefox installation (migrated to a new, reliable installer).
- Package repository errors.
- Numerous additional bug fixes.

<!-- END -->
