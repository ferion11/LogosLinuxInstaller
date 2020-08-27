# LogosLinuxInstaller
> LogosLinuxInstaller is a bash script for installation of Logos Bible on Linux.

##### * NOTE The v2.0 break backward compatibility with previous 1.x versions. It will work like the portable version, with variations that may or may not use AppImage, depending on the user's choice, but all installation alternatives will maintain some isolation from the rest of the system and other installations (the independent directory can be moved/renamed without losing functionality).

### v2.0 or higher  instructions:
#### 00-  Download and execute:
You can download the last release [[HERE]](https://github.com/ferion11/LogosLinuxInstaller/releases "[HERE]").
- If you have the file `Logos-x86.msi` or `Logos-x64.msi`, you can let one copy of it in `/tmp` (or set the variable DOWNLOADED_RESOURCES to the directory that have it) that the installer will use it. It can be useful to install others version without change the script (the same for the others `winetricks` or `wine-i386_x86_64-archlinux.AppImage` versions).
- If you want to use some other option for `winetricks`, then just set the variable `WINETRICKS_EXTRA_OPTION` (the default is just `-q`), like:
`$ export WINETRICKS_EXTRA_OPTION="-q --force"` to force the installation on unsupported versions of Wine.

1.1- After that you need to give permission to execute (You can use some graphical method too, but it will depend on your linux distribution):

`$ chmod +x install_AppImageWine_and_Logos.sh`

1.2- Then execute (you don't need sudo or root acess):

`$ ./install_AppImageWine_and_Logos.sh`

- You can get the skel with the options `skel32` and `skel64`. It can be useful if you want just the scripts to update one of your local installations. And you can reuse the WineBottle from others installation too.

#### 01- The installation start here:

![Step01](/img/step_01.png)

* The default is using the 32bit AppImage, that provide better isolation. But you can choose do it using your native wine 32bits (that I recommend do using the 32bits, but you will need multilib wine installed in your 64bits system) or 64bit (is very unstable, work only on few cases, and need one wine 64bits made with WoW64 compatibility layer with 32bits, because dotnet need the 32bits wine working to install it on the 64bit profile). Option 4 is for better compatibility installation using AppImage (if you don't want AppImage, but like the installation option 4, then just remove the AppImage file from the `data` dir, and it will use your native wine). Regardless of your choice, the installation will be done in isolation from the others.

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

* The `data` directory contains the Wine Bottle and possibly the AppImage, for this installation.
