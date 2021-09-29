#!/bin/bash
# From https://github.com/ferion11/LogosLinuxInstaller
export THIS_SCRIPT_VERSION="fast-v2.34"

#=================================================
# version of Logos from: https://wiki.logos.com/The_Logos_9_Beta_Program
if [ -z "${VERBUM64_URL}" ]; then export VERBUM64_URL="https://downloads.logoscdn.com/LBS9/Verbum/Installer/9.8.0.0004/Verbum-x64.msi" ; fi

#VERBUM_MVERSION=$(echo "${VERBUM64_URL}" | cut -d/ -f4); export VERBUM_MVERSION
VERBUM_VERSION="$(echo "${VERBUM64_URL}" | cut -d/ -f6)"; export VERBUM_VERSION
VERBUM64_MSI="$(basename "${VERBUM64_URL}")"; export VERBUM64_MSI
#=================================================
if [ -z "${VERBUM_ICON_URL}" ]; then export VERBUM_ICON_URL="https://github.com/jg00dman/LogosLinuxInstaller/raw/master/img/verbum-128-icon.png" ; fi
#=================================================
# Default AppImage FULL (with deps) to install 64bits version:
export WINE64_APPIMAGE_FULL_VERSION="v6.5"
if [ -z "${WINE64_APPIMAGE_FULL_URL}" ]; then export WINE64_APPIMAGE_FULL_URL="https://github.com/ferion11/wine_WoW64_fulldeps_AppImage/releases/download/test-beta3/wine-staging-linux-amd64-fulldeps-v6.5-f11-x86_64.AppImage" ; fi
WINE64_APPIMAGE_FULL_FILENAME="$(basename "${WINE64_APPIMAGE_FULL_URL}")"; export WINE64_APPIMAGE_FULL_FILENAME
#=================================================
# Default AppImage (without deps) to install 64bits version:
export WINE64_APPIMAGE_VERSION="v6.5"
if [ -z "${WINE64_APPIMAGE_URL}" ]; then export WINE64_APPIMAGE_URL="https://github.com/ferion11/wine_WoW64_nodeps_AppImage/releases/download/continuous-logos/wine-staging-linux-amd64-nodeps-v6.5-f11-x86_64.AppImage" ; fi
WINE64_APPIMAGE_FILENAME="$(basename "${WINE64_APPIMAGE_URL}")"; export WINE64_APPIMAGE_FILENAME
#=================================================
if [ -z "${WORKDIR}" ]; then WORKDIR="$(mktemp -d)"; export WORKDIR ; fi
if [ -z "${INSTALLDIR}" ]; then export INSTALLDIR="${HOME}/VerbumBible_Linux_P" ; fi
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
	# NOTE: here must be limitation to handle it easily. $2 can be dir, if it already exists or if it ends with '/'

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

# wait to all process that is using the ${1} directory to finish
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

	echo "Creating starting scripts for VerbumBible ${WINE_BITS}bits..."
	#------- Verbum.sh -------------
	cat > "${WORKDIR}"/Verbum.sh << EOF
#!/bin/bash
# generated by "${THIS_SCRIPT_VERSION}" script from https://github.com/ferion11/LogosLinuxInstaller

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
[ -z "\${VERBUM_ICON_URL}" ] && export VERBUM_ICON_URL="${VERBUM_ICON_URL}"
VERBUM_ICON_FILENAME="\$(basename "\${VERBUM_ICON_URL}")"; export VERBUM_ICON_FILENAME
#-------------------------------------------------

#-------------------------------------------------
case "\${1}" in
	"${WINE_EXE}"|"wineserver"|"winetricks"|"selectAppImage")
		"\${HERE}/controlPanel.sh" "\$@"
		exit 0
		;;
	"indexing")
		# Indexing Run:
		echo "======= Running indexing on the Verbum inside this installation only: ======="
		VERBUM_INDEXER_EXE=\$(find "\${WINEPREFIX}" -name VerbumIndexer.exe |  grep "Verbum\/System\/VerbumIndexer.exe")
		if [ -z "\${VERBUM_INDEXER_EXE}" ] ; then
			echo "* ERROR: the VerbumIndexer.exe can't be found!!!"
			exit 1
		fi
		echo "* Closing anything running in this wine bottle:"
		wineserver -k
		echo "* Running the indexer:"
		${WINE_EXE} "\${VERBUM_INDEXER_EXE}"
		wineserver -w
		echo "======= indexing of VerbumBible run done! ======="
		exit 0
		;;
	"removeAllIndex")
		echo "======= removing all VerbumBible index files only: ======="
		VERBUM_EXE="\$(find "\${WINEPREFIX}" -name Verbum.exe | grep "Verbum\/Verbum.exe")"
		VERBUM_DIR="\$(dirname "\${VERBUM_EXE}")"
		rm -fv "\${VERBUM_DIR}"/Data/*/BibleIndex/*
		rm -fv "\${VERBUM_DIR}"/Data/*/LibraryIndex/*
		rm -fv "\${VERBUM_DIR}"/Data/*/PersonalBookIndex/*
		rm -fv "\${VERBUM_DIR}"/Data/*/LibraryCatalog/*
		echo "======= removing all VerbumBible index files done! ======="
		exit 0
		;;
	"logsOn")
		echo "======= enable VerbumBible logging only: ======="
		${WINE_EXE} reg add "HKCU\\\\Software\\\\Logos4\\\\Logging" /v Enabled /t REG_DWORD /d 0001 /f
		wineserver -w
		echo "======= enable VerbumBible logging done! ======="
		exit 0
		;;
	"logsOff")
		echo "======= disable VerbumBible logging only: ======="
		${WINE_EXE} reg add "HKCU\\\\Software\\\\Logos4\\\\Logging" /v Enabled /t REG_DWORD /d 0000 /f
		wineserver -w
		echo "======= disable VerbumBible logging done! ======="
		exit 0
		;;
	"dirlink")
		echo "======= making VerbumBible dir link only: ======="
		VERBUM_EXE="\$(find "\${WINEPREFIX}" -name Verbum.exe | grep "Verbum\/Verbum.exe")"
		VERBUM_DIR="\$(dirname "\${VERBUM_EXE}")"
		VERBUM_DIR_RELATIVE="\$(realpath --relative-to="\${HERE}" "\${VERBUM_DIR}")"
		rm -f "\${HERE}/installation_dir"
		ln -s "\${VERBUM_DIR_RELATIVE}" "\${HERE}/installation_dir"
		echo "dirlink created at: \${HERE}/installation_dir"
		echo "======= making VerbumBible dir link done! ======="
		exit 0
		;;
	"shortcut")
		echo "======= making new VerbumBible shortcut only: ======="
		[ ! -f "\${HERE}/data/\${VERBUM_ICON_FILENAME}" ] && wget -c "\${VERBUM_ICON_URL}" -P "\${HERE}/data"
		mkdir -p "\${HOME}/.local/share/applications"
		rm -rf "\${HOME}/.local/share/applications/VerbumBible.desktop"
		echo "[Desktop Entry]" > "\${HERE}"/VerbumBible.desktop
		echo "Name=VerbumBible" >> "\${HERE}"/VerbumBible.desktop
		echo "Comment=A Bible Study Library with Built-In Tools" >> "\${HERE}"/VerbumBible.desktop
		echo "Exec=\${HERE}/Verbum.sh" >> "\${HERE}"/VerbumBible.desktop
		echo "Icon=\${HERE}/data/verbum-128-icon.png" >> "\${HERE}"/VerbumBible.desktop
		echo "Terminal=false" >> "\${HERE}"/VerbumBible.desktop
		echo "Type=Application" >> "\${HERE}"/VerbumBible.desktop
		echo "Categories=Education;" >> "\${HERE}"/VerbumBible.desktop
		chmod +x "\${HERE}"/VerbumBible.desktop
		mv "\${HERE}"/VerbumBible.desktop "\${HOME}/.local/share/applications"
		echo "File: \${HOME}/.local/share/applications/VerbumBible.desktop updated"
		echo "======= making new VerbumBible.desktop shortcut done! ======="
		exit 0
		;;
	*)
		echo "No arguments parsed."
esac

VERBUM_EXE=\$(find "\${WINEPREFIX}" -name Verbum.exe | grep "Verbum\/Verbum.exe")
if [ -z "\${VERBUM_EXE}" ] ; then
	echo "======= Running control: ======="
	"\${HERE}/controlPanel.sh" "\$@"
	echo "======= control run done! ======="
	exit 0
fi

${WINE_EXE} "\${VERBUM_EXE}"
wineserver -w
#-------------------------------------------------

#------------- Ending block ----------------------
# restore IFS
IFS=\${IFS_TMP}
#-------------------------------------------------
EOF
	#------------------------------
	chmod +x "${WORKDIR}"/Verbum.sh
	mv "${WORKDIR}"/Verbum.sh "${INSTALLDIR}"/

	#------- controlPanel.sh ------
	cat > "${WORKDIR}"/controlPanel.sh << EOF
#!/bin/bash
# generated by "${THIS_SCRIPT_VERSION}" script from https://github.com/ferion11/VerbumLinuxInstaller

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

check_commands mktemp patch lsof wget xwd find sed grep cabextract ntlm_auth
#check_libs libjpeg.so.8

if [ "$(id -u)" = 0 ] && [ -z "${FORCE_ROOT}" ]; then
	echo "* Running Wine/winetricks as root is highly discouraged (you can set FORCE_ROOT=1). See https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.3F"
	gtk_fatal_error "Running Wine/winetricks as root is highly discouraged (you can set FORCE_ROOT=1). See https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.3F"
fi

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
	gtk_fatal_error "A directory already exists at ${INSTALLDIR}. Please remove/rename it or use another location by setting the INSTALLDIR variable"
fi

echo "* Script version: ${THIS_SCRIPT_VERSION}"
installationChoice="$(zenity --width=700 --height=310 \
	--title="Question: Install Verbum Bible using script ${THIS_SCRIPT_VERSION}" \
	--text="This script will create one directory in (which can be changed by setting the INSTALLDIR variable):\n\"${INSTALLDIR}\"\nto be an installation of VerbumBible v${VERBUM_VERSION} independent of other installations.\nPlease select the type of installation:" \
	--list --radiolist --column "S" --column "Description" \
	TRUE "1- Fast install VerbumBible64 using the native Wine64 (default)." \
	FALSE "2- Fast install VerbumBible64 using Wine64 ${WINE64_APPIMAGE_FULL_VERSION} AppImage." )"
# FALSE "3- Fast install VerbumBible64 using Wine64 ${WINE64_APPIMAGE_VERSION} plain AppImage without dependencies."

case "${installationChoice}" in
	1*)
		echo "Installing VerbumBible 64bits using the native Wine..."
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
		echo "Installing VerbumBible 64bits using ${WINE64_APPIMAGE_FULL_VERSION} AppImage..."
		export WINEARCH=win64
		export WINEPREFIX="${APPDIR}/wine64_bottle"
		export WINE_EXE="wine64"

		make_skel "64" "${WINE_EXE}" "${WINE64_APPIMAGE_FULL_FILENAME}"
		export SET_APPIMAGE_FILENAME="${WINE64_APPIMAGE_FULL_FILENAME}"
		export SET_APPIMAGE_URL="${WINE64_APPIMAGE_FULL_URL}"
		;;
	3*)
		echo "Installing VerbumBible 64bits using ${WINE64_APPIMAGE_VERSION} plain AppImage without dependencies..."
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

echo "================================================="
# get and install pre-made wineBottle
#WINE64_BOTTLE_TARGZ_URL="https://github.com/ferion11/wine64_bottle_dotnet/releases/download/v5.11/wine64_bottle.tar.gz"
WINE64_BOTTLE_TARGZ_URL="https://github.com/ferion11/wine64_bottle_dotnet/releases/download/v5.11b/wine64_bottle.tar.gz"
WINE64_BOTTLE_TARGZ_NAME="wine64_bottle.tar.gz"
echo "Installing pre-made wineBottle 64bits..."
if [ -f "${DOWNLOADED_RESOURCES}/${WINE64_BOTTLE_TARGZ_NAME}" ]; then
	echo "${WINE64_BOTTLE_TARGZ_NAME} exist. Using it..."
	cp "${DOWNLOADED_RESOURCES}/${WINE64_BOTTLE_TARGZ_NAME}" "${WORKDIR}/" | zenity --progress --title="Copying..." --text="Copying: ${WINE64_BOTTLE_TARGZ_NAME}\ninto: ${WORKDIR}" --pulsate --auto-close --no-cancel
else
	echo "${WINE64_BOTTLE_TARGZ_NAME} does not exist. Downloading..."
	gtk_download "${WINE64_BOTTLE_TARGZ_URL}" "${WORKDIR}"
fi

echo "Extracting: ${WINE64_BOTTLE_TARGZ_NAME} into: ${APPDIR}"
tar xzf "${WORKDIR}"/"${WINE64_BOTTLE_TARGZ_NAME}" -C "${APPDIR}"/ | zenity --progress --title="Extracting..." --text="Extracting: ${WINE64_BOTTLE_TARGZ_NAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
echo "================================================="

gtk_continue_question "Now the script will create and configure the Wine Bottle at ${WINEPREFIX}. You can cancel the instalation of gecko and say No to any error. Do you wish to continue?"
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

gtk_continue_question "Now the script will download and install Verbum Bible at ${WINEPREFIX}. You will need to interact with the installer. Do you wish to continue?"

echo "================================================="
# Geting and install the VerbumBible:
echo "Installing VerbumBible 64bits..."
if [ -f "${DOWNLOADED_RESOURCES}/${VERBUM64_MSI}" ]; then
	echo "${VERBUM64_MSI} exist. Using it..."
	cp "${DOWNLOADED_RESOURCES}/${VERBUM64_MSI}" "${WORKDIR}/" | zenity --progress --title="Copying..." --text="Copying: ${VERBUM64_MSI}\ninto: ${WORKDIR}" --pulsate --auto-close --no-cancel
else
	echo "${VERBUM64_MSI} does not exist. Downloading..."
	gtk_download "${VERBUM64_URL}" "${WORKDIR}"
fi
echo "${WINE_EXE} msiexec /i ${VERBUM64_MSI}"
${WINE_EXE} msiexec /i "${WORKDIR}"/"${VERBUM64_MSI}"

echo "======= Set VerbumBible Indexing to Vista Mode: ======="
${WINE_EXE} reg add "HKCU\\Software\\Wine\\AppDefaults\\VerbumIndexer.exe" /v Version /t REG_SZ /d vista /f
echo "======= VerbumBible logging set to Vista mode! ======="

heavy_wineserver_wait
echo "================================================="
clean_all
echo "================================================="

if gtk_question "Verbum Bible Installed!\nYou can run it using the script Verbum.sh inside ${INSTALLDIR}.\nDo you want to run it now?\nNOTE: Just close the error on the first execution."; then
	"${INSTALLDIR}"/Verbum.sh
fi

echo "End!"
echo "================================================="
exit 0
#==========================
