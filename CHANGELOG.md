# Changelog
* 3.7.2
  - Fix #178.
  - Make AppImage default install.
  - Add options to `-D|--debug`.
* 3.7.1
  - Add installer `-V|--verbose`. Fix #165. [T. H. Wright]
  - Add installer `-k|--make_skel` and `-b|--custom-binary-path`. Resolve TODOs. Fix #166. [T. H. Wright]
  - Disable wine 8.0 installs. Fix #148. [T. H. Wright]
* 3.7.0
  - Decoupled script from `zenity` and compatible with `dialog` and `whiptail`. Fix #104. [T. H. Wright]
  - Make bash path environment agnostic [Vskillet]
  - Add bash completion file [T. H. Wright]
  - Fix controlPanel's `--winetricks` function [T. H. Wright]
  - Fix installer's `-c|--config` function [T. H. Wright]
  - Fix launcher's `-s|--short` function [T. H. Wright]
* 3.6.3-1
  - Introduce logos_info() and logos_warn() to simplify script feedback. [T. H. Wright]
* 3.6.2
  - Retrieve Logos release version from XML feed [T. H. Wright]
  - Modify the script version, and update the CHANGELOG to reflect this change.
* 3.6.1
  - Introduce logos_error() to simplify error messages. [T. H. Wright]
* 3.6.0
  - [T. H. Wright]
    - Move generated scripts to separate files: `Launcher-Template.sh`, `controlPanel-Template.sh`.
    - Moved generated scripts case statements to optargs (e.g., `-i|--indexing`). Fix #108.
    - Added Logos.sh: `-b|--backup`. Fix #110.
    - Added Logos.sh: `-r|--restore`.
    - Added Logos.sh: `-e|--edit-config`.
    - Added `-r|--regenerate-scripts`.
    - Added LOGOS.sh: `-R|--check-resources`. Requires `sysstat` and `psrecord`.
    - Fix #129.
* 3.5.1
  - [T. H. Wright]
    - Fix #68.
* 3.5.0
  - [T. H. Wright]
    - Change in numbering scheme to note if Logos was updated or the script
    - Fix #116.
    - Added `-c|--config`.
    - Added `-F|--skip-fonts`.
* 3.4.0
  - [T. H. Wright]
    - Fix #36.
    - Fix #81.
    - Fix #97.
    - Fix #99.
    - Fix #102.
    - Fix #103.
    - Fix #107.
    - Fix #109.
    - Fix #112.
    - Added `-f|--force-root`.
    - Added `-D|--debug`.
* 3.3.0
  - [T. H. Wright]
    - Fix #93.
* 3.2.0
  - [T. H. Wright]
    - Fix #92.
* 3.1.0
  - Install DLL d3dcompiler_47 (jg00dman, thw26)
  - L10: Change winetricks URL
  - L10: allow using local winetricks (thw26)
  - L10: add winetricks_dll_install (thw26)
  - Add basic optargs: `-h|--help` and `-v|--version` (thw26)
* 3.0.0:
  - Refactoring and renaming of scripts, updates to README, by T. H. Wright (thw26)
  - Logos 10 and Verbum 10 install scripts by John Goodman (jg00dman)
    - NOTE: Scripts are now numbered by Logos version.
  - Removal of broken Logos 9 AppImage script by T. H. Wright (thw26)
* v2.41:
  - update to LogosBible 9.17.0.0010
* v2.40:
  - update to LogosBible 9.15.0.0005
* v2.39:
  - added `removeLibraryCatalog` option (thw26)
  - update to LogosBible 9.13.0.0018 (thw26)
* v2.38:
  - update to LogosBible 9.11.0.0022
* v2.37:
  - update to LogosBible 9.10.0.0017
* v2.36:
  - update to LogosBible 9.9.0.0011
* v2.35:
  - update to LogosBible 9.8.0.0004
* v2.34:
  - update to LogosBible 9.7.0.0025
* v2.33:
  - added Tahoma
  - update to LogosBible 9.7.0.0020
* v2.32:
  - update to LogosBible 9.6.0.0024
* v2.31:
  - update to LogosBible 9.6.0.0023
* v2.30:
  - update to LogosBible 9.6.0.0020
* v2.29:
  - update to LogosBible 9.5.0.0019
* v2.28:
  - default option to be the WINE native
  - removed nodeps AppImage option
  - update to LogosBible 9.5.0.0014
* v2.27:
  - update to WINE default AppImage
* v2.26:
  - update to WINE AppImage v6.5
  - added AppImage with deps and new default option
* v2.25:
  - update to LogosBible 9.4.0.0009
* v2.24:
  - update to LogosBible 9.3.0.0049 by John Goodman (jg00dman)
  - added change to vista on winebottle by John Goodman (jg00dman)
* v2.23:
  - Typos, spelling, grammar by T. H. Wright (thw26)
  - update to LogosBible 9.3.0.0040
* v2.22:
  - update to LogosBible 9.2.0.0014
* v2.21:
  - update to LogosBible 9.1.0.0018
* v2.20:
  - Added default message for some deps
  - Removed the unsupported 32bit version
  - Changed the AppImage to include one extra libjpeg8 (if you don't have on installed)
  - update to LogosBible 9.0.0.0168
* v2.19:
  - update to LogosBible 8.17.0.0011
* v2.18:
  - LogosBible logo update to optimized file size keeping the quality
  - added silent `wineboot` after `selectAppImage`
  - change default AppImage to `f11-build-v5.11` with `wineserver` bugfix patch.
* v2.17:
  - refactory to a more clean code, improving QA
  - added `dirlink` option to `Logos.sh` to create on link to the LogosBible folder inside the Bottle
  - added `removeAllIndex` option to `Logos.sh` to workaround some issues (by Frank Sauer)
* v2.16:
  - added patch command to dependencies list
  - many improves in code quality
  - removed `WINETRICKS_EXTRA_OPTION` and added `WINETRICKS_UNATTENDED`
  - `winetricks` (mod-updated) tee output and improvements on feedback logs
  - added `shortcut` option to `Logos.sh`
  - changed default value of `DOWNLOADED_RESOURCES` to `PWD`
  - avoiding option on `wineboot` using `DISPLAY=""`, added `WINEBOOT_GUI` to turn it on
* v2.15:
  - improved `wait_process_using_dir` function using `lsof` instead of `fuser`
  - close all wine process in the bottle if `winetricks` error
  - refactor of basic dependencies check.
  - added `FORCE_ROOT` variable to allow root installation (that is blocked by default now)
  - removed `wait_process_using_dir` for small operations
* v2.14:
  - Using one modded `winetricks` with wait function to bugfix installation.
* v2.13:
  - improved QA of the script code
  - bugfix `WINETRICKS_EXTRA_OPTION` use, now we can do `WINETRICKS_EXTRA_OPTION=""`
  - added `logsOn` and `logsOff` options on `Logos.sh` to LogosBible logs
  - removed zsync file from `data` directory, it's useful just to fast download.
  - removed old `option 4`, then the old `option 5` become new `option 4`
  - changed the old `option 5` to use the new AppImage of `wine64`, but without dependencies
  - now all AppImage installations use full named AppImage filename, no more generic one
* v2.12:
  - added one better wait system to be sure that the installation is ok
  - Working in progress of the new `Option 5` to install 64bits
  - update LogosBible to 8.16.0.0002
* v2.11:
  - scripts refactored to be more clean
  - the creation of the scripts are made in the beginning of the installation to make easy debug
  - Bugfix some bugs that make wine send exit code before ending (now we wait for any wine procedure in the wineBottle).
  - added `bin` directory and links for `wine64` installation and skel64
  - added `selectAppImage` option on `Logos.sh` and `controlPanel.sh`
* v2.10:
  - call `wineboot` before download and install LogosBible
  - improved version of gtk_download
  - improved Winetricks opetations
  - more optional variables (`LOGOS_URL, LOGOS64_URL, WINE_APPIMAGE_URL, WINE4_APPIMAGE_URL, WINE5_APPIMAGE_URL, WINETRICKS_URL`)
  - more space to the multiple option window
  - now we can use other `winetricks` after installation, instead of the git one (just put it to the same dir that the `Logos.sh` file)
* v2.9:
  - `winetricks` can be get from `DOWNLOADED_RESOURCES` now
  - `WINETRICKS_DOWNLOADER` default to `wget` but can be changed setting the variable
  - removed the clean question and just clean at the end
  - added option 4 that use AppImage wine-staging v4.21 up to dotnet48 then the v5.x to install and run LogosBible
* v2.8:
  - back to `Jul 23, 2020` `winetricks` because of automated test fail
  - workaround possible issue only setting `PATH` if there is one valid wine on the bin dir.
* v2.7:
  - Some workaround to solve pipe error on test servers
  - more QA code improvements
  - winetricks to `Aug 8, 2020` release
  - change wine AppImage url to one exclusive for logos
* v2.5:
  - using the `"2020 Jul 23"` `winetricks` now (because of some issues with the last git)
  - removed `WINETRICKS_EXTRA_OPTION` `--force` option
  - QA fix improve in the generated scripts.
* v2.4:
  - variable `WORKDIR` or random tmp.
  - more feedback to get download and install winetricks error, terminal feedback too, cancellation is working now, and others.
  - `WINETRICKS_EXTRA_OPTION` variable with default `--force` (to install dotnet with new Wine that have bug reports)
  - 2 options to make the skel: `skel32` and `skel64`.
  - default `DOWNLOADED_RESOURCES` is `/tmp` now.
  - many Quality Assurance (qa) fixes too.
* v2.3 there is:
  - bugfix links creation
  - added the option to index without open LogosBible
* v2.2 there is:
  - added `cabextract` and `ntlm_auth` dependency verification
  - added `wineserver` Run to the scripts
  - added one way to get only the scripts from the installer, so you can just replace the old ones inside your installation (if needed).
* v2.1 is just a bugfix for the unstable 64bits installation. # NOTE: the v2.0 break compatibility with previous versions
