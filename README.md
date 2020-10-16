[![Codacy Badge](https://api.codacy.com/project/badge/Grade/f730f74748c348cb9b3ff2fa1654c84b)](https://app.codacy.com/manual/ferion11/LogosLinuxInstaller?utm_source=github.com&utm_medium=referral&utm_content=ferion11/LogosLinuxInstaller&utm_campaign=Badge_Grade_Dashboard)
[![Automation testing](https://img.shields.io/badge/Automation-testing-sucess)](https://github.com/ferion11/LogosLinuxInstallTests) [![Installer LogosBible](https://img.shields.io/badge/Installer-LogosBible-blue)](https://www.logos.com) [![LastRelease](https://img.shields.io/github/v/release/ferion11/LogosLinuxInstaller)](https://github.com/ferion11/LogosLinuxInstaller/releases)

# LogosLinuxInstaller
> LogosLinuxInstaller is a bash script for installation of Logos Bible on Linux.

##### * NOTE The v2.x break backward compatibility with previous 1.x versions. It will work like the portable version, with variations that may or may not use AppImage, depending on the user's choice, but all installation alternatives will maintain some isolation from the rest of the system and other installations (the independent directory can be moved/renamed without losing the basic functionality).

### v2.x or higher  instructions:
#### 00-  Download and execute:
There is one small video of the installation using the `fast_install_AppImageWine_and_Logos.sh` [[by clicking here]](https://github.com/ferion11/LogosLinuxInstallTests/releases/download/release-0a/LogosBible_Install.mp4 "[by clicking here]").
You can download the last release [[CLICK HERE]](https://github.com/ferion11/LogosLinuxInstaller/releases "[CLICK HERE]"). Highlighting the main environment variables:
- `DOWNLOADED_RESOURCES`: used to use a directory where the script will search for files by name before attempting to download from the internet (default is `${PWD}`).
- `INSTALLDIR`: used to change the installation directory (default is `${HOME}/LogosBible_Linux_P`)
- `WINETRICKS_URL`: to be able to change the source of winetricks.
- `LOGOS_URL` and `LOGOS64_URL`: to be able to change the source of the LogosBible installer.

0.1- After that you need to give permission to execute (You can use some graphical method too, but it will depend on your linux distribution):
```
$ chmod +x install_AppImageWine_and_Logos.sh
```

0.2- Then execute (you don't need sudo or root acess):
```
$ ./install_AppImageWine_and_Logos.sh
or with one or more environment variables like:
$ DOWNLOADED_RESOURCES=${HOME}/Downloads INSTALLDIR=/tmp/logosBibleTemp ./install_AppImageWine_and_Logos.sh
```

- You can get the skel with the options `skel32` and `skel64`. It can be useful if you want just the scripts to update one of your local installations. And you can reuse the WineBottle from others installation too.

#### 01- The installation start here:

![Step01](/img/step_01.png)

* The default is using the 32bit AppImage, that provide better isolation. But you can choose do it using your native wine 32bits (some versions of wine will not work, so use `v5.11`, or the `fast version`) or 64bit (is unstable, work only on few cases, and need one wine 64bits made with WoW64 compatibility layer with 32bits, because dotnet need the 32bits wine working to install it on the 64bit profile, and again use `v5.11` or the `fast version`). Option 4 is for better compatibility 64bits installation using one AppImage, but without deps, so I recommend that you have one wine WoW64 installated anyway for the dependencies (if you don't want AppImage, but like the installation option 4, then just remove the AppImage file from the `data` dir, and it will use your native wine). Regardless of your choice, the installation will be done in isolation from the others.

* Who is travis? Travis-ci is the automated system that test and generates the images, [[HERE]](https://github.com/ferion11/LogosLinuxInstallTests "[HERE]")

#### 02- It will download the AppImage, if needed:

![Step02](/img/step_02.png)

#### 03- It will ask if you wanna continue the installation knowing that it will make one isolated directory installation at the path indicated:

![Step03](/img/step_03.png)

#### 04- The Wine will update the Bottle:

![Step04](/img/step_04.png)

#### 05- It will ask if you wanna continue the installation knowing that it will install the winetricks packages (it will take a while to finish):

![Step05](/img/step_05.png)

#### 06- The first winetricks package is the corefonts (just to make sure that you have the basic fonts installed):

![Step06](/img/step_06.png)

#### 07- The next winetricks package is the configuration fontsmooth (just to have better fonts visual):

![Step07](/img/step_07.png)

#### 08- The next winetricks package is the MS DotNet v4.8, that will install the v4.0 first and then the update v4.8 (this will need some interaction now). Then to install MS DotNet 4.0, mark the license checkbox, then click on `Install`:

![Step08](/img/step_08.png)

#### 09- After the installation of MS DotNet 4.0, just click on `Finish`:

![Step09](/img/step_09.png)

#### 10- For the  MS DotNet 4.8 update, there is one warning but we aren't using `Windows Installer Service`, so just click on `Continue`:

![Step10](/img/step_10.png)

#### 11- Then to install MS DotNet 4.8 update, mark the license checkbox, and click on `Install`:

![Step11](/img/step_11.png)

#### 12- After the installation of the update MS DotNet 4.8, just click on `Finish`:

![Step12](/img/step_12.png)

#### 13- Then click on `Restart Later` (to avoid deadlock on wine process):

![Step13](/img/step_13.png)

#### 14- It will ask if you wanna continue the installation knowing that it will download and install the LogosBible, so just click `Yes`:

![Step14](/img/step_14.png)

Why do I need to click `Yes` here? Because it's a good stopping point to find out what's going on, and these stopping points only happen close to other mandatory interaction stops too.

#### 15- It will download and execute the `msi` LogosBible installer file first:

![Step15](/img/step_15.png)

What is an `msi`? Microsoft Windows Installer.

#### 16- Then we see the first LogosBible installation screen, just click on `Next`:

![Step16](/img/step_16.png)

#### 17- Mark the checkbox to accept the EULA (End User License Agreement) then click `Next`:

![Step17](/img/step_17.png)

#### 18- Choose the type of installation, it can be `Typical`, or `Custom` if you prefer it:

![Step18](/img/step_18.png)

I like to choose `Custom` and change the path to `c:\Logos\` (because it's easy to find), but it's my preference, any path chosen inside the Wine Bottle will work normally. Choose `Typical` for the default.

#### 19- Then click `Install` to begin the installation:

![Step19](/img/step_19.png)

#### 20- At the end click on `Finish`:

![Step20](/img/step_20.png)

#### 21- Congratulations! Installation is complete. You can run it for the first time by clicking `Yes`:

![Step21](/img/step_21.png)

#### 22- Ok! If your window does not leave the screen, just login::

![Step22](/img/step_22.png)

If the windows does leave the screen then just holding the `Alt` key you can move it by clicking any part and drag it, so if something similar happens to you, it will be easy to move the window down just by holding `Alt` key on the keyboard while dragging the window using the mouse.

#### 23- You now have a `LogosBible_Linux_P` folder in your User Home:

* It can be renamed and moved which should maintain functionality (with only a few limitations like changing the name of the linux user).

* Inside it there are two scripts:
  - `Logos.sh` : used to run the LogosBible installed in this directory.
  - `controlPanel.sh` : used to call the Windows Control Panel of this installation, so that you can easily remove and install new versions manually without having to resort to complicated procedures.

* You can also use the `Logos.sh` or `controlPanel.sh` to execute Wine or winetricks commands on that installation, like:
  - `$ ./Logos.sh wine regedit.exe`
  - `$ ./Logos.sh wineserver -w`
  - `$ ./Logos.sh winetricks calibri`
  - if there is another version of winetricks inside `LogosBible_Linux_P`, the `Logos.sh` or `controlPanel.sh` will use it.

* If, after the installation, you want to use a different version of winetricks, just copy it to the same directory that the `Logos.sh` and `controlPanel.sh`, then the 2 scripts will use it, instead of download the last git version.

* You can run the standalone Logos Bible indexing on the console with:
```
$ ./Logos.sh indexing
```

* You can remove all index files and catalog to workaround some indexing bug:
```
$ ./Logos.sh removeAllIndex
```

* You can create one symbolic link to the installation of LogosBible inside the Bottle, on the same dir that `Logos.sh`:
```
$ ./Logos.sh dirlink
```

* You can create/update one `LogosBible.desktop` (in `${HOME}/.local/share/applications`) that will point to the current location of `Logos.sh`:
```
$ ./Logos.sh shortcut
```

* You can enable/disable the Logos Bible logs with:
```
$ ./Logos.sh logsOn
or
$ ./Logos.sh logsOff
```

* You can have multiples AppImages on `data` directory, then change it with:
```
$ ./Logos.sh selectAppImage
or
$ ./controlPanel.sh selectAppImage
```

* The `data` directory contains the Wine Bottle and possibly the AppImage, for this installation.

#### 24- To uninstall:

Just remove the installation directory, everything is contained in isolation from your system.

#### 25- To update:

You can use the skel option to easily update the script version:

25.1.1 - Rename/move the old installation to use like one backup:
```
$ mv LogosBible_Linux_P LogosBible_Linux_P_old
```

25.1.2 - Download the last script [[HERE]](https://github.com/ferion11/LogosLinuxInstaller/releases "[HERE]")

25.1.3 - Make it executable and execute with the option `skel32` or `skel64`, like:
```
$ chmod +x install_AppImageWine_and_Logos.sh
$ ./install_AppImageWine_and_Logos.sh skel32
```

25.1.4 - Copy the wineBottle and if you are using AppImage then copy it too:
```
$ rm -rf LogosBible_Linux_P/data/wine32_bottle
$ cp -r LogosBible_Linux_P_old/data/wine32_bottle LogosBible_Linux_P/data/
$ cp LogosBible_Linux_P_old/data/*.AppImage LogosBible_Linux_P/data/
```

25.1.5 - Test the new version, and if work then you can remove the old `LogosBible_Linux_P_old`

#### 26- Alternative Fast Installations:
In this repository there is a version with "Fast Installations" that part of the procedures are done on the test server, and only the installation of LogosBible is done on the user's equipment: [[HERE]](https://github.com/ferion11/LogosLinuxInstaller/releases "[HERE]")
This alternative can help anyone who is having issues with the first part of the installation.
