[![Codacy Badge](https://api.codacy.com/project/badge/Grade/f730f74748c348cb9b3ff2fa1654c84b)](https://app.codacy.com/manual/ferion11/LogosLinuxInstaller?utm_source=github.com&utm_medium=referral&utm_content=ferion11/LogosLinuxInstaller&utm_campaign=Badge_Grade_Dashboard)
[![Automation testing](https://img.shields.io/badge/Automation-testing-sucess)](https://github.com/ferion11/LogosLinuxInstallTests) [![Installer LogosBible](https://img.shields.io/badge/Installer-LogosBible-blue)](https://www.logos.com) [![LastRelease](https://img.shields.io/github/v/release/ferion11/LogosLinuxInstaller)](https://github.com/ferion11/LogosLinuxInstaller/releases)

# Logos Bible Software on Linux Install Scripts

This repository contains a set of bash scripts for installing Logos Bible (Verbum) Software on Linux.

# Usage

## LogosLinuxInstaller.sh

```
Usage: ./LogosLinuxInstaller.sh
Installs ${FLPRODUCT} Bible Software with Wine on Linux.

Options:
    -h   --help                 Prints this help message and exit.
    -v   --version              Prints version information and exit.
    -V   --verbose              Enable extra CLI verbosity.
    -D   --debug                Makes Wine print out additional info.
    -c   --config               Use the Logos on Linux config file when
                                setting environment variables. Defaults to:
                                \$HOME/.config/Logos_on_Linux/Logos_on_Linux.conf
                                Optionally can accept a config file provided by
                                the user.
    -b   --custom-binary-path   Set a custom path to search for wine binaries
                                during the install.
    -r   --regenerate-scripts   Regenerates the Logos.sh and controlPanel.sh
                                scripts using the config file.
    -F   --skip-fonts           Skips installing corefonts and tahoma.
    -f   --force-root           Sets LOGOS_FORCE_ROOT to true, which permits
                                the root user to run the script.
    -k   --make-skel            Make a skeleton install only.
```

## Logos.sh

```
Usage: ./Logos.sh
Interact with Logos Bible Software in Wine on Linux.

Options:
    -h   --help                Prints this help message and exit.
    -v   --version             Prints version information and exit.
    -D   --debug               Makes Wine print out additional info.
    -f   --force-root          Sets LOGOS_FORCE_ROOT to true, which
                               permits the root user to run the script.
    -R   --check-resources     Check Logos's resource usage.
    -e   --edit-config         Edit the Logos on Linux config file.
    -i   --indexing            Run the Logos indexer in the
                               background.
    -b   --backup              Saves Logos data to the config's
                               backup location.
    -r   --restore             Restores Logos data from the config's
                               backup location.
    -l   --logs                Turn Logos logs on or off.
    -d   --dirlink             Create a symlink to the Windows Logos directory
                               in your Logos on Linux install dir.
                               The symlink's name will be 'installation_dir'.
    -s   --shortcut            Create or update the Logos shortcut, located in
                               HOME/.local/share/applications.
    --remove-all-index         Removes all index and library catalog files.
    --remove-library-catalog   Removes all library catalog files.
```

## controlPanel.sh

```
Usage: ./controlPanel.sh
Interact with Logos Bible Software in Wine on Linux.

Options:x
    -h   --help         Prints this help message and exit.
    -v   --version      Prints version information and exit.
    -D   --debug        Makes Wine print out additional info.
    -f   --force-root   Sets LOGOS_FORCE_ROOT to true, which permits
                        the root user to run the script.
    --wine64            Run the script's wine64 binary.
    --wineserver        Run the script's wineserver binary.
    --winetricks        Run winetricks.
    --setAppImage       Set the script's AppImage file. NOTE:
                        Currently broken. Disabled until fixed.
```

# Installation [WIP]

Once all dependencies are met, run `./LogosLinuxInstaller.sh` and follow the prompts.

NOTE: You can run Logos on Linux using the Steam Proton Experimental binary, which often has the latest and greatest updates to make Logos run even smoother. The script should be able to find the binary automatically, unless your Steam install is located outside of your HOME directory.

Your system must either have `dialog` or `whiptail` installed for a CLI install (launched from CLI), or you must have `zenity` installed for a GUI install (launched from double clicking).

## Install Guide

For an install guide with pictures and video, see the wiki's [Install Guide](https://github.com/ferion11/LogosLinuxInstaller/wiki/Install-Guide).

NOTE: This install guide is outdated. Please see [#114](https://github.com/ferion11/LogosLinuxInstaller/issues/114).

## Debian and Ubuntu

### Install dialog program, choose one of the following:

CLI:

```
sudo apt install dialog
```

or

```
sudo apt install whiptail
```

GUI:

```
sudo apt install zenity
```

### Install Dependencies

```
sudo apt install mktemp patch lsof wget find sed grep gawk tr winbind cabextract x11-apps bc libxml2-utils curl
```

If using wine from a repo, you must install wine staging. Run:

```
sudo apt install winehq-staging
```

See https://wiki.winehq.org/Ubuntu for help.

If using the AppImage, run:

```
sudo apt install fuse3
```

## Arch

### Install dialog program, choose one of the following:

CLI:

```
sudo pacman -S dialog
```

or

```
sudo pacman -S whiptail
```

GUI:

```
sudo pacman -S zenity
```

### Install Dependencies

```
sudo pacman -S patch lsof wget sed grep gawk cabextract samba bc libxml2 curl
```

If using wine from a repo, run:

```
sudo pacman -S wine
```

### Manjaro

#### Install dialog program, choose one of the following:

CLI:

```
sudo pamac install dialog
```

or

```
sudo pamac install whiptail
```

GUI:

```
sudo pamac install zenity
```

#### Install Dependencies

```
sudo pamac install patch lsof wget sed grep gawk cabextract samba bc libxml2 curl
```

If using wine from a repo, run:

```
sudo pamac install wine
```

You may need to install pamac if you are not using Manjaro GNOME:

```
sudo pacman -S pamac-cli
```

### Steamdeck

The steam deck has a locked down filesystem. There are some missing dependencies which cause irregular crashes in Logos. These can be installed following this sequence:

1. Enter Desktop Mode
2. Use `passwd` to create a password for the deck user, unless you already did this.
3. Disable read-only mode: `sudo steamos-readonly disable`
4. Initialize pacman keyring: `sudo pacman-key --init`
5. Populate pacman keyring with the default Arch Linux keys: `sudo pacman-key --populate archlinux`
6. Get package lists: `sudo pacman -Fy`
7. Fix locale issues `sudo pacman -Syu glibc`
8. then `sudo locale-gen` 
9. Install dependencies: `sudo pacman -S samba winbind cabextract appmenu-gtk-module patch bc lib32-libjpeg-turbo`

Packages you install may be overwritten by the next Steam OS update, but you can easily reinstall them if that happens.

After these steps you can go ahead and run the your install script.

## RPM

### Install dialog program, choose one of the following:

CLI:

```
sudo dnf install dialog
```

or

```
sudo dnf install whiptail
```

GUI:

```
sudo dnf install zenity
```

### Install Dependencies

```
sudo dnf install patch mod_auth_ntlm_winbind samba-winbind cabextract bc libxml2 curl
```

If using wine from a repo, run:

```
sudo dnf install winehq-staging
```

If using the AppImage, run:

```
sudo dnf install fuse3
```

### CentOS

#### Install dialog program, choose one of the following:

CLI:

```
sudo yum install dialog
```

or

```
sudo yum install whiptail
```

GUI:

```
sudo yum install zenity
```

### Install Dependencies

```
sudo yum install patch mod_auth_ntlm_winbind samba-winbind cabextract bc libxml2 curl
```

If using wine from a repo, run:

```
sudo yum install winehq-staging
```

If using the AppImage, run:

```
sudo yum install fuse3
```

## OpenSuse

TODO

```
sudo zypper install …
```

## Alpine

TODO

```
sudo apk add …
```

## BSD

TODO. The BSDs will require the script to be modified.

```
doas pkg install …
```

This would require rewriting major chunks of the script, which has assumed GNU/Linux and Bash.

