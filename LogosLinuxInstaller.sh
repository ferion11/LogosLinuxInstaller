#!/bin/bash

LOGOS_SCRIPT_TITLE="Logos Linux Installer" # From https://github.com/ferion11/LogosLinuxInstaller
LOGOS_SCRIPT_AUTHOR="Ferion11, John Goodman, T. H. Wright"
LOGOS_SCRIPT_VERSION="v10.0-4" # Script version to match FaithLife Product version.

#####
# Originally written by Ferion11.
# Modified to install Logoos 10 by Revd. John Goodman M0RVJ
# Modified for optargs, to be FaithLife-product-agnostic, and general code refactoring by Revd. T. H. Wright
#####

# BEGIN ENVIRONMENT
if [ -z "${WINE64_APPIMAGE_FULL_VERSION}" ]; then WINE64_APPIMAGE_FULL_VERSION="v7.18-staging"; export WINE64_APPIMAGE_FULL_VERSION; fi
if [ -z "${WINE64_APPIMAGE_FULL_URL}" ]; then WINE64_APPIMAGE_FULL_URL="https://github.com/ferion11/LogosLinuxInstaller/releases/download/v10.0-1/wine-staging_7.18-x86_64.AppImage"; export WINE64_APPIMAGE_FULL_URL; fi
if [ -z "${WINE64_APPIMAGE_FULL_FILENAME}" ]; then WINE64_APPIMAGE_FULL_FILENAME="$(basename "${WINE64_APPIMAGE_FULL_URL}")"; export WINE64_APPIMAGE_FULL_FILENAME; fi
if [ -z "${WINE64_APPIMAGE_VERSION}" ]; then WINE64_APPIMAGE_VERSION="v7.18-staging"; export WINE64_APPIMAGE_VERSION; fi
if [ -z "${WINE64_APPIMAGE_URL}" ]; then WINE64_APPIMAGE_URL="https://github.com/ferion11/LogosLinuxInstaller/releases/download/v10.0-1/wine-staging_7.18-x86_64.AppImage"; export WINE64_APPIMAGE_URL; fi
if [ -z "${WINE64_APPIMAGE_FILENAME}" ]; then WINE64_APPIMAGE_FILENAME="$(basename "${WINE64_APPIMAGE_URL}" .AppImage)"; export WINE64_APPIMAGE_FILENAME; fi
if [ -z "${APPIMAGE_LINK_SELECTION_NAME}" ]; then APPIMAGE_LINK_SELECTION_NAME="selected_wine.AppImage"; fi
if [ -z "${WINETRICKS_URL}" ]; then WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/5904ee355e37dff4a3ab37e1573c56cffe6ce223/src/winetricks"; export WINETRICKS_URL; fi
if [ -z "${WINETRICKS_DOWNLOADER+x}" ]; then WINETRICKS_DOWNLOADER="wget" ; export WINETRICKS_DOWNLOADER; fi
if [ -z "${WINETRICKS_UNATTENDED+x}" ]; then WINETRICKS_UNATTENDED="" ; export WINETRICKS_UNATTENDED; fi
if [ -z "${WORKDIR}" ]; then WORKDIR="$(mktemp -d LBS.XXXXXXXX)"; export WORKDIR ; fi
if [ -z "${PRESENT_WORKING_DIRECTORY}" ]; then PRESENT_WORKING_DIRECTORY="${PWD}" ; export PRESENT_WORKING_DIRECTORY; fi
if [ -z "${LOGOS_FORCE_ROOT+x}" ]; then export LOGOS_FORCE_ROOT="" ; fi
if [ -z "${WINEBOOT_GUI+x}" ]; then export WINEBOOT_GUI="" ; fi
if [ -z "${EXTRA_INFO}" ]; then EXTRA_INFO="Usually is necessary: winbind cabextract libjpeg8."; export EXTRA_INFO; fi
if [ -z "${WINEDEBUG}" ]; then WINEDEBUG="fixme-all,err-all"; fi # Make wine output less verbose
# END ENVIRONMENT

usage() {
cat << EOF
$LOGOS_SCRIPT_TITLE, by $LOGOS_SCRIPT_AUTHOR, $LOGOS_SCRIPT_VERSION.

Usage: ./$LOGOS_SCRIPT_TITLE.sh
Installs ${FLPRODUCT} Bible Software with Wine in an AppImage on Linux.

Options:
    -h   --help         Prints this help message and exit.
    -v   --version      Prints version information and exit.
    -D   --debug        Makes Wine print out additional info.
    -f   --force-root   Sets LOGOS_FORCE_ROOT to true, which permits
                        the root user to run the script.
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
    case "$arg" in # Relate long options to short options
        --help)      set -- "$@" -h ;;
        --version)   set -- "$@" -V ;;
		--force-root) set -- "$@" -f ;;
		--debug)     set -- "$@" -D ;;
        *)           set -- "$@" "$arg" ;;
    esac
done
OPTSTRING=':hvDf' # Available options

# First loop: set variable options which may affect other options
while getopts "$OPTSTRING" opt; do
	case $opt in
		f)	export LOGOS_FORCE_ROOT="1"; ;;
		D)	export DEBUG=true;
			WINEDEBUG=""; ;;
		\?) echo "$LOGOS_SCRIPT_TITLE: -$OPTARG: undefined option." >&2 && usage >&2 && exit ;;
		:)  echo "$LOGOS_SCRIPT_TITLE: -$OPTARG: missing argument." >&2 && usage >&2 && exit ;;
	esac
done
OPTIND=1 # Reset the index.

# Second loop: determine user action
while getopts "$OPTSTRING" opt; do
    case $opt in
        h)  usage && exit ;;
        v)  echo "$LOGOS_SCRIPT_TITLE, $LOGOS_SCRIPT_VERSION by $LOGOS_SCRIPT_AUTHOR." && exit;;
        \?) echo "$LOGOS_SCRIPT_TITLE: -$OPTARG: undefined option." >&2 && usage >&2 && exit ;;
        :)  echo "$LOGOS_SCRIPT_TITLE: -$OPTARG: missing argument." >&2 && usage >&2 && exit ;;
    esac
done
if [ "$OPTIND" -eq '1' ]; then
        echo "No options were passed.";
fi
shift $((OPTIND-1))
# END OPTARGS

# BEGIN DIE IF ROOT
if [ "$(id -u)" -eq '0' ] && [ -z "${LOGOS_FORCE_ROOT}" ]; then
	echo "* Running Wine/winetricks as root is highly discouraged. Use -f|--force-root if you must run as root. See https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.3F"
	gtk_fatal_error "Running Wine/winetricks as root is highly discouraged. Use -f|--force-root if you must run as root. See https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.3F"
	exit 1;
fi
# END DIE IF ROOT

# BEGIN FUNCTION DECLARATIONS
debug() {
	[[ $DEBUG = true ]] && return 0 || return 1
}

die() { echo >&2 "$*"; exit 1; };

have_dep() {
	command -v "$1" >/dev/null 2>&1
}

clean_all() {
	echo "Cleaning all temp files…"
	rm -rf "${WORKDIR}"
	echo "done"
}

light_wineserver_wait() {
	echo "* Waiting for ${WINE_EXE} to end properly…"
	wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to end properly…" --pulsate --auto-close --no-cancel
}

heavy_wineserver_wait() {
	echo "* Waiting for ${WINE_EXE} to end properly…"
	wait_process_using_dir "${WINEPREFIX}" | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to end properly…" --pulsate --auto-close --no-cancel
	wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to end properly…" --pulsate --auto-close --no-cancel
}

## BEGIN ZENITY FUNCTIONS
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
	zenity --progress --title "Downloading ${FILENAME}…" --text="Downloading: ${FILENAME}\ninto: ${2}\n" --percentage=0 --auto-close < "${pipe_progress}" &
	ZENITY_PID="${!}"

	# download the file with wget:
	wget -c "$1" -O "${TARGET}" > "${pipe_wget}" 2>&1 &
	WGET_PID="${!}"

	# process the dialog progress bar
	total_size="Starting…"
	percent="0"
	current="Starting…"
	speed="Starting…"
	remain="Starting…"
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
## END ZENITY FUNCTIONS
# wait on all processes that are using the ${1} directory to finish
wait_process_using_dir() {
	VERIFICATION_DIR="${1}"
	VERIFICATION_TIME=7
	VERIFICATION_NUM=3

	echo "---------------------"
	echo "* Starting wait_process_using_dir…"
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

create_starting_scripts() {
# ${1} - WINE_BITS: 32 or 64
# ${2} - WINE_EXE name: wine or wine64
	export WINE_BITS="${1}"
	export WINE_EXE="${2}"

## BEGIN CREATE MAIN LAUNCHER
	echo "Creating starting scripts for ${FLPRODUCT}Bible ${WINE_BITS}bits…"
	cat > "${WORKDIR}"/"${FLPRODUCT}".sh << EOF
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
		echo "======= Running indexing on the ${FLPRODUCT} inside this installation only: ======="
		LOGOS_INDEXER_EXE=\$(find "\${WINEPREFIX}" -name ${FLPRODUCT}Indexer.exe |  grep "${FLPRODUCT}\/System\/${FLPRODUCT}Indexer.exe")
		if [ -z "\${LOGOS_INDEXER_EXE}" ] ; then
			echo "* ERROR: the ${FLPRODUCT}Indexer.exe can't be found!!!"
			exit 1
		fi
		echo "* Closing anything running in this wine bottle:"
		wineserver -k
		echo "* Running the indexer:"
		${WINE_EXE} "\${LOGOS_INDEXER_EXE}"
		wineserver -w
		echo "======= indexing of ${FLPRODUCT}Bible run done! ======="
		exit 0
		;;
	"removeAllIndex")
		echo "======= removing all ${FLPRODUCT}Bible BibleIndex, LibraryIndex, PersonalBookIndex, and LibraryCatalog files: ======="
		LOGOS_EXE="\$(find "\${WINEPREFIX}" -name ${FLPRODUCT}.exe | grep "${FLPRODUCT}\/${FLPRODUCT}.exe")"
		LOGOS_DIR="\$(dirname "\${LOGOS_EXE}")"
		rm -fv "\${LOGOS_DIR}"/Data/*/BibleIndex/*
		rm -fv "\${LOGOS_DIR}"/Data/*/LibraryIndex/*
		rm -fv "\${LOGOS_DIR}"/Data/*/PersonalBookIndex/*
		rm -fv "\${LOGOS_DIR}"/Data/*/LibraryCatalog/*
		echo "======= removing all ${FLPRODUCT}Bible index files done! ======="
		exit 0
		;;
	"removeLibraryCatalog")
		echo "======= removing ${FLPRODUCT}Bible LibraryCatalog files only: ======="
		LOGOS_EXE="\$(find "\${WINEPREFIX}" -name ${FLPRODUCT}.exe | grep "${FLPRODUCT}\/${FLPRODUCT}.exe")"
		LOGOS_DIR="\$(dirname "\${LOGOS_EXE}")"
		rm -fv "\${LOGOS_DIR}"/Data/*/LibraryCatalog/*
		echo "======= removing all ${FLPRODUCT}Bible index files done! ======="
		exit 0
		;;
	"logsOn")
		echo "======= enable ${FLPRODUCT}Bible logging only: ======="
		${WINE_EXE} reg add "HKCU\\\\Software\\\\Logos4\\\\Logging" /v Enabled /t REG_DWORD /d 0001 /f
		wineserver -w
		echo "======= enable ${FLPRODUCT}Bible logging done! ======="
		exit 0
		;;
	"logsOff")
		echo "======= disable ${FLPRODUCT}Bible logging only: ======="
		${WINE_EXE} reg add "HKCU\\\\Software\\\\Logos4\\\\Logging" /v Enabled /t REG_DWORD /d 0000 /f
		wineserver -w
		echo "======= disable ${FLPRODUCT}Bible logging done! ======="
		exit 0
		;;
	"dirlink")
		echo "======= making ${FLPRODUCT}Bible dir link only: ======="
		LOGOS_EXE="\$(find "\${WINEPREFIX}" -name ${FLPRODUCT}.exe | grep "${FLPRODUCT}\/${FLPRODUCT}.exe")"
		LOGOS_DIR="\$(dirname "\${LOGOS_EXE}")"
		LOGOS_DIR_RELATIVE="\$(realpath --relative-to="\${HERE}" "\${LOGOS_DIR}")"
		rm -f "\${HERE}/installation_dir"
		ln -s "\${LOGOS_DIR_RELATIVE}" "\${HERE}/installation_dir"
		echo "dirlink created at: \${HERE}/installation_dir"
		echo "======= making ${FLPRODUCT}Bible dir link done! ======="
		exit 0
		;;
	"shortcut")
		echo "======= making new ${FLPRODUCT}Bible shortcut only: ======="
		[ ! -f "\${HERE}/data/\${LOGOS_ICON_FILENAME}" ] && wget -c "\${LOGOS_ICON_URL}" -P "\${HERE}/data"
		mkdir -p "\${HOME}/.local/share/applications"
		rm -rf "\${HOME}/.local/share/applications/${FLPRODUCT}Bible.desktop"
		echo "[Desktop Entry]" > "\${HERE}"/${FLPRODUCT}Bible.desktop
		echo "Name=${FLPRODUCT}Bible" >> "\${HERE}"/${FLPRODUCT}Bible.desktop
		echo "Comment=A Bible Study Library with Built-In Tools" >> "\${HERE}"/${FLPRODUCT}Bible.desktop
		echo "Exec=\${HERE}/${FLPRODUCT}.sh" >> "\${HERE}"/${FLPRODUCT}Bible.desktop
		echo "Icon=\${HERE}/data/${FLPRODUCTi}-128-icon.png" >> "\${HERE}"/${FLPRODUCT}Bible.desktop
		echo "Terminal=false" >> "\${HERE}"/${FLPRODUCT}Bible.desktop
		echo "Type=Application" >> "\${HERE}"/${FLPRODUCT}Bible.desktop
		echo "Categories=Education;" >> "\${HERE}"/${FLPRODUCT}Bible.desktop
		chmod +x "\${HERE}"/${FLPRODUCT}Bible.desktop
		mv "\${HERE}"/${FLPRODUCT}Bible.desktop "\${HOME}/.local/share/applications"
		echo "File: \${HOME}/.local/share/applications/${FLPRODUCT}Bible.desktop updated"
		echo "======= making new ${FLPRODUCT}Bible.desktop shortcut done! ======="
		exit 0
		;;
	*)
		echo "No arguments parsed."
esac

LOGOS_EXE=\$(find "\${WINEPREFIX}" -name ${FLPRODUCT}.exe | grep "${FLPRODUCT}\/${FLPRODUCT}.exe")
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
	chmod +x "${WORKDIR}"/"${FLPRODUCT}".sh
	mv "${WORKDIR}"/"${FLPRODUCT}".sh "${INSTALLDIR}"/
## END CREATE MAIN LAUNCHER

## BEGIN CREATE CONTROLPANEL.SH
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
			echo "No *.AppImage file selected! exiting…"
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
				(DISPLAY="" "\${HERE}/controlPanel.sh" ${WINE_EXE} wineboot) | zenity --progress --title="Wine Bottle update" --text="Updating Wine Bottle…" --pulsate --auto-close --no-cancel
				echo "======= AppImage Selection run done with external link! ======="
				exit 0
			fi
		fi

		echo "Info: Linking ../\${APPIMAGE_FILENAME} to ./data/bin/\${APPIMAGE_LINK_SELECTION_NAME}"
		chmod +x "\${APPIMAGE_FULLPATH}"
		ln -s "../\${APPIMAGE_FILENAME}" "\${APPIMAGE_LINK_SELECTION_NAME}"
		rm -rf "\${HERE}/data/bin/\${APPIMAGE_LINK_SELECTION_NAME}"
		mv "\${APPIMAGE_LINK_SELECTION_NAME}" "\${HERE}/data/bin/"
		(DISPLAY="" "\${HERE}/controlPanel.sh" ${WINE_EXE} wineboot) | zenity --progress --title="Wine Bottle update" --text="Updating Wine Bottle…" --pulsate --auto-close --no-cancel
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
	chmod +x "${WORKDIR}"/controlPanel.sh
	mv "${WORKDIR}"/controlPanel.sh "${INSTALLDIR}"/
## END CREATE CONTROLPANEL.SH
}


make_skel() {
# ${1} - WINE_BITS: 32 or 64
# ${2} - WINE_EXE name: wine or wine64
# ${3} - SET_APPIMAGE_FILENAME
	export WINE_BITS="${1}"
	export WINE_EXE="${2}"
	export SET_APPIMAGE_FILENAME="${3}"

	echo "* Making skel${WINE_BITS} inside ${INSTALLDIR}"
	mkdir -p "${INSTALLDIR}"
	mkdir "${APPDIR}" || die "can't make dir: ${APPDIR}"
	mkdir "${APPDIR_BINDIR}" || die "can't make dir: ${APPDIR_BINDIR}"

	# Making the links
	cd "${APPDIR_BINDIR}" || die "ERROR: Can't open dir: ${APPDIR_BINDIR}"
	ln -s "../${SET_APPIMAGE_FILENAME}" "${APPIMAGE_LINK_SELECTION_NAME}"
	ln -s "${APPIMAGE_LINK_SELECTION_NAME}" wine
	[ "${WINE_BITS}" == "64" ] && ln -s "${APPIMAGE_LINK_SELECTION_NAME}" wine64
	ln -s "${APPIMAGE_LINK_SELECTION_NAME}" wineserver
	cd - || die "ERROR: Can't go back to preview dir!"

	mkdir "${APPDIR}/wine${WINE_BITS}_bottle"
	
	create_starting_scripts "${WINE_BITS}" "${WINE_EXE}"

	echo "skel${WINE_BITS} done!"
}

# TODO: Move this to a CLI optarg.

#	#======= Parsing =============
#	case "${1}" in
#		"skel64")
#			export WINE_EXE="wine64"
#			make_skel "64" "${WINE_EXE}" "none.AppImage"
#			rm -rf "${WORKDIR}"
#			exit 0
#			echo "================================================="
#			;;
#		*)
#			echo "No arguments parsed."
#			echo "================================================="
#	esac

## BEGIN CHECK DEPENDENCIES FUNCTIONS
check_commands() {
    for cmd in "$@"; do
        if have_dep "${cmd}"; then
            echo "* command ${cmd} is installed!"
        else
            echo "* Your system does not have the command: ${cmd}. Please install command    ${cmd} package. ${EXTRA_INFO}"
            gtk_fatal_error "Your system does not have command: ${cmd}. Please install       command ${cmd} package.\n ${EXTRA_INFO}"
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
            echo "* Your system does not have the lib: ${lib}. Please install ${lib}         package. ${EXTRA_INFO}"
            gtk_fatal_error "Your system does not have lib: ${lib}. Please install ${lib}    package.\n ${EXTRA_INFO}"
        fi
    done
}

checkDependenciesXBase() {
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
}

checkDependenciesLogos10() {
	echo "Checking dependencies for Logos 10."
	check_commands mktemp patch lsof wget find sed grep ntlm_auth;
	echo "All dependencies found. Starting Zenity GUI…"
}

checkDependenciesLogos9() {
	echo "Checking dependencies for Logos 9."
	check_commands mktemp patch lsof wget xwd find sed grep cabextract ntlm_auth;
	echo "All dependencies found. Starting Zenity GUI…"
}
## END CHECK DEPENDENCIES FUNCTIONS

## BEGIN INSTALL OPTIONS FUNCTIONS
chooseProduct() {
	productChoice="$(zenity --width=700 --height=310 \
		--title="Question: Should the script install Logos or Verbum?" \
		--text="Choose which FaithLife product to install:." \
		--list --radiolist --column "S" --column "Description" \
		TRUE "Logos Bible Software." \
		FALSE "Verbum Bible Software." \
		FALSE "Exit." )"

	case "${productChoice}" in
		"Logos"*)
			echo "Installing Logos Bible Software"
			export FLPRODUCT="Logos"
			export FLPRODUCTi="logos4" #This is the variable referencing the icon path name in the repo.
			;;
		"Verbum"*)
			echo "Installing Verbum Bible Software"
			export FLPRODUCT="Verbum"
			export FLPRODUCTi="verbum" #This is the variable referencing the icon path name in the repo.
			;;
		"Exit"*)
			exit
			;;
		*)
			gtk_fatal_error "Installation canceled!"
	esac

	if [ -z "${LOGOS_ICON_URL}" ]; then export LOGOS_ICON_URL="https://raw.githubusercontent.com/ferion11/LogosLinuxInstaller/master/img/${FLPRODUCTi}-128-icon.png" ; fi
}

chooseVersion() {
	versionChoice="$(zenity --width=700 --height=310 \
		--title="Question: Which version of ${FLPRODUCT} should the script install?" \
		--text="Choose which FaithLife product to install:." \
		--list --radiolist --column "S" --column "Description" \
		TRUE "${FLPRODUCT} 10" \
		FALSE "${FLPRODUCT} 9" \
		FALSE "Exit." )"
	case "${versionChoice}" in
		*10)
			checkDependenciesLogos10;
			export TARGETVERSION="10";
			if [ -z "${LOGOS64_URL}" ]; then export LOGOS64_URL="https://downloads.logoscdn.com/LBS10/Installer/10.1.0.0046/${FLPRODUCT}-x64.msi" ; fi
			LOGOS_VERSION="$(echo "${LOGOS64_URL}" | cut -d/ -f6)"; export LOGOS_VERSION
			LOGOS64_MSI="$(basename "${LOGOS64_URL}")"; export LOGOS64_MSI
			;;
		*9)
			checkDependenciesLogos9;
			export TARGETVERSION="9";
			if [ -z "${LOGOS64_URL}" ]; then export LOGOS64_URL="https://downloads.logoscdn.com/LBS9/Installer/9.17.0.0010/${FLPRODUCT}-x64.msi" ; fi
			LOGOS_VERSION="$(echo "${LOGOS64_URL}" | cut -d/ -f6)"; export LOGOS_VERSION
			LOGOS64_MSI="$(basename "${LOGOS64_URL}")"; export LOGOS64_MSI
			;;
		3*)
			exit
			;;
		*)
			gtk_fatal_error "Installation canceled!"
	esac
	if [ -z "${INSTALLDIR}" ]; then export INSTALLDIR="${HOME}/${FLPRODUCT}Bible${TARGETVERSION}" ; fi
	export APPDIR="${INSTALLDIR}/data"
	export APPDIR_BINDIR="${APPDIR}/bin"

	if [ -d "${INSTALLDIR}" ]; then
		echo "A directory already exists at ${INSTALLDIR}. Please remove/rename it or use another location by setting the INSTALLDIR variable"
		gtk_fatal_error "a directory already exists at ${INSTALLDIR}. Please remove/rename it or use another location by setting the INSTALLDIR variable"
	fi              
}

chooseInstallMethod() {
	if [ "${TARGETVERSION}" == "10" ]; then
		installationChoice="$(zenity --width=700 --height=310 \
			--title="Question: Install ${FLPRODUCT} Bible using script ${LOGOS_SCRIPT_VERSION}" \
			--text="This script will create one directory in (which can be changed by setting the INSTALLDIR variable):\n\"${INSTALLDIR}\"\nto be an installation of ${FLPRODUCT}Bible v${LOGOS_VERSION} independent of other installations.\nPlease select the type of installation:" \
			--list --radiolist --column "S" --column "Description" \
			TRUE "Native Wine: Install ${FLPRODUCT} Bible ${TARGETVERSION} using native Wine64. WINE must be 7.18-staging or later. Stable or Devel do not work." \
			FALSE "AppImage: Install ${FLPRODUCT} Bible ${TARGETVERSION} using Wine64 ${WINE64_APPIMAGE_FULL_VERSION} AppImage." )"

		case "${installationChoice}" in
			"Native Wine:"*)
				echo "Installing ${FLPRODUCT} Bible ${TARGETVERSION} using the native Wine…"
				export WINEARCH=win64
				export WINEPREFIX="${APPDIR}/wine64_bottle"
				export WINE_EXE="wine64"

				# check for wine installation
				WINE_VERSION_CHECK="$(${WINE_EXE} --version)"
				[ -z "${WINE_VERSION_CHECK}" ] && gtk_fatal_error "Wine64 not found! Please install native Wine64 first."
				echo "Using: ${WINE_VERSION_CHECK}"

				make_skel "64" "${WINE_EXE}" "none.AppImage"
				;;
			"AppImage:"*)
				echo "Installing ${FLPRODUCT} Bible ${TARGETVERSION} using ${WINE64_APPIMAGE_FULL_VERSION} AppImage…"
				export WINEARCH=win64
				export WINEPREFIX="${APPDIR}/wine64_bottle"
				export WINE_EXE="wine64"

				make_skel "64" "${WINE_EXE}" "${WINE64_APPIMAGE_FULL_FILENAME}"

				# exporting PATH to internal use if using AppImage, doing backup too:
				export OLD_PATH="${PATH}"
				export PATH="${APPDIR_BINDIR}":"${PATH}"

				# Geting the AppImage:
				if [ -f "${PRESENT_WORKING_DIRECTORY}/${WINE64_APPIMAGE_FULL_FILENAME}" ]; then
					echo "${WINE64_APPIMAGE_FULL_FILENAME} exists. Using it…"
					cp "${PRESENT_WORKING_DIRECTORY}/${WINE64_APPIMAGE_FULL_FILENAME}" "${APPDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${WINE64_APPIMAGE_FULL_FILENAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
				elif [ -f "${HOME}/Downloads/${WINE64_APPIMAGE_FULL_FILENAME}" ]; then
					echo "${WINE64_APPIMAGE_FULL_FILENAME} exists. Using it…"
					cp "${HOME}/Downloads/${WINE64_APPIMAGE_FULL_FILENAME}" "${APPDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${WINE64_APPIMAGE_FULL_FILENAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
				else
					echo "${WINE64_APPIMAGE_FULL_FILENAME} does not exist. Downloading…"
					gtk_download "${WINE64_APPIMAGE_FULL_URL}" "${HOME}/Downloads/${WINE64_APPIMAGE_FULL_FILENAME}"
					cp "${PRESENT_WORKING_DIRECTORY}/${WINE64_APPIMAGE_FULL_FILENAME}" "${APPDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${WINE64_APPIMAGE_FULL_FILENAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
					mv "${WORKDIR}/${WINE64_APPIMAGE_FULL_FILENAME}" "${APPDIR}" | zenity --progress --title="Moving…" --text="Moving: ${WINE64_APPIMAGE_FULL_FILENAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
				fi

				chmod +x "${APPDIR}/${WINE64_APPIMAGE_FULL_FILENAME}"
				echo "Using: $(${WINE_EXE} --version)"
				echo "================================================="
				;;
			*)
				gtk_fatal_error "Installation canceled!"
		esac

	elif [ "${TARGETVERSION}" == "9" ]; then
		installationChoice="$(zenity --width=700 --height=310 \
			--title="Question: Install ${FLPRODUCT} Bible using script ${LOGOS_SCRIPT_VERSION}" \
			--text="This script will create one directory in (which can be changed by setting the INSTALLDIR variable):\n\"${INSTALLDIR}\"\nto be an installation of ${FLPRODUCT}Bible v${LOGOS_VERSION} independent of other installations.\nPlease select the type of installation:" \
			--list --radiolist --column "S" --column "Description" \
			TRUE "Native Wine: Fast install ${FLPRODUCT}Bible64 using the native Wine64 (default)." \
			FALSE "AppImage: Fast install ${FLPRODUCT}Bible64 using Wine64 ${WINE64_APPIMAGE_FULL_VERSION} AppImage." )"
			# FALSE "3- Fast install ${FLPRODUCT}Bible64 using Wine64 ${WINE64_APPIMAGE_VERSION} plain AppImage without dependencies."

		case "${installationChoice}" in
			"Native Wine:"*)
				echo "Installing ${FLPRODUCT} Bible ${TARGETVERSION} using the native Wine…"
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
			"AppImage"*)
				echo "Installing ${FLPRODUCT} Bible ${TARGETVERSION} using ${WINE64_APPIMAGE_FULL_VERSION} AppImage…"
				export WINEARCH=win64
				export WINEPREFIX="${APPDIR}/wine64_bottle"
				export WINE_EXE="wine64"

				make_skel "64" "${WINE_EXE}" "${WINE64_APPIMAGE_FULL_FILENAME}"
				export SET_APPIMAGE_FILENAME="${WINE64_APPIMAGE_FULL_FILENAME}"
				export SET_APPIMAGE_URL="${WINE64_APPIMAGE_FULL_URL}"
				;;
			3*)
				echo "Installing ${FLPRODUCT} Bible ${TARGETVERSION} using ${WINE64_APPIMAGE_VERSION} plain AppImage without dependencies…"
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
			# Geting the AppImage:
			if [ -f "${PRESENT_WORKING_DIRECTORY}/${SET_APPIMAGE_FILENAME}" ]; then
				echo "${SET_APPIMAGE_FILENAME} exist. Using it…"
				cp "${PRESENT_WORKING_DIRECTORY}/${SET_APPIMAGE_FILENAME}" "${APPDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${SET_APPIMAGE_FILENAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
			else
				echo "${SET_APPIMAGE_FILENAME} does not exist. Downloading…"
				gtk_download "${SET_APPIMAGE_URL}" "${WORKDIR}"

				mv "${WORKDIR}/${SET_APPIMAGE_FILENAME}" "${APPDIR}" | zenity --progress --title="Moving…" --text="Moving: ${SET_APPIMAGE_FILENAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
			fi

			chmod +x "${APPDIR}/${SET_APPIMAGE_FILENAME}"
			echo "Using: $(${WINE_EXE} --version)"
			echo "================================================="
		fi
	else
		echo "TARGETVERSION not set."
		exit 1;
	fi
}
## END INSTALL OPTIONS FUNCTIONS
## BEGIN WINE BOTTLE AND WINETRICKS FUNCTIONS
prepareWineBottle() {
	gtk_continue_question "Now the script will create and configure the Wine Bottle at ${WINEPREFIX}. You can cancel the instalation of Mono. Do you wish to continue?"
	echo "${WINE_EXE} wineboot"
	if [ -z "${WINEBOOT_GUI}" ]; then
		(DISPLAY="" ${WINE_EXE} wineboot) | zenity --progress --title="Waiting ${WINE_EXE} wineboot" --text="Waiting for ${WINE_EXE} wineboot…" --pulsate --auto-close --no-cancel
	else
		${WINE_EXE} wineboot
	fi
	light_wineserver_wait
}

wine_reg_install() {
	REG_FILENAME="${1}"
	echo "${WINE_EXE} regedit.exe ${REG_FILENAME}"
	${WINE_EXE} regedit.exe "${WORKDIR}"/"${REG_FILENAME}" | zenity --progress --title="Wine regedit" --text="Wine is installing ${REG_FILENAME} in ${WINEPREFIX}" --pulsate --auto-close --no-cancel

	light_wineserver_wait
	echo "${WINE_EXE} regedit.exe ${REG_FILENAME} DONE!"
}

downloadWinetricks() {
	echo "Downloading winetricks from the Internet…"
	if [ -f "${PRESENT_WORKING_DIRECTORY}/winetricks" ]; then
		echo "A winetricks binary has already been downloaded. Using it…"
		cp "${PRESENT_WORKING_DIRECTORY}/winetricks" "${WORKDIR}"
	else
		echo "winetricks does not exist. Downloading…"
		gtk_download "${WINETRICKS_URL}" "${WORKDIR}"
	fi
	chmod +x "${WORKDIR}/winetricks"
}

setWinetricks() {
	# TODO: Do not ask if winetricks version is older than 20220411; in that case, default to an internet install.
	if [ "$(which winetricks)" ]; then
		winetricksChoice="$(zenity --width=700 --height=310 \
		--title="Question: Should the script use local winetricks or download winetricks fresh?" \
		--text="This script needs to set some Wine options that help or make ${FLPRODUCT} run on Linux. Please select whether to use your local winetricks version or a fresh install." \
		--list --radiolist --column "S" --column "Description" \
		TRUE "1- Use local winetricks." \
		FALSE "2- Download winetricks from the Internet." )"

		case "${winetricksChoice}" in
			1*)
				echo "Setting winetricks to the local binary…"
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
}

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

getPremadeWineBottle() {
	# get and install pre-made wineBottle
	WINE64_BOTTLE_TARGZ_URL="https://github.com/ferion11/wine64_bottle_dotnet/releases/download/v5.11b/wine64_bottle.tar.gz"
	WINE64_BOTTLE_TARGZ_NAME="wine64_bottle.tar.gz"
	echo "Installing pre-made wineBottle 64bits…"
	if [ -f "${PRESENT_WORKING_DIRECTORY}/${WINE64_BOTTLE_TARGZ_NAME}" ]; then
		echo "${WINE64_BOTTLE_TARGZ_NAME} exist. Using it…"
		cp "${PRESENT_WORKING_DIRECTORY}/${WINE64_BOTTLE_TARGZ_NAME}" "${WORKDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${WINE64_BOTTLE_TARGZ_NAME}\ninto: ${WORKDIR}" --pulsate --auto-close --no-cancel
	else
		echo "${WINE64_BOTTLE_TARGZ_NAME} does not exist. Downloading…"
		gtk_download "${WINE64_BOTTLE_TARGZ_URL}" "${WORKDIR}"
	fi

	echo "Extracting: ${WINE64_BOTTLE_TARGZ_NAME} into: ${APPDIR}"
	tar xzf "${WORKDIR}"/"${WINE64_BOTTLE_TARGZ_NAME}" -C "${APPDIR}"/ | zenity --progress --title="Extracting…" --text="Extracting: ${WINE64_BOTTLE_TARGZ_NAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
	echo "================================================="
}
## END WINE BOTTLE AND WINETRICKS FUNCTIONS
## BEGIN LOGOS INSTALL FUNCTIONS
getLogosExecutable() {
	gtk_continue_question "Now the script will download and install ${FLPRODUCT} Bible at ${WINEPREFIX}. You will need to interact with the installer. Do you wish to continue?"

	echo "================================================="
	# Geting and install ${FLPRODUCT}Bible:
	echo "Installing ${FLPRODUCT}Bible 64bits…"
	if [ -f "${PRESENT_WORKING_DIRECTORY}/${LOGOS64_MSI}" ]; then
		echo "${LOGOS64_MSI} exists. Using it…"
		cp "${PRESENT_WORKING_DIRECTORY}/${LOGOS64_MSI}" "${WORKDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${LOGOS64_MSI}\ninto: ${WORKDIR}" --pulsate --auto-close --no-cancel
	elif [ -f "${HOME}/Downloads/${LOGOS64_MSI}" ]; then
		echo "${LOGOS64_MSI} exists. Using it…"
		cp "${HOME}/Downloads/${LOGOS64_MSI}" "${WORKDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${LOGOS64_MSI}\ninto: ${WORKDIR}" --pulsate --auto-close --no-cancel
	else
		echo "${LOGOS64_MSI} does not exist. Downloading…"
		gtk_download "${LOGOS64_URL}" "${HOME}/Downloads/${LOGOS64_MSI}"
		cp "${HOME}/Downloads/${LOGOS64_MSI}" "${WORKDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${LOGOS64_MSI}\ninto: ${WORKDIR}" --pulsate --auto-close --no-cancel
	fi
}

installMSI() {
	echo "Running: ${WINE_EXE} msiexec /i ${WORKDIR}/${LOGOS64_MSI}"
	${WINE_EXE} msiexec /i "${WORKDIR}"/"${LOGOS64_MSI}"
}

installLogos9() {	
	getPremadeWineBottle;

	getLogosExecutable;

	installMSI;

	echo "======= Set ${FLPRODUCT}Bible Indexing to Vista Mode: ======="
	${WINE_EXE} reg add "HKCU\\Software\\Wine\\AppDefaults\\${FLPRODUCT}Indexer.exe" /v Version /t REG_SZ /d vista /f
	echo "======= ${FLPRODUCT}Bible logging set to Vista mode! ======="
}

installLogos10() {
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

	wine_reg_install "disable-winemenubuilder.reg";
	wine_reg_install "renderer_gdi.reg";

	setWinetricks;

	if [ -z "${WINETRICKS_UNATTENDED}" ]; then
		winetricks_install -q corefonts
		winetricks_install -q tahoma
		winetricks_install -q settings fontsmooth=rgb
		winetricks_install -q settings win10
		winetricks_dll_install -q d3dcompiler_47;
	else
		winetricks_install corefonts
		winetricks_install tahoma
		winetricks_install settings fontsmooth=rgb
		winetricks_install settings win10
		winetricks_dll_install d3dcompiler_47
	fi

	getLogosExecutable;

	installMSI;
}
## END LOGOS INSTALL FUNCTIONS
# END FUNCTION DECLARATIONS

main () {
	echo "$LOGOS_SCRIPT_TITLE, $LOGOS_SCRIPT_VERSION by $LOGOS_SCRIPT_AUTHOR."
	debug && echo "Debug mode enabled."

	# BEGIN PREPARATION
	checkDependenciesXBase; # We verify the user is running a graphical UI.
	chooseProduct; # We ask user for his Faithlife product's name and set variables.
	chooseVersion; # We ask user for his Faithlife product's version and set variables.
	chooseInstallMethod; # We ask user for his desired install method and begin installation.
	prepareWineBottle; # We run wineboot.
	# END PREPARATION

	# BEGIN INSTALL
	case "${TARGETVERSION}" in
		10*)
				installLogos10; ;; # We run the commands specific to Logos 10.
		9*)
				installLogos9; ;; # We run the commands specific to Logos 9.
		*)
				gtk_fatal_error "Installation canceled!"
				exit 0; ;;
	esac

	heavy_wineserver_wait;
	clean_all;

	LOGOS_EXE=$(find "${WINEPREFIX}" -name ${FLPRODUCT}.exe | grep "${FLPRODUCT}/${FLPRODUCT}.exe")

	if [ -f "${LOGOS_EXE}" ]; then
		if gtk_question "${FLPRODUCT} Bible ${TARGETVERSION} installed!\n\nA launch script has been placed in ${INSTALLDIR}for your use. The script's name is ${FLPRODUCT}.sh.\n\nDo you want to run it now?\n\nNOTE: There may be an error on first execution. You can close the error dialog."; then
			"${INSTALLDIR}"/"${FLPRODUCT}".sh
		else echo "The script has finished. Exiting…";
		fi
	else
		gtk_fatal_error "The ${FLPRODUCT} executable was not found. This means something went wrong while installing ${FLPRODUCT}. Please contact the Logos on Linux community for help."
		echo "Installation failed. Exiting…"
		exit 1;
	fi
	# END INSTALL
	
	exit 0;
}

main;

