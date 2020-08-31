#!/bin/bash
# From https://github.com/ferion11/LogosLinuxInstaller
export THIS_SCRIPT_VERSION="v2.12-rc3"

# version of Logos from: https://wiki.logos.com/The_Logos_8_Beta_Program
if [ -z "${LOGOS_URL}" ]; then export LOGOS_URL="https://downloads.logoscdn.com/LBS8/Installer/8.15.0.0004/Logos-x86.msi" ; fi
if [ -z "${LOGOS64_URL}" ]; then export LOGOS64_URL="https://downloads.logoscdn.com/LBS8/Installer/8.15.0.0004/Logos-x64.msi" ; fi
if [ -z "${WINE_APPIMAGE_URL}" ]; then export WINE_APPIMAGE_URL="https://github.com/ferion11/Wine_Appimage/releases/download/continuous-logos/wine-i386_x86_64-archlinux.AppImage" ; fi
#if [ -z "${WINE4_APPIMAGE_URL}" ]; then export WINE4_APPIMAGE_URL="https://github.com/ferion11/Wine_Appimage/releases/download/v4.21/wine-i386_x86_64-archlinux.AppImage" ; fi
if [ -z "${WINE4_APPIMAGE_URL}" ]; then export WINE4_APPIMAGE_URL="https://github.com/ferion11/Wine_Appimage_dev/releases/download/continuous-f11wine4/wine-i386_x86_64-archlinux.AppImage" ; fi
if [ -z "${WINE5_APPIMAGE_URL}" ]; then export WINE5_APPIMAGE_URL="${WINE_APPIMAGE_URL}" ; fi
if [ -z "${WINE64_5_11_URL}" ]; then export WINE64_5_11_URL="https://www.playonlinux.com/wine/binaries/phoenicis/upstream-linux-amd64/PlayOnLinux-wine-5.0.2-upstream-linux-amd64.tar.gz" ; fi
if [ -z "${FAKE_WINE_APPIMAGE_URL}" ]; then export FAKE_WINE_APPIMAGE_URL="https://github.com/ferion11/libsutil/releases/download/fakeAppImage/wine-fake.AppImage" ; fi
#if [ -z "${WINETRICKS_URL}" ]; then export WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" ; fi
# back to Jul 23, 2020 release of winetricks, not more of the last git random broken fun:
if [ -z "${WINETRICKS_URL}" ]; then export WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/29d4edcfaec76128a68a0506605fd84473b6e38c/src/winetricks" ; fi
## trying one customized version of winetricks:
##if [ -z "${WINETRICKS_URL}" ]; then export WINETRICKS_URL="https://github.com/ferion11/libsutil/releases/download/winetricks/winetricks" ; fi
if [ -z "${WINETRICKS_DOWNLOADER}" ]; then export WINETRICKS_DOWNLOADER="wget" ; fi
#LOGOS_MVERSION=$(echo "${LOGOS_URL}" | cut -d/ -f4)
#export LOGOS_MVERSION
LOGOS_VERSION="$(echo "${LOGOS_URL}" | cut -d/ -f6)"
LOGOS_MSI="$(echo "${LOGOS_URL}" | cut -d/ -f7)"
LOGOS64_MSI="$(echo "${LOGOS64_URL}" | cut -d/ -f7)"
export LOGOS_VERSION
export LOGOS_MSI
export LOGOS64_MSI

if [ -z "${WORKDIR}" ]; then WORKDIR="$(mktemp -d)"; export WORKDIR ; fi
if [ -z "${INSTALLDIR}" ]; then export INSTALLDIR="${HOME}/LogosBible_Linux_P" ; fi

export APPDIR="${INSTALLDIR}/data"
export APPDIR_BINDIR="${APPDIR}/bin"
export WINE5_TMP_INST_DIRNAME="wineInstallation"
WINE5_TMP_FILENAME="$(echo "${WINE64_5_11_URL}" | cut -d/ -f8)"
export WINE5_TMP_FILENAME
export APPIMAGE_FILENAME="wine-i386_x86_64-archlinux.AppImage"
export APPIMAGE_LINK_SELECTION_NAME="selected_wine.AppImage"
export FAKE_WINE_APPIMAGE_NAME="wine-fake.AppImage"

# --force causes winetricks to install regardless of reported bugs. It also doesn't check whether it is already installed or not.
# -f, --force           Don't check whether packages were already installed
# -q, --unattended      Don't ask any questions, just install automatically
if [ -z "${WINETRICKS_EXTRA_OPTION}" ]; then export WINETRICKS_EXTRA_OPTION="-q" ; fi
if [ -z "${DOWNLOADED_RESOURCES}" ]; then export DOWNLOADED_RESOURCES="/tmp" ; fi


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
	then
		return 0
	else
		return 1
	fi
}
gtk_continue_question() {
	if ! gtk_question "$@"; then
		gtk_fatal_error "The installation is cancelled!"
	fi
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
		# ensure that directory, where the target file will be exists
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

	# NOTE: sometimes the process finish before the wait command, giving the error code 127
	if [ "${ZENITY_RETURN}" == "0" ] || [ "${ZENITY_RETURN}" == "127" ] ; then
		if [ "${WGET_RETURN}" != "0" ] && [ "${WGET_RETURN}" != "127" ] ; then
			echo "ERROR: error downloading the file! WGET_RETURN: ${WGET_RETURN}"
			gtk_fatal_error "The installation is cancelled because of error downloading the file!\n * ${FILENAME}\n  - WGET_RETURN: ${WGET_RETURN}"
		fi
	else
		gtk_fatal_error "The installation is cancelled!\n * ZENITY_RETURN: ${ZENITY_RETURN}"
	fi
	echo "${FILENAME} download finished!"
}
#--------------
#==========================

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
		else wget -c -P "\${WORKDIR}" https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
		fi
		chmod +x "\${WORKDIR}"/winetricks
		shift
		"\${WORKDIR}"/winetricks "\$@"
		rm -rf "\${WORKDIR}"
		echo "======= winetricks run done! ======="
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
	"selectAppImage")
		echo "======= Running AppImage Selection only: ======="
		APPIMAGE_FILENAME="${APPIMAGE_FILENAME}"
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
				echo "======= AppImage Selection run done with external link! ======="
				exit 0
			fi
		fi

		echo "Info: Linking ../\${APPIMAGE_FILENAME} to ./data/bin/\${APPIMAGE_LINK_SELECTION_NAME}"
		chmod +x "\${APPIMAGE_FULLPATH}"
		ln -s "../\${APPIMAGE_FILENAME}" "\${APPIMAGE_LINK_SELECTION_NAME}"
		rm -rf "\${HERE}/data/bin/\${APPIMAGE_LINK_SELECTION_NAME}"
		mv "\${APPIMAGE_LINK_SELECTION_NAME}" "\${HERE}/data/bin/"
		echo "======= AppImage Selection run done! ======="
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
		else wget -c -P "\${WORKDIR}" https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
		fi
		chmod +x "\${WORKDIR}"/winetricks
		shift
		"\${WORKDIR}"/winetricks "\$@"
		rm -rf "\${WORKDIR}"
		echo "======= winetricks run done! ======="
		exit 0
		;;
	"selectAppImage")
		echo "======= Running AppImage Selection only: ======="
		APPIMAGE_FILENAME="${APPIMAGE_FILENAME}"
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
				echo "======= AppImage Selection run done with external link! ======="
				exit 0
			fi
		fi

		echo "Info: Linking ../\${APPIMAGE_FILENAME} to ./data/bin/\${APPIMAGE_LINK_SELECTION_NAME}"
		chmod +x "\${APPIMAGE_FULLPATH}"
		ln -s "../\${APPIMAGE_FILENAME}" "\${APPIMAGE_LINK_SELECTION_NAME}"
		rm -rf "\${HERE}/data/bin/\${APPIMAGE_LINK_SELECTION_NAME}"
		mv "\${APPIMAGE_LINK_SELECTION_NAME}" "\${HERE}/data/bin/"
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
	WINE_BITS="${1}"
	WINE_EXE="${2}"

	echo "* Making skel${WINE_BITS} inside ${INSTALLDIR}"
	mkdir -p "${INSTALLDIR}"
	mkdir "${APPDIR}" || die "can't make dir: ${APPDIR}"

	# Making the links (and dir)
	mkdir "${APPDIR_BINDIR}" || die "can't make dir: ${APPDIR_BINDIR}"
	cd "${APPDIR_BINDIR}" || die "ERROR: Can't enter on dir: ${APPDIR_BINDIR}"
	ln -s "../${APPIMAGE_FILENAME}" "${APPIMAGE_LINK_SELECTION_NAME}"
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
echo 'Searching for dependencies:'

if [ "$(id -u)" = 0 ]; then
	echo "* Running Wine/winetricks as root is highly discouraged. See https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.3F"
fi

if [ -z "${DISPLAY}" ]; then
	echo "* You want to run without X, but it don't work."
	exit 1
fi

if have_dep mktemp; then
	echo '* mktemp is installed!'
else
	echo '* Your system does not have mktemp. Please install mktemp package.'
	exit 1
fi

if have_dep fuser; then
	echo '* fuser is installed!'
else
	echo '* Your system does not have fuser. Please install fuser package (Usually psmisc).'
	exit 1
fi

if have_dep zenity; then
	echo '* Zenity is installed!'
else
	echo '* Your system does not have Zenity. Please install Zenity package.'
	exit 1
fi

if have_dep wget; then
	echo '* wget is installed!'
else
	echo '* Your system does not have wget. Please install wget package.'
	gtk_fatal_error "Your system does not have wget. Please install wget package."
fi

if have_dep xwd; then
	echo '* xwd is installed!'
else
	echo '* Your system does not have xwd. Please install xwd package.'
	gtk_fatal_error "Your system does not have xwd. Please install xwd package."
fi

if have_dep find; then
	echo '* command find is installed!'
else
	echo '* Your system does not have find. Please install find package.'
	gtk_fatal_error "Your system does not have command find. Please install command find package."
fi

if have_dep sed; then
	echo '* command sed is installed!'
else
	echo '* Your system does not have sed. Please install sed package.'
	gtk_fatal_error "Your system does not have command sed. Please install command sed package."
fi

if have_dep grep; then
	echo '* command grep is installed!'
else
	echo '* Your system does not have grep. Please install grep package.'
	gtk_fatal_error "Your system does not have command grep. Please install command grep package."
fi

if have_dep cabextract; then
	echo '* command cabextract is installed!'
else
	echo '* Your system does not have cabextract. Please install cabextract package.'
	gtk_fatal_error "Your system does not have command cabextract. Please install command cabextract package."
fi

if have_dep ntlm_auth; then
	echo '* command ntlm_auth is installed!'
else
	echo '* Your system does not have ntlm_auth. Please install ntlm_auth package.'
	gtk_fatal_error "Your system does not have command ntlm_auth. Please install command ntlm_auth package (Usually winbind or samba)."
fi

echo "Starting Zenity GUI..."
#==========================


#======= Parsing =============
case "${1}" in
	"skel32")
		WINE_EXE="wine"
		make_skel "32" "${WINE_EXE}"
		rm -rf "${WORKDIR}"
		exit 0
		;;
	"skel64")
		WINE_EXE="wine64"
		make_skel "64" "${WINE_EXE}"
		rm -rf "${WORKDIR}"
		exit 0
		;;
	*)
		echo "No arguments parsed."
esac

#======= Main =============
if [ -d "${INSTALLDIR}" ]; then
	echo "One directory already exists in ${INSTALLDIR}, please remove/rename it or use another location by setting the INSTALLDIR variable"
	gtk_fatal_error "One directory already exists in ${INSTALLDIR}, please remove/rename it or use another location by setting the INSTALLDIR variable"
fi

installationChoice="$(zenity --width=700 --height=310 \
	--title="Question: Install Logos Bible" \
	--text="This script will create one directory in (can changed by setting the INSTALLDIR variable):\n\"${INSTALLDIR}\"\nto be one installation of LogosBible v${LOGOS_VERSION} independent of others installations.\nPlease, select the type of installation:" \
	--list --radiolist --column "S" --column "Descrition" \
	TRUE "1- Install LogosBible32 using Wine AppImage (default)." \
	FALSE "2- Install LogosBible32 using the native Wine." \
	FALSE "3- Install LogosBible64 using the native Wine64 (unstable)." \
	FALSE "4- Install LogosBible32 using AppImage v4.21 up to dotnet48 and replace with v5.x AppImage." \
	FALSE "5- Install LogosBible64 using Wine64 v5.11 up to dotnet48 and replace with native (unstable)." )"

case "${installationChoice}" in
	1*)
		echo "Installing LogosBible 32bits using Wine AppImage..."
		export WINEARCH=win32
		export WINEPREFIX="${APPDIR}/wine32_bottle"
		export WINE_EXE="wine"

		make_skel "32" "${WINE_EXE}"
		;;
	2*)
		echo "Installing LogosBible 32bits using the native Wine..."
		export NO_APPIMAGE="1"
		export WINEARCH=win32
		export WINEPREFIX="${APPDIR}/wine32_bottle"
		export WINE_EXE="wine"

		# check for wine installation
		WINE_VERSION_CHECK="$(${WINE_EXE} --version)"
		if [ -z "${WINE_VERSION_CHECK}" ]; then
			gtk_fatal_error "Wine not found! Please install native Wine first."
		fi
		echo "Using: ${WINE_VERSION_CHECK}"

		make_skel "32" "${WINE_EXE}"
		;;
	3*)
		echo "Installing LogosBible 64bits using the native Wine..."
		export NO_APPIMAGE="1"
		export WINEARCH=win64
		export WINEPREFIX="${APPDIR}/wine64_bottle"
		export WINE_EXE="wine64"

		# check for wine installation
		WINE_VERSION_CHECK="$(${WINE_EXE} --version)"
		if [ -z "${WINE_VERSION_CHECK}" ]; then
			gtk_fatal_error "Wine64 not found! Please install native Wine64 first."
		fi
		echo "Using: ${WINE_VERSION_CHECK}"

		make_skel "64" "${WINE_EXE}"
		;;
	4*)
		echo "Installing LogosBible 32bits using 2 Wine AppImage..."
		export WINEARCH=win32
		export WINEPREFIX="${APPDIR}/wine32_bottle"
		export WINE_EXE="wine"
		export INSTALL_USING_APPIMAGE_4="1"

		make_skel "32" "${WINE_EXE}"
		;;
	5*)
		echo "Installing LogosBible 64bits using 2 Wine versions..."
		export WINEARCH=win64
		export WINEPREFIX="${APPDIR}/wine64_bottle"
		export WINE_EXE="wine64"

		make_skel "64" "${WINE_EXE}"
		;;
	*)
		gtk_fatal_error "Installation canceled!"
esac

# exporting PATH to internal use if using AppImage or LocalDirInstall, doing backup too:
if [ -z "${NO_APPIMAGE}" ] ; then
	export OLD_PATH="${PATH}"
	export PATH="${APPDIR_BINDIR}":"${PATH}"
fi

if [ -z "${NO_APPIMAGE}" ] && [ "${WINEARCH}" == "win32" ] ; then
	echo "Using AppImage..."
	#-------------------------
	# Geting the AppImage:
	if [ -f "${DOWNLOADED_RESOURCES}/${APPIMAGE_FILENAME}" ]; then
		echo "${APPIMAGE_FILENAME} exist. Using it..."
		cp "${DOWNLOADED_RESOURCES}/${APPIMAGE_FILENAME}" "${APPDIR}/" | zenity --progress --title="Copying..." --text="Copying: ${APPIMAGE_FILENAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
		cp "${DOWNLOADED_RESOURCES}/${APPIMAGE_FILENAME}.zsync" "${APPDIR}" | zenity --progress --title="Copying..." --text="Copying: ${APPIMAGE_FILENAME}.zsync\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
	else
		echo "${APPIMAGE_FILENAME} does not exist. Downloading..."
		if [ -z "${INSTALL_USING_APPIMAGE_4}" ]; then
			gtk_download "${WINE_APPIMAGE_URL}" "${WORKDIR}"
		else
			gtk_download "${WINE4_APPIMAGE_URL}" "${WORKDIR}"
		fi

		mv "${WORKDIR}/${APPIMAGE_FILENAME}" "${APPDIR}" | zenity --progress --title="Moving..." --text="Moving: ${APPIMAGE_FILENAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel

		gtk_download "${WINE_APPIMAGE_URL}.zsync" "${WORKDIR}"
		mv "${WORKDIR}/${APPIMAGE_FILENAME}.zsync" "${APPDIR}" | zenity --progress --title="Moving..." --text="Moving: ${APPIMAGE_FILENAME}.zsync\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
	fi
	FILE="${APPDIR}/${APPIMAGE_FILENAME}"
	chmod +x "${FILE}"
	echo "Using: $(${WINE_EXE} --version)"
	#-------------------------
fi

if [ -z "${NO_APPIMAGE}" ] && [ "${WINEARCH}" == "win64" ] ; then
	echo "Using fake AppImage plus ${WINE5_TMP_FILENAME}..."
	#-------------------------
	# Geting the fake AppImage and Wine64:
	gtk_download "${FAKE_WINE_APPIMAGE_URL}" "${WORKDIR}"
	gtk_download "${WINE64_5_11_URL}" "${WORKDIR}"

	chmod +x "${WORKDIR}/${FAKE_WINE_APPIMAGE_NAME}"
	mv "${WORKDIR}/${FAKE_WINE_APPIMAGE_NAME}" "${APPDIR}"

	mkdir "${APPDIR}/${WINE5_TMP_INST_DIRNAME}" || die "Cannot create ${WINE5_TMP_INST_DIRNAME}"
	tar xf "${WORKDIR}/${WINE5_TMP_FILENAME}" -C "${APPDIR}/${WINE5_TMP_INST_DIRNAME}"/ | zenity --progress --title="Extracting..." --text="Extracting: ${WINE5_TMP_FILENAME}\ninto: ${APPDIR}/${WINE5_TMP_INST_DIRNAME}" --pulsate --auto-close --no-cancel

	# update links:
	rm -rf "${APPDIR_BINDIR:?}/${APPIMAGE_LINK_SELECTION_NAME}"
	ln -s "../${FAKE_WINE_APPIMAGE_NAME}" "${APPIMAGE_LINK_SELECTION_NAME}"
	mv "${APPIMAGE_LINK_SELECTION_NAME}" "${APPDIR_BINDIR}"

	echo "Using: $(${WINE_EXE} --version)"
	#-------------------------
fi

gtk_continue_question "Now the script will create and configure the Wine Bottle on ${WINEPREFIX}. You can cancel the instalation of Mono. Do you wish to continue?"
${WINE_EXE} wineboot

echo "* Waiting for ${WINE_EXE} to proper end..."
wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to proper end..." --pulsate --auto-close --no-cancel

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

echo "${WINE_EXE} regedit.exe disable-winemenubuilder.reg"
${WINE_EXE} regedit.exe "${WORKDIR}"/disable-winemenubuilder.reg | zenity --progress --title="Wine regedit" --text="Wine is blocking in ${WINEPREFIX}:\nfiletype associations, add menu items, or create desktop links" --pulsate --auto-close --no-cancel
echo "* Waiting for ${WINE_EXE} to proper end..."
wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to proper end..." --pulsate --auto-close --no-cancel
echo "${WINE_EXE} regedit.exe disable-winemenubuilder.reg DONE!"

echo "${WINE_EXE} regedit.exe renderer_gdi.reg"
${WINE_EXE} regedit.exe "${WORKDIR}"/renderer_gdi.reg | zenity --progress --title="Wine regedit" --text="Wine is changing the renderer to gdi:\nthe old DirectDrawRenderer and the new renderer key" --pulsate --auto-close --no-cancel
echo "* Waiting for ${WINE_EXE} to proper end..."
wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to proper end..." --pulsate --auto-close --no-cancel
echo "${WINE_EXE} regedit.exe renderer_gdi.reg DONE!"

gtk_continue_question "Now the script will install the winetricks packages on ${WINEPREFIX}. Do you wish to continue?"

if [ -f "${DOWNLOADED_RESOURCES}/winetricks" ]; then
	echo "winetricks exist. Using it..."
	cp "${DOWNLOADED_RESOURCES}/winetricks" "${WORKDIR}"
else
	echo "winetricks does not exist. Downloading..."
	gtk_download "${WINETRICKS_URL}" "${WORKDIR}"
fi
chmod +x "${WORKDIR}/winetricks"

#-------------------------------------------------
echo "winetricks ${WINETRICKS_EXTRA_OPTION} corefonts"
pipe_winetricks="$(mktemp)"
rm -rf "${pipe_winetricks}"
mkfifo "${pipe_winetricks}"

# zenity GUI feedback
zenity --progress --title="Winetricks corefonts" --text="Winetricks installing corefonts" --pulsate --auto-close < "${pipe_winetricks}" &
ZENITY_PID="${!}"

"${WORKDIR}"/winetricks "${WINETRICKS_EXTRA_OPTION}" corefonts > "${pipe_winetricks}"
WINETRICKS_STATUS="${?}"

wait "${ZENITY_PID}"
ZENITY_RETURN="${?}"

#fuser -TERM -k -w "${pipe_winetricks}"
rm -rf "${pipe_winetricks}"

# NOTE: sometimes the process finish before the wait command, giving the error code 127
if [ "${ZENITY_RETURN}" == "0" ] || [ "${ZENITY_RETURN}" == "127" ] ; then
	if [ "${WINETRICKS_STATUS}" != "0" ] ; then
		echo "ERROR on : winetricks ${WINETRICKS_EXTRA_OPTION} corefonts; WINETRICKS_STATUS: ${WINETRICKS_STATUS}"
		gtk_fatal_error "The installation is cancelled because of sub-job failure!\n * winetricks ${WINETRICKS_EXTRA_OPTION} corefonts\n  - WINETRICKS_STATUS: ${WINETRICKS_STATUS}"
	fi
else
	gtk_fatal_error "The installation is cancelled!\n * ZENITY_RETURN: ${ZENITY_RETURN}"
fi
echo "winetricks ${WINETRICKS_EXTRA_OPTION} corefonts DONE!"
#-------------------------------------------------
echo "* Waiting for ${WINE_EXE} to proper end..."
wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to proper end..." --pulsate --auto-close --no-cancel
#-------------------------------------------------
echo "winetricks ${WINETRICKS_EXTRA_OPTION} settings fontsmooth=rgb"
pipe_winetricks="$(mktemp)"
rm -rf "${pipe_winetricks}"
mkfifo "${pipe_winetricks}"

# zenity GUI feedback
zenity --progress --title="Winetricks fontsmooth" --text="Winetricks setting fontsmooth=rgb..." --pulsate --auto-close < "${pipe_winetricks}" &
ZENITY_PID="${!}"

"${WORKDIR}"/winetricks "${WINETRICKS_EXTRA_OPTION}" settings fontsmooth=rgb > "${pipe_winetricks}"
WINETRICKS_STATUS="${?}"

wait "${ZENITY_PID}"
ZENITY_RETURN="${?}"

#fuser -TERM -k -w "${pipe_winetricks}"
rm -rf "${pipe_winetricks}"

# NOTE: sometimes the process finish before the wait command, giving the error code 127
if [ "${ZENITY_RETURN}" == "0" ] || [ "${ZENITY_RETURN}" == "127" ] ; then
	if [ "${WINETRICKS_STATUS}" != "0" ] ; then
		echo "ERROR on : winetricks ${WINETRICKS_EXTRA_OPTION} settings fontsmooth=rgb; WINETRICKS_STATUS: ${WINETRICKS_STATUS}"
		gtk_fatal_error "The installation is cancelled because of sub-job failure!\n * winetricks ${WINETRICKS_EXTRA_OPTION} settings fontsmooth=rgb\n  - WINETRICKS_STATUS: ${WINETRICKS_STATUS}"
	fi
else
	gtk_fatal_error "The installation is cancelled!\n * ZENITY_RETURN: ${ZENITY_RETURN}"
fi
echo "winetricks ${WINETRICKS_EXTRA_OPTION} settings fontsmooth=rgb DONE!"
#-------------------------------------------------
echo "* Waiting for ${WINE_EXE} to proper end..."
wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to proper end..." --pulsate --auto-close --no-cancel
#-------------------------------------------------
echo "winetricks ${WINETRICKS_EXTRA_OPTION} dotnet48"
pipe_winetricks="$(mktemp)"
rm -rf "${pipe_winetricks}"
mkfifo "${pipe_winetricks}"

# zenity GUI feedback
zenity --progress --title="Winetricks dotnet48" --text="Winetricks installing DotNet v2.0, v4.0 and v4.8 update (It might take a while)..." --pulsate --auto-close < "${pipe_winetricks}" &
ZENITY_PID="${!}"

"${WORKDIR}"/winetricks "${WINETRICKS_EXTRA_OPTION}" dotnet48 > "${pipe_winetricks}"
WINETRICKS_STATUS="${?}"

wait "${ZENITY_PID}"
ZENITY_RETURN="${?}"

#fuser -TERM -k -w "${pipe_winetricks}"
rm -rf "${pipe_winetricks}"

# NOTE: sometimes the process finish before the wait command, giving the error code 127
if [ "${ZENITY_RETURN}" == "0" ] || [ "${ZENITY_RETURN}" == "127" ] ; then
	if [ "${WINETRICKS_STATUS}" != "0" ] ; then
		echo "ERROR on : winetricks ${WINETRICKS_EXTRA_OPTION} dotnet48; WINETRICKS_STATUS: ${WINETRICKS_STATUS}"
		gtk_fatal_error "The installation is cancelled because of sub-job failure!\n * winetricks ${WINETRICKS_EXTRA_OPTION} dotnet48\n  - WINETRICKS_STATUS: ${WINETRICKS_STATUS}"
	fi
else
	gtk_fatal_error "The installation is cancelled!\n * ZENITY_RETURN: ${ZENITY_RETURN}"
fi
echo "winetricks ${WINETRICKS_EXTRA_OPTION} dotnet48 DONE!"
#-------------------------------------------------

echo "* Waiting for ${WINE_EXE} to proper end..."
wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to proper end..." --pulsate --auto-close --no-cancel

if [ -n "${INSTALL_USING_APPIMAGE_4}" ]; then
	gtk_download "${WINE5_APPIMAGE_URL}" "${WORKDIR}"
	rm -rf "${APPDIR:?}/${APPIMAGE_FILENAME}"
	mv "${WORKDIR}/${APPIMAGE_FILENAME}" "${APPDIR}" | zenity --progress --title="Moving..." --text="Moving: ${APPIMAGE_FILENAME}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
	FILE="${APPDIR}/${APPIMAGE_FILENAME}"
	chmod +x "${FILE}"
	echo "Using: $(${WINE_EXE} --version)"
	${WINE_EXE} wineboot

	echo "* Waiting for ${WINE_EXE} to proper end..."
	wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to proper end..." --pulsate --auto-close --no-cancel
fi

if [ -z "${NO_APPIMAGE}" ] && [ "${WINEARCH}" == "win64" ] ; then
	echo "Removing temp Wine, and using native 64bit one..."
	rm -rf "${APPDIR:?}/${FAKE_WINE_APPIMAGE_NAME}"
	rm -rf "${APPDIR:?}/${WINE5_TMP_INST_DIRNAME}"

	# removing the local bin PATH to be sure of using the local 64bit installation
	export PATH="${OLD_PATH}"

	# check for wine installation
	WINE_VERSION_CHECK="$(${WINE_EXE} --version)"
	if [ -z "${WINE_VERSION_CHECK}" ]; then
		gtk_fatal_error "Wine64 not found! Please install native Wine64 first."
	fi
	echo "Using: ${WINE_VERSION_CHECK}"
	${WINE_EXE} wineboot

	echo "* Waiting for ${WINE_EXE} to proper end..."
	wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to proper end..." --pulsate --auto-close --no-cancel
fi

gtk_continue_question "Now the script will download and install Logos Bible on ${WINEPREFIX}. You will need to interact with the installer. Do you wish to continue?"

# Geting and install the LogosBible:
case "${WINEARCH}" in
	win32)
		echo "Installing LogosBible 32bits..."
		if [ -f "${DOWNLOADED_RESOURCES}/${LOGOS_MSI}" ]; then
			echo "${LOGOS_MSI} exist. Using it..."
			cp "${DOWNLOADED_RESOURCES}/${LOGOS_MSI}" "${WORKDIR}/" | zenity --progress --title="Copying..." --text="Copying: ${LOGOS_MSI}\ninto: ${WORKDIR}" --pulsate --auto-close --no-cancel
		else
			echo "${LOGOS_MSI} does not exist. Downloading..."
			gtk_download "${LOGOS_URL}" "${WORKDIR}"
		fi
		${WINE_EXE} msiexec /i "${WORKDIR}"/"${LOGOS_MSI}"
		;;
	win64)
		echo "Installing LogosBible 64bits..."
		if [ -f "${DOWNLOADED_RESOURCES}/${LOGOS64_MSI}" ]; then
			echo "${LOGOS64_MSI} exist. Using it..."
			cp "${DOWNLOADED_RESOURCES}/${LOGOS64_MSI}" "${WORKDIR}/" | zenity --progress --title="Copying..." --text="Copying: ${LOGOS64_MSI}\ninto: ${WORKDIR}" --pulsate --auto-close --no-cancel
		else
			echo "${LOGOS64_MSI} does not exist. Downloading..."
			gtk_download "${LOGOS64_URL}" "${WORKDIR}"
		fi
		${WINE_EXE} msiexec /i "${WORKDIR}"/"${LOGOS64_MSI}"
		;;
	*)
		gtk_fatal_error "Installation failed!"
esac

echo "* Waiting for ${WINE_EXE} to proper end..."
wineserver -w | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to proper end..." --pulsate --auto-close --no-cancel

clean_all

if gtk_question "Logos Bible Installed!\nYou can run it using the script Logos.sh inside ${INSTALLDIR}.\nDo you want to run it now?\nNOTE: Just close the error on the first execution."; then
	"${INSTALLDIR}"/Logos.sh
fi

echo "End!"
exit 0
#==========================
