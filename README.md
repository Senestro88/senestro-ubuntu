<p align="center">
<img src="./distro/image.jpg">
</p>
<p align="center">
<img src="https://img.shields.io/badge/MADE%20IN-BANGLADESH-green?colorA=%23ff0000&colorB=%23017e40&style=for-the-badge">
<img src="https://img.shields.io/badge/Version-2.0-blue?style=for-the-badge">
</p>
<p align="center">
<img src="https://img.shields.io/badge/Written%20In-Bash-darkgreen?style=flat-square">
<img src="https://img.shields.io/badge/Open%20Source-Yes-darkviolet?style=flat-square">
<img src="https://img.shields.io/github/stars/modded-ubuntu/modded-ubuntu?style=flat-square">
<img src="https://img.shields.io/github/issues/modded-ubuntu/modded-ubuntu?color=red&style=flat-square">
<img src="https://img.shields.io/github/forks/modded-ubuntu/modded-ubuntu?color=teal&style=flat-square">
</p>
<p align="center"><b>Run Ubuntu GUI on your termux with much features.</b></p>

> **⚠️ Modded Version Notice**
> This is a modded version of [modded-ubuntu](https://github.com/modded-ubuntu/modded-ubuntu/tree/master).
> All credits and thanks go to the original **modded-ubuntu** project and its contributors.

### Features

- Audio output support (fixed for Termux/proot environments)
- Lightweight installation (requires at least 4 GB of available storage)
- Choice of two browsers: Chromium and Mozilla Firefox
- Bengali font support (fonts-beng / fonts-beng-extra)
- Media players: VLC and MPV
- Visual Studio Code (note: may exhibit instability on ARM devices)
- Sublime Text Editor (supported on arm64/aarch64 only)
- Beginner-friendly installation process
- Pre-configured desktop themes and wallpapers

### Installation

**Step 1 — Install Termux**

Download and install the [Termux](https://termux.com) application from [F-Droid](https://f-droid.org/repo/com.termux_118.apk).

**Step 2 — Clone the repository and run the setup script**

  - `yes | pkg up`
  - `pkg install git wget -y`
  - `git clone --depth=1 https://github.com/Senestro88/senestro-ubuntu.git`
  - `cd senestro-ubuntu`
  - `bash setup.sh`

**Step 3 — Create your Ubuntu user**

Restart Termux, then run the following commands:

   - `ubuntu`
   - `bash user.sh`

Enter a username when prompted. It must be lowercase with no spaces.

**Step 4 — Install the GUI**

Restart Termux again, then run:

   - `ubuntu`
   - `sudo bash gui.sh`

> **Important:** Make note of the VNC password displayed during this step — it is required to connect later.

The Ubuntu image is now fully installed.

  - Run `vncstart` to start the VNC server.
  - Run `vncstop` to stop the VNC server.

**Step 5 — Connect via VNC Viewer**

Install [VNC Viewer](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android&hl=en) on your device.

- Open VNC Viewer and tap the **+** button.
- Enter the address `localhost:1` and assign any name to the connection.
- Set the picture quality to **High** for the best experience.
- Tap **Connect** and enter your VNC password when prompted.

### Quick Reference

| Command | Description |
|---|---|
| `ubuntu` | Launch the Ubuntu CLI environment |
| `vncstart` | Start the VNC server |
| `vncstop` | Stop the VNC server |
| `bash remove.sh` | Uninstall the Ubuntu environment |

#
### Click to see the [Changelog](./CHANGELOG.md)
Licensed under [Apache License](./LICENSE)
#

### Credits : 

```
This Tool Uses the ubuntu image provided by the termux package `proot-distro` 

Full Credit of the Ubuntu image goes to them .

Termux Proot Distro - https://github.com/termux/proot-distro
```

### Maintainers

- [**Mustakim Ahmed**](https://github.com/BDhackers009)
- [**Tahmid Rayat**](https://github.com/htr-tech)
- [**0xBaryonyx**](https://github.com/Mahfuz-THBD)


### If you like our work then dont forget to give a Star :)

