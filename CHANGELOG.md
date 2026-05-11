## Changelog

## [2.1.2] - 11-MAY-2026

### Changed
- `uninstall.sh` now removes `senestro-ubuntu`, `x11start-senestro-ubuntu`, and `x11stop-senestro-ubuntu` from `$PREFIX/bin` instead of the old `ubuntu` launcher
- Switched from `rm -rf` to `rm -f` for individual bin file removal in `uninstall.sh` (safer for single-file deletion)

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
