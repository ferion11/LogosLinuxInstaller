[![Codacy Badge](https://api.codacy.com/project/badge/Grade/f730f74748c348cb9b3ff2fa1654c84b)](https://app.codacy.com/manual/ferion11/LogosLinuxInstaller?utm_source=github.com&utm_medium=referral&utm_content=ferion11/LogosLinuxInstaller&utm_campaign=Badge_Grade_Dashboard)
[![Automation testing](https://img.shields.io/badge/Automation-testing-sucess)](https://github.com/ferion11/LogosLinuxInstallTests) [![Installer LogosBible](https://img.shields.io/badge/Installer-LogosBible-blue)](https://www.logos.com)

# LogosLinuxInstaller
> LogosLinuxInstaller is a bash script for installation of Logos Bible on Linux.

##### * NOTE The v2.x break backward compatibility with previous 1.x versions. It will work like the portable version, with variations that may or may not use AppImage, depending on the user's choice, but all installation alternatives will maintain some isolation from the rest of the system and other installations (the independent directory can be moved/renamed without losing functionality).

### v2.x or higher  instructions:
#### 00-  Download and execute:
You can download the last release [[HERE]](https://github.com/ferion11/LogosLinuxInstaller/releases "[HERE]").
- If you have the file `Logos-x86.msi` or `Logos-x64.msi`, you can let one copy of it in `/tmp` (or set the variable DOWNLOADED_RESOURCES to the directory that have it) that the installer will use it. It can be useful to install others version without change the script (the same for the others `winetricks` or `wine-i386_x86_64-archlinux.AppImage` versions).
- If you want to use some other option for `winetricks`, then just set the variable `WINETRICKS_EXTRA_OPTION` (the default is just `-q`), like:
`$ export WINETRICKS_EXTRA_OPTION="-q --force"` to force the installation on unsupported versions of Wine, or `$ export WINETRICKS_EXTRA_OPTION=""` to remove the default `-q`.
- If you have the files downloaded then you can put all in your `/tmp` directory, or set the variable `DOWNLOADED_RESOURCES`, like `$ export DOWNLOADED_RESOURCES="${HOME}/Downloads"`.

0.1- After that you need to give permission to execute (You can use some graphical method too, but it will depend on your linux distribution):
```
$ chmod +x install_AppImageWine_and_Logos.sh
```

0.2- Then execute (you don't need sudo or root acess):
```
$ ./install_AppImageWine_and_Logos.sh
```

- You can get the skel with the options `skel32` and `skel64`. It can be useful if you want just the scripts to update one of your local installations. And you can reuse the WineBottle from others installation too.

#### 01- The installation start here:

![Step01](/img/step_01.png)

* The default is using the 32bit AppImage, that provide better isolation. But you can choose do it using your native wine 32bits (some versions of wine will not work, so use `v5.11`) or 64bit (is unstable, work only on few cases, and need one wine 64bits made with WoW64 compatibility layer with 32bits, because dotnet need the 32bits wine working to install it on the 64bit profile, and again use `v5.11`). Option 4 is for better compatibility 64bits installation using one AppImage, but without deps, so I recommend that you have one wine WoW64 installated anyway for the dependencies (if you don't want AppImage, but like the installation option 4, then just remove the AppImage file from the `data` dir, and it will use your native wine). Regardless of your choice, the installation will be done in isolation from the others.

* Who is travis? Travis-ci is the automated system that test and generates the images, [[HERE]](https://github.com/ferion11/LogosLinuxInstallTests "[HERE]")

#### 02- It will download the AppImage, if needed:

![Step02](/img/step_02.png)

#### 03- It will ask if you wanna continue the installation knowing that it will make one isolated directory installation at the path indicated:

![Step03](/img/step_03.png)

#### 04- The Wine will ask if you wanna install the .NET mono implementation, then I recommend you to Cancel, just to speed up a little the process, because it will be removed later anyway:

![Step04](/img/step_04.png)

#### 05- The Wine will ask if you wanna install the Gecko engine, that will work like one Internet Explorer, you can Cancel too, but if you use some LogosBible feature that show or load internet pages, then click to Install:

![Step05](/img/step_05.png)

#### 06- It will ask if you wanna continue the installation knowing that it will install the winetricks packages (it will take a while to finish):

![Step06](/img/step_06.png)

#### 07- The first winetricks package is the corefonts (just to make sure that you have the basic fonts installed):

![Step07](/img/step_07.png)

#### 08- The next winetricks package is the configuration fontsmooth (just to have better fonts visual):

![Step08](/img/step_08.png)

#### 09- The next winetricks package is the MS DotNet v4.8, that will install the v4.0 first and then the update v4.8 (this will use some time to finish):

![Step09](/img/step_09.png)

#### 10- It will ask if you wanna continue the installation knowing that it will download and install the LogosBible, so just click Yes:

![Step10](/img/step_10.png)

Why do I need to click Yes here? Because it's a good stopping point to find out what's going on, and these stopping points only happen close to other mandatory interaction stops too.

#### 11- It will download and execute the msi LogosBible installer file first:

![Step11](/img/step_11.png)

What is an msi? Microsoft Windows Installer.

#### 12- Then we see the first LogosBible installation screen, just click on Next:

![Step12](/img/step_12.png)

#### 13- Mark the checkbox to accept the EULA (End User License Agreement) then click Next:

![Step13](/img/step_13.png)

#### 14- Choose the type of installation, it can be Typical, or Custom if you prefer it:

![Step14](/img/step_14.png)

I like to choose Custom and change the path to `c:\Logos\` (because it's easy to find), but it's my preference, any path chosen inside the Wine Bottle will work normally. Choose Typical for the default.

#### 15- Then click Install to begin the installation:

![Step15](/img/step_15.png)

#### 16- At the end click on Finish:

![Step16](/img/step_16.png)

#### 17- Congratulations! Installation is complete. You can run it for the first time by clicking Yes:

![Step17](/img/step_17.png)

#### 18- Ok! If your window does not leave the screen, just login::

![Step18](/img/step_18.png)

If the windows does leave the screen then just holding the `Alt` key you can move it by clicking any part and drag it, so if something similar happens to you, it will be easy to move the window down just by holding `Alt` key on the keyboard while dragging the window using the mouse.

#### 19- You now have a `LogosBible_Linux_P` folder in your User Home:

* It can be renamed and moved which should maintain functionality (with only a few limitations like changing the name of the linux user).

* Inside it there are two scripts:
  - `Logos.sh` : used to run the LogosBible installed in this directory.
  - `controlPanel.sh` : used to call the Windows Control Panel of this installation, so that you can easily remove and install new versions manually without having to resort to complicated procedures.

* You can also use the `Logos.sh` or `controlPanel.sh` to execute Wine or winetricks commands on that installation, like:
  - `$ ./Logos.sh wine regedit.exe`
  - `$ ./Logos.sh winetricks calibri`
  - if there is another version of winetricks inside `LogosBible_Linux_P`, the `Logos.sh` or `controlPanel.sh` will use it.

* If, after the installation, you want to use a different version of winetricks, just copy it to the same directory that the `Logos.sh` and `controlPanel.sh`, then the 2 scripts will use it, instead of download the last git version.

* You can run the standalone Logos Bible indexing on the console with:
```
$ ./Logos.sh indexing
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

#### 20- To uninstall:

Just remove the installation directory, everything is contained in isolation from your system.

#### 21- To update:

You can use the skel option to easily update the script version:

21.1.1 - Rename/move the old installation to use like one backup:
```
$ mv LogosBible_Linux_P LogosBible_Linux_P_old
```

21.1.2 - Download the last script [[HERE]](https://github.com/ferion11/LogosLinuxInstaller/releases "[HERE]")

21.1.3 - Make it executable and execute with the option `skel32` or `skel64`, like:
```
$ chmod +x install_AppImageWine_and_Logos.sh
$ ./install_AppImageWine_and_Logos.sh skel32
```

21.1.4 - Copy the wineBottle and if you are using AppImage then copy it too:
```
$ rm -rf LogosBible_Linux_P/data/wine32_bottle
$ cp -r LogosBible_Linux_P_old/data/wine32_bottle LogosBible_Linux_P/data/
$ cp LogosBible_Linux_P_old/data/*.AppImage LogosBible_Linux_P/data/
```

21.1.5 - Test the new version, and if work then you can remove the old `LogosBible_Linux_P_old`

#### 22- Alternative Fast Installations:
In this repository there is a version with "Fast Installations" that part of the procedures are done on the test server, and only the installation of LogosBible is done on the user's equipment: [[HERE]](https://raw.githubusercontent.com/ferion11/LogosLinuxInstaller/fast/install_AppImageWine_and_Logos.sh "[HERE]")
This alternative can help anyone who is having issues with the first part of the installation.
