# Changelog

#### NOTE: the v2.0 break compatibility with previous versions

* from v2.0 to v2.1 is just a bugfix for the unstable 64bits installation.
* from v2.1 to v2.2 there is:
  - added `cabextract` and `ntlm_auth` dependency verification
  - added `wineserver` Run to the scripts
  - added one way to get only the scripts from the installer, so you can just replace the old ones inside your installation (if needed).
* from v2.2 to v2.3 there is:
  - bugfix links creation
  - added the option to index without open LogosBible
* from v2.3 to v2.4:
  - variable `WORKDIR` or random tmp.
  - more feedback to get download and install winetricks error, terminal feedback too, cancellation is working now, and others.
  - `WINETRICKS_EXTRA_OPTION` variable with default `--force` (to install dotnet with new Wine that have bug reports)
  - 2 options to make the skel: `skel32` and `skel64`.
  - default `DOWNLOADED_RESOURCES` is `/tmp` now.
  - many Quality Assurance (qa) fixes too.
* from v2.4 to v2.5:
  - using the `"2020 Jul 23"` `winetricks` now (because of some issues with the last git)
  - removed `WINETRICKS_EXTRA_OPTION` `--force` option
  - QA fix improve in the generated scripts.
* from v2.5 to v2.7:
  - Some workaround to solve pipe error on test servers
  - more QA code improvements
  - winetricks to `Aug 8, 2020` release
  - change wine AppImage url to one exclusive for logos
* from v2.7 to v2.8:
  - back to `Jul 23, 2020` `winetricks` because of automated test fail
  - workaround possible issue only setting `PATH` if there is one valid wine on the bin dir.
* from v2.8 to v2.9:
  - `winetricks` can be get from `DOWNLOADED_RESOURCES` now
  - `WINETRICKS_DOWNLOADER` default to `wget` but can be changed setting the variable
  - removed the clean question and just clean at the end
  - added option 4 that use AppImage wine-staging v4.21 up to dotnet48 then the v5.x to install and run LogosBible
* from v2.9 to v2.10:
  - call `wineboot` before download and install LogosBible
  - improved version of gtk_download
  - improved Winetricks opetations
  - more optional variables (`LOGOS_URL, LOGOS64_URL, WINE_APPIMAGE_URL, WINE4_APPIMAGE_URL, WINE5_APPIMAGE_URL, WINETRICKS_URL`)
  - more space to the multiple option window
  - now we can use other `winetricks` after installation, instead of the git one (just put it to the same dir that the `Logos.sh` file)
* from v2.10 to v2.11:
  - scripts refactored to be more clean
  - the creation of the scripts are made in the beginning of the installation to make easy debug
  - Bugfix some bugs that make wine send exit code before ending (now we wait for any wine procedure in the wineBottle).
  - added `bin` directory and links for `wine64` installation and skel64
  - added `selectAppImage` option on `Logos.sh` and `controlPanel.sh`
* from v2.11 to v2.12:
  - added one better wait system to be sure that the installation is ok
  - Working in progress of the new `Option 5` to install 64bits
  - update LogosBible to 8.16.0.0002
* from v2.12 to v2.13:
  - improved QA of the script code
  - bugfix `WINETRICKS_EXTRA_OPTION` use, now we can do `WINETRICKS_EXTRA_OPTION=""`
  - added `logsOn` and `logsOff` options on `Logos.sh` to LogosBible logs
  - removed zsync file from `data` directory, it's useful just to fast download.
  - removed old `option 4`, then the old `option 5` become new `option 4`
  - changed the old `option 5` to use the new AppImage of `wine64`, but without dependencies
  - now all AppImage installations use full named AppImage filename, no more generic one
* from v2.13 to v2.14:
  - Using one modded `winetricks` with wait function to bugfix installation.
* from v2.14 to v2.15:
  - improved `wait_process_using_dir` function using `lsof` instead of `fuser`
  - close all wine process in the bottle if `winetricks` error
  - refactor of basic dependencies check.
  - added `FORCE_ROOT` variable to allow root installation (that is blocked by default now)
  - removed `wait_process_using_dir` for small operations
* from v2.15 to v2.16:
  - added patch command to dependencies list
  - many improves in code quality
  - removed `WINETRICKS_EXTRA_OPTION` and added `WINETRICKS_UNATTENDED`
  - `winetricks` (mod-updated) tee output and improvements on feedback logs
  - added `shortcut` option to `Logos.sh`
  - changed default value of `DOWNLOADED_RESOURCES` to `PWD`
  - avoiding option on `wineboot` using `DISPLAY=""`, added `WINEBOOT_GUI` to turn it on
* from v2.16 to v2.17:
  - refactory to a more clean code, improving QA
  - added `dirlink` option to `Logos.sh` to create on link to the LogosBible folder inside the Bottle
  - added `removeAllIndex` option to `Logos.sh` to workaround some issues (by Frank Sauer)
* from v2.17 to v2.18:
  - LogosBible logo update to optimized file size keeping the quality
  - added silent `wineboot` after `selectAppImage`
  - change default AppImage to `f11-build-v5.11` with `wineserver` bugfix patch.
* from v2.18 to v2.19:
  - update to LogosBible 8.17.0.0011
* from v2.19 to v2.20:
  - Added default message for some deps
  - Removed the unsupported 32bit version
  - Changed the AppImage to include one extra libjpeg8 (if you don't have on installed)
  - update to LogosBible 9.0.0.0168
* from v2.20 to v2.21:
  - update to LogosBible 9.1.0.0018
* from v2.21 to v2.22:
  - update to LogosBible 9.2.0.0014
* from v2.22 to v2.23:
  - Typos, spelling, grammar by T. H. Wright (thw26)
  - update to LogosBible 9.3.0.0040
* from v2.23 to v2.24:
  - update to LogosBible 9.3.0.0049 by John Goodman (jg00dman)
  - added change to vista on winebottle by John Goodman (jg00dman)
* from v2.24 to v2.25:
  - update to LogosBible 9.4.0.0009
* from v2.25 to v2.26:
  - update to WINE AppImage v6.5
  - added AppImage with deps and new default option
* from v2.26 to v2.27:
  - update to WINE default AppImage
* from v2.27 to v2.28:
  - default option to be the WINE native
  - removed nodeps AppImage option
  - update to LogosBible 9.5.0.0014
* from v2.28 to v2.29:
  - update to LogosBible 9.5.0.0019
* from v2.29 to v2.30:
  - update to LogosBible 9.6.0.0020
* from v2.30 to v2.31:
  - update to LogosBible 9.6.0.0023
* from v2.31 to v2.32:
  - update to LogosBible 9.6.0.0024
* from v2.32 to v2.33:
  - added Tahoma
  - update to LogosBible 9.7.0.0020
* from v2.33 to v2.34:
  - update to LogosBible 9.7.0.0025
* from v2.34 to v2.35:
  - update to LogosBible 9.8.0.0004
