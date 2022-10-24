[![Codacy Badge](https://api.codacy.com/project/badge/Grade/f730f74748c348cb9b3ff2fa1654c84b)](https://app.codacy.com/manual/ferion11/LogosLinuxInstaller?utm_source=github.com&utm_medium=referral&utm_content=ferion11/LogosLinuxInstaller&utm_campaign=Badge_Grade_Dashboard)
[![Automation testing](https://img.shields.io/badge/Automation-testing-sucess)](https://github.com/ferion11/LogosLinuxInstallTests) [![Installer LogosBible](https://img.shields.io/badge/Installer-LogosBible-blue)](https://www.logos.com) [![LastRelease](https://img.shields.io/github/v/release/ferion11/LogosLinuxInstaller)](https://github.com/ferion11/LogosLinuxInstaller/releases)

# Logos Bible Software on Linux Install Scripts
>This repository contains a set of bash scripts for installing Logos Bible (Verbum) Software on Linux.

### v2.x or higher  instructions:
#### 00-  Download and execute:
You can watch a small video on how to use the setup scripts [[by clicking here]](https://github.com/ferion11/LogosLinuxInstallTests/releases/download/release-0a/LogosBible_Install.mp4 "[by clicking here]").
You can download the latest release [[CLICK HERE]](https://github.com/ferion11/LogosLinuxInstaller/releases "[CLICK HERE]"). Highlighting the main environment variables:
- `DOWNLOADED_RESOURCES`: change the directory where the script will search for files by name before attempting to download from the internet (default is `${PWD}`).
- `INSTALLDIR`: change the installation directory (default is `${HOME}/LogosBible10`).
- `WINETRICKS_URL`: change the source of winetricks.
- `LOGOS64_URL`: change the source of the LogosBible installer.

0.1- After this you need to give permission to execute. (You can use some graphical method too, but it will depend on your Linux distribution.):
```
$ chmod +x Logos10_Setup.sh
```

0.2- Then execute the shell script. (You don't need sudo or root access.):
```
$ ./Logos10_Setup.sh
or with one or more environment variables like:
$ DOWNLOADED_RESOURCES=${HOME}/Downloads INSTALLDIR=/tmp/logosBibleTemp ./Logos10_Setup.sh
```

- You can get the skel with the options `skel64`. It can be useful if you want just the scripts to update one of your local installations. And you can reuse the WineBottle from others installation too.

#### 01- The installation starts here:

![Step01](/img/step_01.png)

* The default uses the AppImage nodeps, which provides some isolation. But you can choose do it using your native wine 64bits WoW64. (Some versions of wine will not work, so use `v5.11`, or the `fast version`. If you remove the AppImage file from the `data` dir, then it will use your native wine). Regardless of your choice, the installation will be done in isolation from others.

* Who is travis? Travis-ci is the automated system that tests and generates the images, [[HERE]](https://github.com/ferion11/LogosLinuxInstallTests "[HERE]")

#### 02- It will download the AppImage, if needed:

![Step02](/img/step_02.png)

#### 03- It will ask if you wanna continue the installation knowing that it will make an isolated directory installation at the path indicated:

![Step03](/img/step_03.png)

#### 04- Wine will update the Bottle:

![Step04](/img/step_04.png)

#### 05- It will ask if you want to continue the installation knowing that it will install the winetricks packages. (It will take a while to finish.):

![Step05](/img/step_05.png)

#### 06- The first winetricks package is corefonts (just to make sure that you have the basic fonts installed):

![Step06](/img/step_06.png)

#### 07- The next winetricks package is the configuration fontsmooth (just to have better fonts visual):

![Step07](/img/step_07.png)

#### 08- The next winetricks package is MS DotNet v4.8, which will install the v4.0 first and then the update to v4.8, which will need some interaction. To install MS DotNet 4.0, mark the license checkbox, then click on `Install`:

![Step08](/img/step_08.png)

#### 09- After the installation of MS DotNet 4.0, click on `Finish`:

![Step09](/img/step_09.png)

#### 10- For the  MS DotNet 4.8 update, there is a warning but we aren't using the `Windows Installer Service`, so click on `Continue`:

![Step10](/img/step_10.png)

#### 11- Then to install the MS DotNet 4.8 update, mark the license checkbox, and click on `Install`:

![Step11](/img/step_11.png)

#### 12- After the installation of the update to MS DotNet 4.8, click on `Finish`:

![Step12](/img/step_12.png)

#### 13- Then click on `Restart Later` to avoid deadlock on the wine process:

![Step13](/img/step_13.png)

#### 14- It will ask if you want to continue the installation knowing that it will download and install the LogosBible software. Click `Yes`:

![Step14](/img/step_14.png)

Why do I need to click `Yes` here? Because it's a good stopping point to find out what's going on, and these stopping points only happen close to other mandatory interaction stops, too.

#### 15- It will download and execute the `msi` LogosBible installer file first:

![Step15](/img/step_15.png)

What is an `msi`? Microsoft Windows Installer.

#### 16- Then we see the first LogosBible installation screen. Click on `Next`:

![Step16](/img/step_16.png)

#### 17- Mark the checkbox to accept the EULA (End User License Agreement), then click `Next`:

![Step17](/img/step_17.png)

#### 18- Choose the type of installation; it can be `Typical` or `Custom`:

![Step18](/img/step_18.png)

I like to choose `Custom` and change the path to `c:\Logos\` (because it's easy to find), but that's my preference. Any path chosen inside the Wine Bottle will work normally. Choose `Typical` for the default.

#### 19- Then click `Install` to begin the installation:

![Step19](/img/step_19.png)

#### 20- At the end click on `Finish`:

![Step20](/img/step_20.png)

#### 21- Congratulations! Installation is complete. You can run it for the first time by clicking `Yes`:

![Step21](/img/step_21.png)

#### 22- If your window does not leave the screen, login:

![Step22](/img/step_22.png)

If the LogosBible window vanishes from the screen or you accidentally move it to some place you cannot see it, hold the `Alt` key and click and drag any part of the window until you can see it again.

#### 23- You now have a `LogosBible10` folder in your User's Home Directory:

* It can be renamed and moved while maintaining functionality (with only a few limitations like changing the name of the Linux user).

* Inside the directory are two scripts:
  - `Logos.sh` : used to run the LogosBible installed in this directory.
  - `controlPanel.sh` : used to call the Windows Control Panel of this installation. This allows you to easily remove and install new versions manually without having to resort to complicated install procedures.

* You can also use the `Logos.sh` or `controlPanel.sh` to execute Wine or winetricks commands for that installation, like:
  - `$ ./Logos.sh wine regedit.exe`
  - `$ ./Logos.sh wineserver -w`
  - `$ ./Logos.sh winetricks calibri`
  - if there is another version of winetricks inside `LogosBible10`, the `Logos.sh` or `controlPanel.sh` will use it.

* If, after the installation, you want to use a different version of winetricks, just copy it to the same directory that the `Logos.sh` and `controlPanel.sh` scripts are, then the two scripts will use it instead of downloading the latest git version.

* You can run the standalone Logos Bible indexing on the console with:
```
$ ./Logos.sh indexing
```

* You can remove all index files and catalog to workaround some indexing bug:
```
$ ./Logos.sh removeAllIndex
```

* You can create a symbolic link to the installation of LogosBible inside the Bottle like so:
```
$ ./Logos.sh dirlink
```

* You can create/update the `LogosBible.desktop` (in `${HOME}/.local/share/applications`) to will point to the current location of `Logos.sh`:
```
$ ./Logos.sh shortcut
```

* You can enable/disable the Logos Bible logs with:
```
$ ./Logos.sh logsOn
or
$ ./Logos.sh logsOff
```

* You can have multiples AppImages on `data` directory and change it with:
```
$ ./Logos.sh selectAppImage
or
$ ./controlPanel.sh selectAppImage
```

* The `data` directory contains the Wine Bottle and possibly the AppImage for this installation.

#### 24- To uninstall:

Just remove the installation directory. Everything is contained in isolation from your system.

#### 25- To update:

You can use the skel option to easily update the script version:

25.1.1 - Rename/move the old installation to use as a backup:
```
$ mv LogosBible10 LogosBible10_old
```

25.1.2 - Download the last script [[HERE]](https://github.com/ferion11/LogosLinuxInstaller/releases "[HERE]")

25.1.3 - Make it executable and execute with the option `skel64`, like:
```
$ chmod +x Logos10_Setup.sh
$ ./Logos10_Setup.sh skel64
```

25.1.4 - Copy the wineBottle and if you are using AppImage then copy it, too:
```
$ rm -rf LogosBible10/data/wine64_bottle
$ cp -r LogosBible10_old/data/wine64_bottle LogosBible10/data/
$ cp LogosBible10_old/data/*.AppImage LogosBible10/data/
```

25.1.5 - Test the new version. If it works, you can remove the old `LogosBible10_old`

#### 26- Alternative Fast Installations:
In this repository there is also a "Fast Installation" version in which part of the install procedures are done on the test server and only the installation of LogosBible is done on the user's equipment: [[HERE]](https://github.com/ferion11/LogosLinuxInstaller/releases "[HERE]")
This alternative can help anyone who is having issues with the first part of the installation.

25.1.6 - Extra information:

1- For installing LogosBible using fast_install_AppImageWine_and_Logos.sh, you can keep in the same directory (${PWD}) the file https://github.com/ferion11/wine64_bottle_dotnet/releases/download/v5.11/wine64_bottle.tar.gz, as the script will use it, instead of download every time you install using a newer version of the script. With this you save some bandwidth in the installation.

2- After completing the installation you can use the files (books) from the old installation (so remember to backup) to save more bandwidth. The directories to be copied are (the default):

* remember that you can move and/or rename (or backup) the LogosBible64_Linux_P directory.
```
* LogosBible10/data/wine64_bottle/drive_c/users/$USER/Local\ Settings/Application\ Data/Logos/Data
* LogosBible10/data/wine64_bottle/drive_c/users/$USER/Local\ Settings/Application\ Data/Logos/Documents
* LogosBible10/data/wine64_bottle/drive_c/users/$USER/Local\ Settings/Application\ Data/Logos/Users
```
So, theoretically, if before the first run, you copy the files from these directories (from the old and functional to the new installation), LogosBible will not download them again, saving bandwidth. But again, remember to make sure the new version is working before deleting the old one (which will serve as a working backup too).
