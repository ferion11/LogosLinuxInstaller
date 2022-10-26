#!/bin/bash
# From https://github.com/ferion11/LogosLinuxInstaller
# Modified to install Logoos 10 by Revd. John Goodman M0RVJ
# Script version to match Logos version.
LOGOS_SCRIPT_TITLE="Logos10_Setup"
LOGOS_SCRIPT_AUTHOR="Ferion11, John Goodman, T. H. Wright"
LOGOS_SCRIPT_VERSION="v10.0"

#=================================================
# version of Logos from: https://wiki.logos.com/The_Logos_9_Beta_Program
#if [ -z "${LOGOS64_URL}" ]; then export LOGOS64_URL="https://downloads.logoscdn.com/LBS9/Installer/9.15.0.0005/Logos-x64.msi" ; fi

#LOGOS_MVERSION=$(echo "${LOGOS64_URL}" | cut -d/ -f4); export LOGOS_MVERSION
#LOGOS_VERSION="$(echo "${LOGOS64_URL}" | cut -d/ -f6)"; export LOGOS_VERSION
#LOGOS64_MSI="$(basename "${LOGOS64_URL}")"; export LOGOS64_MSI
LOGOS64_MSI="LogosSetup.exe"
#=================================================
if [ -z "${LOGOS_ICON_URL}" ]; then export LOGOS_ICON_URL="https://raw.githubusercontent.com/ferion11/LogosLinuxInstaller/master/img/logos4-128-icon.png" ; fi
#=================================================
# Default AppImage FULL (with deps) to install 64bits version:
export WINE64_APPIMAGE_FULL_VERSION="v7.18-staging"
if [ -z "${WINE64_APPIMAGE_FULL_URL}" ]; then export WINE64_APPIMAGE_FULL_URL="https://github.com/mmtrt/WINE_AppImage/releases/download/continuous-staging/wine-staging_7.18-x86_64.AppImage" ; fi
WINE64_APPIMAGE_FULL_FILENAME="$(basename "${WINE64_APPIMAGE_FULL_URL}")"; export WINE64_APPIMAGE_FULL_FILENAME
#=================================================
# Default AppImage (without deps) to install 64bits version:
export WINE64_APPIMAGE_VERSION="v7.18-staging"
if [ -z "${WINE64_APPIMAGE_URL}" ]; then export WINE64_APPIMAGE_URL="https://github.com/mmtrt/WINE_AppImage/releases/download/continuous-staging/wine-staging_7.18-x86_64.AppImage" ; fi
WINE64_APPIMAGE_FILENAME="$(basename "${WINE64_APPIMAGE_URL}")"; export WINE64_APPIMAGE_FILENAME
#=================================================
# winetricks version in use (and downloader option set):
#if [ -z "${WINETRICKS_URL}" ]; then export WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" ; fi
# back to Jul 23, 2020 release of winetricks, not more of the last git random broken fun:
#if [ -z "${WINETRICKS_URL}" ]; then export WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/29d4edcfaec76128a68a0506605fd84473b6e38c/src/winetricks" ; fi
# trying one customized version of winetricks, of the link above:
if [ -z "${WINETRICKS_URL}" ]; then export WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/5904ee355e37dff4a3ab37e1573c56cffe6ce223/src/winetricks" ; fi
if [ -z "${WINETRICKS_DOWNLOADER+x}" ]; then export WINETRICKS_DOWNLOADER="wget" ; fi
if [ -z "${WINETRICKS_UNATTENDED+x}" ]; then export WINETRICKS_UNATTENDED="" ; fi

#=================================================
if [ -z "${WORKDIR}" ]; then WORKDIR="$(mktemp -d)"; export WORKDIR ; fi
if [ -z "${INSTALLDIR}" ]; then export INSTALLDIR="${HOME}/LogosBible10" ; fi
export APPDIR="${INSTALLDIR}/data"
export APPDIR_BINDIR="${APPDIR}/bin"
export APPIMAGE_LINK_SELECTION_NAME="selected_wine.AppImage"
if [ -z "${DOWNLOADED_RESOURCES}" ]; then export DOWNLOADED_RESOURCES="${PWD}" ; fi
if [ -z "${FORCE_ROOT+x}" ]; then export FORCE_ROOT="" ; fi
if [ -z "${WINEBOOT_GUI+x}" ]; then export WINEBOOT_GUI="" ; fi
export EXTRA_INFO="Usually is necessary: winbind cabextract libjpeg8."
#=================================================
#=================================================

#======= Aux =============
if [ "$(id -u)" -eq '0' ] && [ -z "${LOGOS_FORCE_ROOT}" ]; then
		echo "* Running Wine/winetricks as root is highly discouraged (you can set FORCE_ROOT=1). See https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.3F"
		gtk_fatal_error "Running Wine/winetricks as root is highly discouraged (you can set FORCE_ROOT=1). See https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.3F"
        exit 1;
fi

usage() {
cat << EOF
LogosLinuxInstaller, by $LOGOS_SCRIPT_TITLE, $LOGOS_SCRIPT_VERSION.

Usage: ./$LOGOS_SCRIPT_TITLE.sh
Installs Logos Bible Software with Wine in an AppImage on Linux.

Options:
    -h   --help         Prints this help message and exit.
    -v   --version      Prints version information and exit.
EOF
}

# BEGIN OPTARGS
RESET_OPTARGS=true
for arg in "$@"
do
    if [ -n "$RESET_OPTARGS" ]; then
      unset RESET_OPTARGS
      set -- 
    fi
    case "$arg" in
        --help)      set -- "$@" -h ;;
        --version)   set -- "$@" -V ;;
        *)           set -- "$@" "$arg" ;;
    esac
done
OPTSTRING=':hv' # Available options

# First loop: set variable options
while getopts "$OPTSTRING" opt; do
        case $opt in
        esac
done
OPTIND=1 # Reset the index.

# Second loop: determine user action
while getopts "$OPTSTRING" opt; do
    case $opt in
        h)  usage && exit ;;
        v)  echo "$LOGOS_SCRIPT_TITLE, $LOGOS_SCRIPT_VERSION by $LOGOS_SCRIPT_AUTHOR." &&     exit;;
        \?) echo "$LOGOS_SCRIPT_TITLE: -$OPTARG: undefined option." >&2 && usage >&2 &&      exit ;;
        :)  echo "$LOGOS_SCRIPT_TITLE: -$OPTARG: missing argument." >&2 && usage >&2 &&      exit ;;
    esac
done
if [ "$OPTIND" -eq '1' ]; then
        echo "No options were passed.";
fi
shift $((OPTIND-1))
# END OPTARGS

die() { echo >&2 "$*"; exit 1; };

have_dep() {
	command -v "$1" >/dev/null 2>&1
}

clean_all() {
	echo "Cleaning all temp files..."
	rm -rf "${WORKDIR}"
	echo "done"
}

#zenity------
gtk_info() {
	zenity --info --width=300 --height=200 --text="$*" --title='Information'
}
gtk_warn() {
	zenity --warning --width=300 --height=200 --text="$*" --title='Warning!'
}
gtk_error() {
	zenity --error --width=300 --height=200 --text="$*" --title='Error!'
}
gtk_fatal_error() {
	gtk_error "$@"
	echo "End in failure!"
	kill -SIGKILL "-$(($(ps -o pgid= -p "${$}")))"
	exit 1
}

mkdir_critical() {
	mkdir "$1" || gtk_fatal_error "Can't create the $1 directory"
}

gtk_question() {
	if zenity --question --width=300 --height=200 --text "$@" --title='Question:'
	then return 0
	else return 1
	fi
}
gtk_continue_question() {
	if ! gtk_question "$@"; then gtk_fatal_error "The installation was cancelled!"; fi
}

# shellcheck disable=SC2028
gtk_download() {
	# $1	what to download
	# $2	where into
	# NOTE: here must be a limitation to handle it easily. $2 can be dir if it already exists or if it ends with '/'

	URI="$1"
	# extract last field of URI as filename:
	FILENAME="${URI##*/}"

	if [ "$2" != "${2%/}" ]; then
		# it has '/' at the end or it is existing directory
		TARGET="$2/${1##*/}"
		[ -d "$2" ] || mkdir -p "$2" || gtk_fatal_error "Cannot create $2"
	elif [ -d "$2" ]; then
		# it's existing directory
		TARGET="$2/${1##*/}"
	else
		# $2 is file
		TARGET="$2"
		# ensure that the directory where the target file will be exists
		[ -d "${2%/*}" ] || mkdir -p "${2%/*}" || gtk_fatal_error "Cannot create directory ${2%/*}"
	fi

	echo "* Downloading:"
	echo "$1"
	echo "into:"
	echo "$2"

	pipe_progress="$(mktemp)"
	rm -rf "${pipe_progress}"
	mkfifo "${pipe_progress}"

	pipe_wget="$(mktemp)"
	rm -rf "${pipe_wget}"
	mkfifo "${pipe_wget}"

	# zenity GUI feedback
	zenity --progress --title "Downloading ${FILENAME}..." --text="Downloading: ${FILENAME}\ninto: ${2}\n" --percentage=0 --auto-close < "${pipe_progress}" &
	ZENITY_PID="${!}"

	# download the file with wget:
	wget -c "$1" -O "${TARGET}" > "${pipe_wget}" 2>&1 &
	WGET_PID="${!}"

	# process the dialog progress bar
	total_size="Starting..."
	percent="0"
	current="Starting..."
	speed="Starting..."
	remain="Starting..."
	while read -r data; do
		if echo "${data}" | grep -q '^Length:' ; then
			result="$(echo "${data}" | grep "^Length:" | sed 's/.*\((.*)\).*/\1/' |  tr -d '()')"
			if [ ${#result} -le 10 ]; then total_size=${result} ; fi
		fi

		if echo "${data}" | grep -q '[0-9]*%' ;then
			result="$(echo "${data}" | grep -o "[0-9]*%" | tr -d '%')"
			if [ ${#result} -le 3 ]; then percent=${result} ; fi

			result="$(echo "${data}" | grep "[0-9]*%" | sed 's/\([0-9BKMG]\+\).*/\1/' )"
			if [ ${#result} -le 10 ]; then current=${result} ; fi

			result="$(echo "${data}" | grep "[0-9]*%" | sed 's/.*\(% [0-9BKMG.]\+\).*/\1/' | tr -d ' %')"
			if [ ${#result} -le 10 ]; then speed=${result} ; fi

			result="$(echo "${data}" | grep -o "[0-9A-Za-z]*$" )"
			if [ ${#result} -le 10 ]; then remain=${result} ; fi
		fi

		if [ -z "$(pgrep -P "${$}" zenity)" ]; then
			WGET_PID_CURRENT="$(pgrep -P "${$}" wget)"
			[ -n "${WGET_PID_CURRENT}" ] && kill -SIGKILL "${WGET_PID_CURRENT}"
		fi

		[ "${percent}" == "100" ] && break
		# report
		echo "${percent}"
		echo "#Downloading: ${FILENAME}\ninto: $2\n\n${current} of ${total_size} \(${percent}%\)\nSpeed : ${speed}/Sec\nEstimated time : ${remain}"
	done < "${pipe_wget}" > "${pipe_progress}"

	wait "${WGET_PID}"
	WGET_RETURN="${?}"

	wait "${ZENITY_PID}"
	ZENITY_RETURN="${?}"

	fuser -TERM -k -w "${pipe_progress}"
	rm -rf "${pipe_progress}"

	fuser -TERM -k -w "${pipe_wget}"
	rm -rf "${pipe_wget}"

	# NOTE: sometimes the process finishes before the wait command, giving the error code 127
	if [ "${ZENITY_RETURN}" == "0" ] || [ "${ZENITY_RETURN}" == "127" ] ; then
		if [ "${WGET_RETURN}" != "0" ] && [ "${WGET_RETURN}" != "127" ] ; then
			echo "ERROR: error downloading the file! WGET_RETURN: ${WGET_RETURN}"
			gtk_fatal_error "The installation was cancelled because of error downloading the file!\n * ${FILENAME}\n  - WGET_RETURN: ${WGET_RETURN}"
		fi
	else
		gtk_fatal_error "The installation was cancelled!\n * ZENITY_RETURN: ${ZENITY_RETURN}"
	fi
	echo "${FILENAME} download finished!"
}

check_commands() {
	for cmd in "$@"; do
		if have_dep "${cmd}"; then
			echo "* command ${cmd} is installed!"
		else
			echo "* Your system does not have the command: ${cmd}. Please install command ${cmd} package. ${EXTRA_INFO}"
			gtk_fatal_error "Your system does not have command: ${cmd}. Please install command ${cmd} package.\n ${EXTRA_INFO}"
		fi
	done
}
# shellcheck disable=SC2001
check_libs() {
	for lib in "$@"; do
		HAVE_LIB="$(ldconfig -N -v "$(sed 's/:/ /g' <<< "${LD_LIBRARY_PATH}")" 2>/dev/null | grep "${lib}")"
		if [ -n "${HAVE_LIB}" ]; then
			echo "* ${lib} is installed!"
		else
			echo "* Your system does not have the lib: ${lib}. Please install ${lib} package. ${EXTRA_INFO}"
			gtk_fatal_error "Your system does not have lib: ${lib}. Please install ${lib} package.\n ${EXTRA_INFO}"
		fi
	done
}
#--------------
#==========================

# wait on all processes that are using the ${1} directory to finish
wait_process_using_dir() {
	VERIFICATION_DIR="${1}"
	VERIFICATION_TIME=7
	VERIFICATION_NUM=3

	echo "---------------------"
	echo "* Starting wait_process_using_dir..."
	i=0 ; while true; do
		i=$((i+1))
		echo "-------"
		echo "wait_process_using_dir: loop with i=${i}"

		echo "wait_process_using_dir: sleep ${VERIFICATION_TIME}"
		sleep "${VERIFICATION_TIME}"

		FIST_PID="$(lsof -t "${VERIFICATION_DIR}" | head -n 1)"
		echo "wait_process_using_dir FIST_PID: ${FIST_PID}"
		if [ -n "${FIST_PID}" ]; then
			i=0
			echo "wait_process_using_dir: tail --pid=${FIST_PID} -f /dev/null"
			tail --pid="${FIST_PID}" -f /dev/null
			continue
		fi

		echo "-------"
		[ "${i}" -lt "${VERIFICATION_NUM}" ] || break
	done
	echo "* End of wait_process_using_dir."
	echo "---------------------"
}

#======= making the starting scripts ==============
create_starting_scripts() {
# ${1} - WINE_BITS: 32 or 64
# ${2} - WINE_EXE name: wine or wine64
	WINE_BITS="${1}"
	WINE_EXE="${2}"

	echo "Creating starting scripts for LogosBible ${WINE_BITS}bits..."
	#------- Logos.sh -------------
	cat > "${WORKDIR}"/Logos.sh << EOF
#!/bin/bash
# generated by "${LOGOS_SCRIPT_VERSION}" script from https://github.com/ferion11/LogosLinuxInstaller

#------------- Starting block --------------------
HERE="\$(dirname "\$(readlink -f "\${0}")")"

# Save IFS
IFS_TMP=\${IFS}
IFS=$'\n'
#-------------------------------------------------

#-------------------------------------------------
[ -x "\${HERE}/data/bin/${WINE_EXE}" ] && export PATH="\${HERE}/data/bin:\${PATH}"
export WINEARCH=win${WINE_BITS}
export WINEPREFIX="\${HERE}/data/wine${WINE_BITS}_bottle"
#-------
[ -z "\${LOGOS_ICON_URL}" ] && export LOGOS_ICON_URL="${LOGOS_ICON_URL}"
LOGOS_ICON_FILENAME="\$(basename "\${LOGOS_ICON_URL}")"; export LOGOS_ICON_FILENAME
#-------------------------------------------------

#-------------------------------------------------
case "\${1}" in
	"${WINE_EXE}"|"wineserver"|"winetricks"|"selectAppImage")
		"\${HERE}/controlPanel.sh" "\$@"
		exit 0
		;;
	"indexing")
		# Indexing Run:
		echo "======= Running indexing on the Logos inside this installation only: ======="
		LOGOS_INDEXER_EXE=\$(find "\${WINEPREFIX}" -name LogosIndexer.exe |  grep "Logos\/System\/LogosIndexer.exe")
		if [ -z "\${LOGOS_INDEXER_EXE}" ] ; then
			echo "* ERROR: the LogosIndexer.exe can't be found!!!"
			exit 1
		fi
		echo "* Closing anything running in this wine bottle:"
		wineserver -k
		echo "* Running the indexer:"
		${WINE_EXE} "\${LOGOS_INDEXER_EXE}"
		wineserver -w
		echo "======= indexing of LogosBible run done! ======="
		exit 0
		;;
	"removeAllIndex")
		echo "======= removing all LogosBible index files only: ======="
		LOGOS_EXE="\$(find "\${WINEPREFIX}" -name Logos.exe | grep "Logos\/Logos.exe")"
		LOGOS_DIR="\$(dirname "\${LOGOS_EXE}")"
		rm -fv "\${LOGOS_DIR}"/Data/*/BibleIndex/*
		rm -fv "\${LOGOS_DIR}"/Data/*/LibraryIndex/*
		rm -fv "\${LOGOS_DIR}"/Data/*/PersonalBookIndex/*
		rm -fv "\${LOGOS_DIR}"/Data/*/LibraryCatalog/*
		echo "======= removing all LogosBible index files done! ======="
		exit 0
		;;
	"logsOn")
		echo "======= enable LogosBible logging only: ======="
		${WINE_EXE} reg add "HKCU\\\\Software\\\\Logos4\\\\Logging" /v Enabled /t REG_DWORD /d 0001 /f
		wineserver -w
		echo "======= enable LogosBible logging done! ======="
		exit 0
		;;
	"logsOff")
		echo "======= disable LogosBible logging only: ======="
		${WINE_EXE} reg add "HKCU\\\\Software\\\\Logos4\\\\Logging" /v Enabled /t REG_DWORD /d 0000 /f
		wineserver -w
		echo "======= disable LogosBible logging done! ======="
		exit 0
		;;
	"dirlink")
		echo "======= making LogosBible dir link only: ======="
		LOGOS_EXE="\$(find "\${WINEPREFIX}" -name Logos.exe | grep "Logos\/Logos.exe")"
		LOGOS_DIR="\$(dirname "\${LOGOS_EXE}")"
		LOGOS_DIR_RELATIVE="\$(realpath --relative-to="\${HERE}" "\${LOGOS_DIR}")"
		rm -f "\${HERE}/installation_dir"
		ln -s "\${LOGOS_DIR_RELATIVE}" "\${HERE}/installation_dir"
		echo "dirlink created at: \${HERE}/installation_dir"
		echo "======= making LogosBible dir link done! ======="
		exit 0
		;;
	"shortcut")
		echo "======= making new LogosBible shortcut only: ======="
		[ ! -f "\${HERE}/data/\${LOGOS_ICON_FILENAME}" ] && wget -c "\${LOGOS_ICON_URL}" -P "\${HERE}/data"
		mkdir -p "\${HOME}/.local/share/applications"
		rm -rf "\${HOME}/.local/share/applications/LogosBible.desktop"
		echo "[Desktop Entry]" > "\${HERE}"/LogosBible.desktop
		echo "Name=LogosBible" >> "\${HERE}"/LogosBible.desktop
		echo "Comment=A Bible Study Library with Built-In Tools" >> "\${HERE}"/LogosBible.desktop
		echo "Exec=\${HERE}/Logos.sh" >> "\${HERE}"/LogosBible.desktop
		echo "Icon=\${HERE}/data/logos4-128-icon.png" >> "\${HERE}"/LogosBible.desktop
		echo "Terminal=false" >> "\${HERE}"/LogosBible.desktop
		echo "Type=Application" >> "\${HERE}"/LogosBible.desktop
		echo "Categories=Education;" >> "\${HERE}"/LogosBible.desktop
		chmod +x "\${HERE}"/LogosBible.desktop
		mv "\${HERE}"/LogosBible.desktop "\${HOME}/.local/share/applications"
		echo "File: \${HOME}/.local/share/applications/LogosBible.desktop updated"
		echo "======= making new LogosBible.desktop shortcut done! ======="
		exit 0
		;;
	*)
		echo "No arguments parsed."
esac

LOGOS_EXE=\$(find "\${WINEPREFIX}" -name Logos.exe | grep "Logos\/Logos.exe")
if [ -z "\${LOGOS_EXE}" ] ; then
	echo "======= Running control: ======="
	"\${HERE}/controlPanel.sh" "\$@"
	echo "======= control run done! ======="
	exit 0
fi

${WINE_EXE} "\${LOGOS_EXE}"
wineserver -w
#-------------------------------------------------

#------------- Ending block ----------------------
# restore IFS
IFS=\${IFS_TMP}
#-------------------------------------------------
EOF
	#------------------------------
	chmod +x "${WORKDIR}"/Logos.sh
	mv "${WORKDIR}"/Logos.sh "${INSTALLDIR}"/

	#------- controlPanel.sh ------
	cat > "${WORKDIR}"/controlPanel.sh << EOF
#!/bin/bash
# generated by "${LOGOS_SCRIPT_VERSION}" script from https://github.com/ferion11/LogosLinuxInstaller

#------------- Starting block --------------------
HERE="\$(dirname "\$(readlink -f "\${0}")")"

# Save IFS
IFS_TMP=\${IFS}
IFS=$'\n'
#-------------------------------------------------

#-------------------------------------------------
[ -x "\${HERE}/data/bin/${WINE_EXE}" ] && export PATH="\${HERE}/data/bin:\${PATH}"
export WINEARCH=win${WINE_BITS}
export WINEPREFIX="\${HERE}/data/wine${WINE_BITS}_bottle"
#-------
[ -z "\${WINETRICKS_URL}" ] && export WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
[ -z "\${WINETRICKS_DOWNLOADER+x}" ] && export WINETRICKS_DOWNLOADER="wget"
#-------------------------------------------------

#-------------------------------------------------
case "\${1}" in
	"${WINE_EXE}")
		# ${WINE_EXE} Run:
		echo "======= Running ${WINE_EXE} only: ======="
		shift
		${WINE_EXE} "\$@"
		wineserver -w
		echo "======= ${WINE_EXE} run done! ======="
		exit 0
		;;
	"wineserver")
		# wineserver Run:
		echo "======= Running wineserver only: ======="
		shift
		wineserver "\$@"
		echo "======= wineserver run done! ======="
		exit 0
		;;
	"winetricks")
		# winetricks Run:
		echo "======= Running winetricks only: ======="
		WORKDIR="\$(mktemp -d)"
		if [ -f "\${HERE}/winetricks" ]; then cp "\${HERE}/winetricks" "\${WORKDIR}"
		else wget -c -P "\${WORKDIR}" "\${WINETRICKS_URL}"
		fi
		chmod +x "\${WORKDIR}"/winetricks
		shift
		"\${WORKDIR}"/winetricks "\$@"
		rm -rf "\${WORKDIR}"
		wineserver -w
		echo "======= winetricks run done! ======="
		exit 0
		;;
	"selectAppImage")
		echo "======= Running AppImage Selection only: ======="
		APPIMAGE_FILENAME=""
		APPIMAGE_LINK_SELECTION_NAME="${APPIMAGE_LINK_SELECTION_NAME}"

		APPIMAGE_FULLPATH="\$(zenity --file-selection --filename="\${HERE}"/data/*.AppImage --file-filter='AppImage files | *.AppImage *.Appimage *.appImage *.appimage' --file-filter='All files | *')"
		if [ -z "\${APPIMAGE_FULLPATH}" ]; then
			echo "No *.AppImage file selected! exiting..."
			exit 1
		fi

		APPIMAGE_FILENAME="\${APPIMAGE_FULLPATH##*/}"
		APPIMAGE_DIR="\${APPIMAGE_FULLPATH%\${APPIMAGE_FILENAME}}"
		APPIMAGE_DIR="\${APPIMAGE_DIR%?}"
		#-------

		if [ "\${APPIMAGE_DIR}" != "\${HERE}/data" ]; then
			if zenity --question --width=300 --height=200 --text="Warning: The AppImage isn't at \"./data/ directory\"\!\nDo you want to copy the AppImage to the \"./data/\" directory keeping portability?" --title='Warning!'; then
				[ -f "\${HERE}/data/\${APPIMAGE_FILENAME}" ] && rm -rf "\${HERE}/data/\${APPIMAGE_FILENAME}"
				cp "\${APPIMAGE_FULLPATH}" "\${HERE}/data/"
				APPIMAGE_FULLPATH="\${HERE}/data/\${APPIMAGE_FILENAME}"
			else
				echo "Warning: Linking \${APPIMAGE_FULLPATH} to ./data/bin/\${APPIMAGE_LINK_SELECTION_NAME}"
				chmod +x "\${APPIMAGE_FULLPATH}"
				ln -s "\${APPIMAGE_FULLPATH}" "\${APPIMAGE_LINK_SELECTION_NAME}"
				rm -rf "\${HERE}/data/bin/\${APPIMAGE_LINK_SELECTION_NAME}"
				mv "\${APPIMAGE_LINK_SELECTION_NAME}" "\${HERE}/data/bin/"
				(DISPLAY="" "\${HERE}/controlPanel.sh" ${WINE_EXE} wineboot) | zenity --progress --title="Wine Bottle update" --text="Updating Wine Bottle..." --pulsate --auto-close --no-cancel
				echo "======= AppImage Selection run done with external link! ======="
				exit 0
			fi
		fi

		echo "Info: Linking ../\${APPIMAGE_FILENAME} to ./data/bin/\${APPIMAGE_LINK_SELECTION_NAME}"
		chmod +x "\${APPIMAGE_FULLPATH}"
		ln -s "../\${APPIMAGE_FILENAME}" "\${APPIMAGE_LINK_SELECTION_NAME}"
		rm -rf "\${HERE}/data/bin/\${APPIMAGE_LINK_SELECTION_NAME}"
		mv "\${APPIMAGE_LINK_SELECTION_NAME}" "\${HERE}/data/bin/"
		(DISPLAY="" "\${HERE}/controlPanel.sh" ${WINE_EXE} wineboot) | zenity --progress --title="Wine Bottle update" --text="Updating Wine Bottle..." --pulsate --auto-close --no-cancel
		echo "======= AppImage Selection run done! ======="
		exit 0
		;;
	*)
		echo "No arguments parsed."
esac

${WINE_EXE} control
wineserver -w
#-------------------------------------------------

#------------- Ending block ----------------------
# restore IFS
IFS=\${IFS_TMP}
#-------------------------------------------------
EOF
	#------------------------------
	chmod +x "${WORKDIR}"/controlPanel.sh
	mv "${WORKDIR}"/controlPanel.sh "${INSTALLDIR}"/
}

make_skel() {
# ${1} - WINE_BITS: 32 or 64
# ${2} - WINE_EXE name: wine or wine64
# ${3} - SET_APPIMAGE_FILENAME
	WINE_BITS="${1}"
	WINE_EXE="${2}"
	SET_APPIMAGE_FILENAME="${3}"

	echo "* Making skel${WINE_BITS} inside ${INSTALLDIR}"
	mkdir -p "${INSTALLDIR}"
	mkdir "${APPDIR}" || die "can't make dir: ${APPDIR}"

	# Making the links (and dir)
	mkdir "${APPDIR_BINDIR}" || die "can't make dir: ${APPDIR_BINDIR}"
	cd "${APPDIR_BINDIR}" || die "ERROR: Can't enter on dir: ${APPDIR_BINDIR}"
	ln -s "../${SET_APPIMAGE_FILENAME}" "${APPIMAGE_LINK_SELECTION_NAME}"
	ln -s "${APPIMAGE_LINK_SELECTION_NAME}" wine
	[ "${WINE_BITS}" == "64" ] && ln -s "${APPIMAGE_LINK_SELECTION_NAME}" wine64
	ln -s "${APPIMAGE_LINK_SELECTION_NAME}" wineserver
	cd - || die "ERROR: Can't go back to preview dir!"

	mkdir "${APPDIR}/wine${WINE_BITS}_bottle"
	create_starting_scripts "${WINE_BITS}" "${WINE_EXE}"

	echo "skel${WINE_BITS} done!"
}
#==================================================

#======= Basic Deps =============
echo "================================================="
echo 'Searching for dependencies:'

if [ -z "${DISPLAY}" ]; then
	echo "* You want to run without X, but it doesn't work."
	exit 1
fi

if have_dep zenity; then
	echo '* Zenity is installed!'
else
	echo '* Your system does not have Zenity. Please install Zenity package.'
	exit 1
fi

#check_commands mktemp patch lsof wget xwd find sed grep cabextract ntlm_auth
check_commands mktemp patch lsof wget find sed grep ntlm_auth
#check_libs libjpeg.so.8

echo "================================================="
echo "Starting Zenity GUI..."
#==========================


#======= Parsing =============
case "${1}" in
	"skel64")
		export WINE_EXE="wine64"
		make_skel "64" "${WINE_EXE}" "none.AppImage"
		rm -rf "${WORKDIR}"
		exit 0
		echo "================================================="
		;;
	*)
		echo "No arguments parsed."
		echo "================================================="
esac

#======= Main =============
if [ -d "${INSTALLDIR}" ]; then
	echo "A directory already exists at ${INSTALLDIR}. Please remove/rename it or use another location by setting the INSTALLDIR variable"
	gtk_fatal_error "a directory already exists at ${INSTALLDIR}. Please remove/rename it or use another location by setting the INSTALLDIR variable"
fi

echo "* Script version: ${LOGOS_SCRIPT_VERSION}"
installationChoice="$(zenity --width=700 --height=310 \
	--title="Question: Install Logos Bible using script ${LOGOS_SCRIPT_VERSION}" \
	--text="This script will create one directory in (which can be changed by setting the INSTALLDIR variable):\n\"${INSTALLDIR}\"\nto be an installation of LogosBible v${LOGOS_VERSION} independent of other installations.\nPlease select the type of installation:" \
	--list --radiolist --column "S" --column "Description" \
	TRUE "1- Install LogosBible64 using the native Wine64 (default) Which must be 7.18-staging or later. Stable or Devel do not work." \
	FALSE "2- Install LogosBible64 using Wine64 ${WINE64_APPIMAGE_FULL_VERSION} AppImage." )"
# FALSE "3- Install LogosBible64 using Wine64 ${WINE64_APPIMAGE_VERSION} plain AppImage without dependencies."

case "${installationChoice}" in
	1*)
		echo "Installing LogosBible 64bits using the native Wine..."
		export NO_APPIMAGE="1"
		export WINEARCH=win64
		export WINEPREFIX="${APPDIR}/wine64_bottle"
		export WINE_EXE="wine64"

		# check for wine installation
		WINE_VERSION_CHECK="$(${WINE_EXE} --version)"
		[ -z "${WINE_VERSION_CHECK}" ] && gtk_fatal_error "Wine64 not found! Please install native Wine64 first."
		echo "Using: ${WINE_VERSION_CHECK}"

		make_skel "64" "${WINE_EXE}" "none.AppImage"
		;;
	2*)
		echo "Installing LogosBible 64bits using ${WINE64_APPIMAGE_FULL_VERSION} AppImage..."
		export WINEARCH=win64
		export WINEPREFIX="${APPDIR}/wine64_bottle"
		export WINE_EXE="wine64"

		make_skel "64" "${WINE_EXE}" "${WINE64_APPIMAGE_FULL_FILENAME}"
		export SET_APPIMAGE_FILENAME="${WINE64_APPIMAGE_FULL_FILENAME}"
		export SET_APPIMAGE_URL="${WINE64_APPIMAGE_FULL_URL}"
		;;
	3*)
		echo "Installing LogosBible 64bits using ${WINE64_APPIMAGE_VERSION} plain AppImage without dependencies..."
		export WINEARCH=win64
		export WINEPREFIX="${APPDIR}/wine64_bottle"
		export WINE_EXE="wine64"

		make_skel "64" "${WINE_EXE}" "${WINE64_APPIMAGE_FILENAME}"
		export SET_APPIMAGE_FILENAME="${WINE64_APPIMAGE_FILENAME}"
		export SET_APPIMAGE_URL="${WINE64_APPIMAGE_URL}"
		;;
	*)
		gtk_fatal_error "Installation canceled!"
esac

# exporting PATH to internal use if using AppImage, doing backup too:
if [ -z "${NO_APPIMAGE}" ] ; then
	export OLD_PATH="${PATH}"
	export PATH="${APPDIR_BINDIR}":"${PATH}"
fi

if [ -z "${NO_APPIMAGE}" ] ; then
	echo "================================================="
	echo "Using AppImage: ${SET_APPIMAGE_FILENAME}"
	#-------------------------
	# Geting the AppImage:
	if [ -f "${DOWNLOADED_RESOURCES}/${SET_APPIMAGE_FILENAME}" ]; then
		echo "${SET_APPIMAGE_FILENAME} exist. Using it..."
		cp "${DOWNLOADED_RESOURCES}/${SET_APPIMAGE_FILENAME}" "${APPDIR}/" | zenity --progress --title="Copying..." --text="Copying: ${SET_APPIMAGE_FILENAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
	else
		echo "${SET_APPIMAGE_FILENAME} does not exist. Downloading..."
		gtk_download "${SET_APPIMAGE_URL}" "${WORKDIR}"

		mv "${WORKDIR}/${SET_APPIMAGE_FILENAME}" "${APPDIR}" | zenity --progress --title="Moving..." --text="Moving: ${SET_APPIMAGE_FILENAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
	fi

	chmod +x "${APPDIR}/${SET_APPIMAGE_FILENAME}"
	echo "Using: $(${WINE_EXE} --version)"
	echo "================================================="
	#-------------------------
fi
#-------------------------------------------------

light_wineserver_wait() {
	echo "* Waiting for ${WINE_EXE} to end properly..."
	wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to end properly..." --pulsate --auto-close --no-cancel
}
heavy_wineserver_wait() {
	echo "* Waiting for ${WINE_EXE} to end properly..."
	wait_process_using_dir "${WINEPREFIX}" | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to end properly..." --pulsate --auto-close --no-cancel
	wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to end properly..." --pulsate --auto-close --no-cancel
}

gtk_continue_question "Now the script will create and configure the Wine Bottle at ${WINEPREFIX}. You can cancel the instalation of Mono. Do you wish to continue?"
echo "================================================="
echo "${WINE_EXE} wineboot"
if [ -z "${WINEBOOT_GUI}" ]; then
	(DISPLAY="" ${WINE_EXE} wineboot) | zenity --progress --title="Waiting ${WINE_EXE} wineboot" --text="Waiting for ${WINE_EXE} wineboot..." --pulsate --auto-close --no-cancel
else
	${WINE_EXE} wineboot
fi
light_wineserver_wait
echo "================================================="

#-------------------------------------------------
cat > "${WORKDIR}"/disable-winemenubuilder.reg << EOF
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"winemenubuilder.exe"=""

EOF

cat > "${WORKDIR}"/renderer_gdi.reg << EOF
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"DirectDrawRenderer"="gdi"
"renderer"="gdi"

EOF

wine_reg_install() {
	REG_FILENAME="${1}"
	echo "${WINE_EXE} regedit.exe ${REG_FILENAME}"
	${WINE_EXE} regedit.exe "${WORKDIR}"/"${REG_FILENAME}" | zenity --progress --title="Wine regedit" --text="Wine is installing ${REG_FILENAME} in ${WINEPREFIX}" --pulsate --auto-close --no-cancel

	light_wineserver_wait
	echo "${WINE_EXE} regedit.exe ${REG_FILENAME} DONE!"
}
echo "================================================="
wine_reg_install "disable-winemenubuilder.reg"
echo "================================================="
wine_reg_install "renderer_gdi.reg"
echo "================================================="

downloadWinetricks() {
	echo "Downloading winetricks from the Internet…"
	if [ -f "${DOWNLOADED_RESOURCES}/winetricks" ]; then
		echo "A winetricks binary has already been downloaded. Using it..."
		cp "${DOWNLOADED_RESOURCES}/winetricks" "${WORKDIR}"
	else
		echo "winetricks does not exist. Downloading..."
		gtk_download "${WINETRICKS_URL}" "${WORKDIR}"
	fi
	chmod +x "${WORKDIR}/winetricks"
}

if [ "$(which winetricks)" ]; then
	winetricksChoice="$(zenity --width=700 --height=310 \
    --title="Question: Should the script use local winetricks or download winetricks fresh?" \
    --text="This script needs to set some Wine options that help or make Logos run on Linux. Please select whether to use your local winetricks version or a fresh install." \
    --list --radiolist --column "S" --column "Description" \
    TRUE "1- Use local winetricks." \
    FALSE "2- Download winetricks from the Internet." )"

	case "${winetricksChoice}" in
    	1*)
    	    echo "Setting winetricks to the local binary..."
			if [ -z "${WINETRICKSBIN}" ]; then WINETRICKSBIN="$(which winetricks)"; fi
    	    ;;
    	2*)
			downloadWinetricks;
			if [ -z "${WINETRICKSBIN}" ]; then WINETRICKSBIN="${WORKDIR}/winetricks"; fi
    	    ;;
    	*)
    	    gtk_fatal_error "Installation canceled!"
	esac
else
	echo "Local winetricks not found. Downloading winetricks from the Internet…"
	downloadWinetricks;
	export WINETRICKSBIN="${WORKDIR}/winetricks"
fi

echo "Winetricks is ready to be used."

#-------------------------------------------------
winetricks_install() {
	echo "winetricks ${*}"
	pipe_winetricks="$(mktemp)"
	rm -rf "${pipe_winetricks}"
	mkfifo "${pipe_winetricks}"

	# zenity GUI feedback
	zenity --progress --title="Winetricks ${*}" --text="Winetricks installing ${*}" --pulsate --auto-close < "${pipe_winetricks}" &
	ZENITY_PID="${!}"

	"$WINETRICKSBIN" "${@}" | tee "${pipe_winetricks}";
	WINETRICKS_STATUS="${?}";

	wait "${ZENITY_PID}";
	ZENITY_RETURN="${?}";

	rm -rf "${pipe_winetricks}";

	# NOTE: sometimes the process finishes before the wait command, giving the error code 127
	if [ "${ZENITY_RETURN}" == "0" ] || [ "${ZENITY_RETURN}" == "127" ] ; then
		if [ "${WINETRICKS_STATUS}" != "0" ] ; then
			wineserver -k;
			echo "ERROR on : winetricks ${*}; WINETRICKS_STATUS: ${WINETRICKS_STATUS}";
			gtk_fatal_error "The installation was cancelled because of sub-job failure!\n * winetricks ${*}\n  - WINETRICKS_STATUS: ${WINETRICKS_STATUS}";
		fi
	else
		wineserver -k;
		gtk_fatal_error "The installation was cancelled!\n * ZENITY_RETURN: ${ZENITY_RETURN}";
	fi
	echo "winetricks ${*} DONE!";

	heavy_wineserver_wait;
}

winetricks_dll_install() {
    echo "winetricks ${*}"
    
	gtk_continue_question "Now the script will install the DLL ${*}. Continue?"

	"$WINETRICKSBIN" "${@}"

    echo "winetricks ${*} DONE!";
    
    heavy_wineserver_wait;

}

if [ -z "${WINETRICKS_UNATTENDED}" ]; then
	winetricks_install -q corefonts
	winetricks_install -q tahoma
	winetricks_install -q settings fontsmooth=rgb
	winetricks_install -q settings win10
	winetricks_dll_install -q d3dcompiler_47;
else
	echo "================================================="
	winetricks_install corefonts
	echo "================================================="
	winetricks_install tahoma
	echo "================================================="
	winetricks_install settings fontsmooth=rgb
	echo "================================================="
	winetricks_install settings win10
	echo "================================================="
	winetricks_dll_install d3dcompiler_47
	echo "================================================="
fi
#-------------------------------------------------

gtk_continue_question "You need to supply the installer, download from https://www.logos.com/get-started and place the installer in ${INSTALLDIR}.\nLogos 10 is currently only available to those who have a license.\nIn previous years the free engine is made available to everyone a few months later.\nYou will need to interact with the installer. The progress slider does not show progress but it is working.\n\nI HAVE PLACED THE INSTALLER IN THE CORRECT DIR AND WISH TO CONTINUE..."

echo "================================================="
# Geting and install the LogosBible:
echo "Installing LogosBible 64bits..."
if [ -f "${INSTALLDIR}/${LOGOS64_MSI}" ]; then
	echo "${LOGOS64_MSI} exist. Using it..."
#	cp "${INSTALLDIR}/${LOGOS64_MSI}" "${WORKDIR}/" | zenity --progress --title="Copying..." --text="Copying: ${LOGOS64_MSI}\ninto: ${WORKDIR}" --pulsate --auto-close --no-cancel
else
	echo "${LOGOS64_MSI} was not found. This installer is exiting. All files created are in ${INSTALLDIR} and you may delete them. Please try again and ensure the installer is placed in the correct directory."
	exit 1
#	gtk_download "${LOGOS64_URL}" "${WORKDIR}"
fi
echo "${WINE_EXE} ${LOGOS64_MSI}"
${WINE_EXE} "${INSTALLDIR}"/"${LOGOS64_MSI}"

#echo "======= Set LogosBible Indexing to Vista Mode: ======="
#${WINE_EXE} reg add "HKCU\\Software\\Wine\\AppDefaults\\LogosIndexer.exe" /v Version /t #REG_SZ /d vista /f
#echo "======= LogosBible logging set to Vista mode! ======="

heavy_wineserver_wait
echo "================================================="
clean_all
echo "================================================="

if gtk_question "Logos Bible Installed!\nYou can run it using the script Logos.sh inside ${INSTALLDIR}.\nDo you want to run it now?\nNOTE: Just close the error on the first execution."; then
	"${INSTALLDIR}"/Logos.sh
fi

echo "End!"
echo "================================================="
exit 0
#==========================
