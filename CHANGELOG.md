## Changelog

## [2.1.1] - 11-MAY-2026

### Added
- `x11-repo` Termux repository now enabled in `install.sh` before package installs (required for `termux-x11-nightly` to be available)
- `qt5-qttools` added to Termux package installs (required by Termux-X11)
- D-Bus machine-id validation and auto-generation in `x11start-senestro-ubuntu` — prevents dbus startup failures inside the proot container
- Stale session cleanup at startup in `x11start-senestro-ubuntu`: kills old xfce4-session, xfwm4, xfce4-panel, qdbus, pulseaudio, and termux-x11 processes before launching fresh
- Status banner in `x11start-senestro-ubuntu` showing display number and audio server address

### Changed
- `x11start-senestro-ubuntu` shebang changed to `/data/data/com.termux/files/usr/bin/bash` (explicit Termux bash path)
- XFCE4 now launched via `startxfce4` instead of bare `xfce4-session` for a more complete session startup
- `XDG_RUNTIME_DIR` set to `/tmp/runtime-root` with `chmod 700` inside proot, preventing runtime dir permission warnings
- PulseAudio TCP module now loaded via `pactl load-module` instead of `pacmd` (more reliable in newer PulseAudio versions)
- `x11stop-senestro-ubuntu` simplified to direct `pkill` calls — removed fragile `proot-distro login` approach for stopping processes
- Stale X lock files now cleaned using a `DISPLAY_NUM` variable in `x11start-senestro-ubuntu` for easier display number management

### Fixed
- `proot-distro login senestro-ubuntu` error — corrected to `proot-distro login ubuntu` in both x11 scripts (`senestro-ubuntu` is the Termux bin launcher name, not the proot-distro registered distro name)
- `termux-x11: command not found` — fixed invocation and added `-ac` flag
- PulseAudio "user-configured server, refusing to autospawn" noise — startup now checks if already running and skips gracefully

---

## [2.1.0] - 11-MAY-2026

### Added
- Termux-X11 support: `x11start-senestro-ubuntu` and `x11stop-senestro-ubuntu` scripts for low-latency native display without VNC
- `termux-x11-nightly` added to Termux package installs in `install.sh`
- `xorg-xserver-xephyr` added to Ubuntu package installs in `gui.sh` (required by Termux-X11)
- Skip option for browser selection in `install_softwares` (previously only IDE and media player had skip)

### Changed
- Main Termux launcher renamed from `ubuntu` to `senestro-ubuntu` for clarity and to avoid conflicts
- `x11start` and `x11stop` renamed to `x11start-senestro-ubuntu` and `x11stop-senestro-ubuntu`
- `DISPLAY` and `PULSE_SERVER` env vars moved out of `/etc/profile` — now set only in `vncstart` and `x11start-senestro-ubuntu` to prevent PulseAudio warnings on every plain login
- `package()` in `gui.sh` now installs all core packages in a single `apt-get install` call instead of a per-package loop, with a full package list printed before install
- README updated: all commands reflect new names, Quick Reference table now includes a `Where` column distinguishing Termux vs. inside Ubuntu commands

### Fixed
- PulseAudio "No daemon running" warnings appearing on every `senestro-ubuntu` login (caused by `PULSE_SERVER` being exported globally in `/etc/profile`)

---

## [2.0.0] - 2023-01-20

### Added
- Optional selection of browser, IDE, and media player during setup (reduces storage consumption)
- Code optimization and improved overall stability
- Breeze Hacked cursor theme
- Kora icon theme
- Custom default configuration for an enhanced out-of-the-box desktop experience
- Additional wallpapers
- Nerd Fonts support
- Various other improvements

### Changed
- Revised installer interface
- Updated default wallpaper
- Updated default font
- Updated default desktop theme

### Fixed
- Firefox installation (migrated to a new, reliable installer)
- Package repository errors
- Numerous additional bug fixes

<!-- END -->
