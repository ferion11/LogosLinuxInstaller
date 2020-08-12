#!/bin/bash
# From https://github.com/ferion11/LogosLinuxInstaller
export THIS_SCRIPT_VERSION="v2.4-rc3"

# version of Logos from: https://wiki.logos.com/The_Logos_8_Beta_Program
export LOGOS_URL="https://downloads.logoscdn.com/LBS8/Installer/8.15.0.0004/Logos-x86.msi"
export LOGOS64_URL="https://downloads.logoscdn.com/LBS8/Installer/8.15.0.0004/Logos-x64.msi"
export WINE_APPIMAGE_URL="https://github.com/ferion11/Wine_Appimage/releases/download/continuous/wine-i386_x86_64-archlinux.AppImage"
export WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
#LOGOS_MVERSION=$(echo $LOGOS_URL | cut -d/ -f4)
#export LOGOS_MVERSION
LOGOS_VERSION=$(echo $LOGOS_URL | cut -d/ -f6)
LOGOS_MSI=$(echo $LOGOS_URL | cut -d/ -f7)
LOGOS64_MSI=$(echo $LOGOS64_URL | cut -d/ -f7)
export LOGOS_VERSION
export LOGOS_MSI
export LOGOS64_MSI

if [ -z "$WORKDIR" ]; then export WORKDIR="$(mktemp -d)" ; fi
if [ -z "$INSTALLDIR" ]; then export INSTALLDIR="$HOME/LogosBible_Linux_P" ; fi

export APPDIR="${INSTALLDIR}/data"
export APPDIR_BIN="$APPDIR/bin"
export APPIMAGE_NAME="wine-i386_x86_64-archlinux.AppImage"

# --force causes winetricks to install regardless of reported bugs. It also doesn't check whether it is already installed or not.
WINETRICKS_EXTRA_OPTION="--force"
#DOWNLOADED_RESOURCES=""


#======= Aux =============
die() { echo >&2 "$*"; exit 1; };

have_dep() {
	command -v "$1" >/dev/null 2>&1
}

clean_all() {
	echo "Cleaning all temp files..."
	rm -rf "$WORKDIR"
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

	percent_file="$(mktemp)"
	pipe="$(mktemp)"
	rm -rf "${pipe}"
	mkfifo "${pipe}"

	# download with output to dialog progress bar
	total_size="Starting..."
	percent="0"
	current="Starting..."
	speed="Starting..."
	remain="Starting..."
	wget -c "$1" -O "$TARGET" 2>&1 | while read -r data; do
		#if [ "$(echo "$data" | grep '^Length:')" ]; then
		if echo "$data" | grep -q '^Length:' ; then
			result=$(echo "$data" | grep "^Length:" | sed 's/.*\((.*)\).*/\1/' |  tr -d '()')
			if [ ${#result} -le 10 ]; then total_size=${result} ; fi
		fi

		#if [ "$(echo "$data" | grep '[0-9]*%' )" ];then
		if echo "$data" | grep -q '[0-9]*%' ;then
			result=$(echo "$data" | grep -o "[0-9]*%" | tr -d '%')
			if [ ${#result} -le 3 ]; then percent=${result} ; fi

			result=$(echo "$data" | grep "[0-9]*%" | sed 's/\([0-9BKMG]\+\).*/\1/' )
			if [ ${#result} -le 10 ]; then current=${result} ; fi

			result=$(echo "$data" | grep "[0-9]*%" | sed 's/.*\(% [0-9BKMG.]\+\).*/\1/' | tr -d ' %')
			if [ ${#result} -le 10 ]; then speed=${result} ; fi

			result=$(echo "$data" | grep -o "[0-9A-Za-z]*$" )
			if [ ${#result} -le 10 ]; then remain=${result} ; fi
		fi

		# report
		echo "$percent"
		echo "$percent" > "${percent_file}"
		# shellcheck disable=SC2028
		echo "#Downloading: $FILENAME\ninto: $2\n\n$current of $total_size ($percent%)\nSpeed : $speed/Sec\nEstimated time : $remain"
	done > "${pipe}" &

	zenity --progress --title "Downloading $FILENAME..." --text="Downloading: $FILENAME\ninto: $2\n" --percentage=0 --auto-close < "${pipe}"
	RETURN_ZENITY="${?}"
	rm -rf "${pipe}"

	percent="$(cat "${percent_file}")"
	rm -rf "${percent_file}"
	if [ "${RETURN_ZENITY}" == "0" ] ; then
		if [ "${percent}" != "100" ] ; then
			echo "ERROR: incomplete downloaded file! ${FILENAME}  - percent: ${percent}"
			gtk_fatal_error "The installation is cancelled because of incomplete downloaded file!\n * ${FILENAME}\n  - percent: ${percent}"
		fi
	else
		gtk_fatal_error "The installation is cancelled!\n * RETURN_ZENITY: ${RETURN_ZENITY}"
	fi
	echo "${FILENAME} download finished!"
}
#--------------
#==========================

#======= making the starting scripts ==============
create_starting_scripts_32() {
	echo "Creating starting scripts for LogosBible 32bits..."
	#------- Logos.sh -------------
	cat > "${WORKDIR}"/Logos.sh << EOF
#!/bin/bash
# generated by "${THIS_SCRIPT_VERSION}" script from https://github.com/ferion11/LogosLinuxInstaller

#------------- Starting block --------------
HERE="\$(dirname "\$(readlink -f "\${0}")")"

# Save IFS
IFS_TMP=\$IFS
IFS=$'\n'

#-------------------------------------------
export PATH="\${HERE}/data/bin:\${PATH}"
export WINEARCH=win32
export WINEPREFIX="\${HERE}/data/wine32_bottle"
#-------------------------------------------

# wine Run:
if [ "\$1" = "wine" ] ; then
	echo "======= Running wine only: ======="
	shift
	wine "\$@"
	wineserver -w
	echo "======= wine run done! ======="
	exit 0
fi

# wineserver Run:
if [ "\$1" = "wineserver" ] ; then
	echo "======= Running wineserver only: ======="
	shift
	wineserver "\$@"
	echo "======= wineserver run done! ======="
	exit 0
fi

# winetricks Run:
if [ "\$1" = "winetricks" ] ; then
	echo "======= Running winetricks only: ======="
	WORKDIR="\$(mktemp -d)"
	wget -c -P \${WORKDIR} https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
	chmod +x \${WORKDIR}/winetricks
	shift
	\${WORKDIR}/winetricks "\$@"
	rm -rf \${WORKDIR}
	echo "======= winetricks run done! ======="
	exit 0
fi

# Indexing Run:
if [ "\$1" = "indexing" ] ; then
	echo "======= Running indexing on the Logos inside this installation only: ======="
	LOGOS_INDEXER_EXE=\$(find \${WINEPREFIX} -name LogosIndexer.exe |  grep "Logos\/System\/LogosIndexer.exe")
	if [ -z "\${LOGOS_INDEXER_EXE}" ] ; then
		echo "* ERROR: the LogosIndexer.exe can't be found!!!"
		exit 1
	fi
	echo "* Closing anything running in this wine bottle:"
	wineserver -k
	echo "* Running the indexer:"
	wine "\${LOGOS_INDEXER_EXE}"
	wineserver -w
	echo "======= indexing of LogosBible run done! ======="
	exit 0
fi

LOGOS_EXE=\$(find \${WINEPREFIX} -name Logos.exe | grep "Logos\/Logos.exe")
if [ -z "\$LOGOS_EXE" ] ; then
	echo "======= Running control: ======="
	"\${HERE}/controlPanel.sh"
	echo "======= control run done! ======="
	exit 0
fi

wine "\${LOGOS_EXE}"
wineserver -w

#------------- Ending block ----------------
# restore IFS
IFS=\$IFS_TMP
#-------------------------------------------
EOF
	#------------------------------
	chmod +x "${WORKDIR}"/Logos.sh
	mv "${WORKDIR}"/Logos.sh "${INSTALLDIR}"/

	#------- controlPanel.sh ------
	cat > "${WORKDIR}"/controlPanel.sh << EOF
#!/bin/bash
# generated by "${THIS_SCRIPT_VERSION}" script from https://github.com/ferion11/LogosLinuxInstaller

#------------- Starting block --------------
HERE="\$(dirname "\$(readlink -f "\${0}")")"

# Save IFS
IFS_TMP=\$IFS
IFS=$'\n'

#-------------------------------------------
export PATH="\${HERE}/data/bin:\${PATH}"
export WINEARCH=win32
export WINEPREFIX="\${HERE}/data/wine32_bottle"
#-------------------------------------------

# wine Run:
if [ "\$1" = "wine" ] ; then
	echo "======= Running wine only: ======="
	shift
	wine "\$@"
	wineserver -w
	echo "======= wine run done! ======="
	exit 0
fi

# wineserver Run:
if [ "\$1" = "wineserver" ] ; then
	echo "======= Running wineserver only: ======="
	shift
	wineserver "\$@"
	echo "======= wineserver run done! ======="
	exit 0
fi

# winetricks Run:
if [ "\$1" = "winetricks" ] ; then
	echo "======= Running winetricks only: ======="
	WORKDIR="\$(mktemp -d)"
	wget -c -P \${WORKDIR} https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
	chmod +x \${WORKDIR}/winetricks
	shift
	\${WORKDIR}/winetricks "\$@"
	rm -rf \${WORKDIR}
	echo "======= winetricks run done! ======="
	exit 0
fi

wine control
wineserver -w

#------------- Ending block ----------------
# restore IFS
IFS=\$IFS_TMP
#-------------------------------------------
EOF
	#------------------------------
	chmod +x "${WORKDIR}"/controlPanel.sh
	mv "${WORKDIR}"/controlPanel.sh "${INSTALLDIR}"/
}

create_starting_scripts_64() {
	echo "Creating starting scripts for LogosBible 64bits..."
	#------- Logos.sh -------------
	cat > "${WORKDIR}"/Logos.sh << EOF
#!/bin/bash
# generated by "${THIS_SCRIPT_VERSION}" script from https://github.com/ferion11/LogosLinuxInstaller

#------------- Starting block --------------
HERE="\$(dirname "\$(readlink -f "\${0}")")"

# Save IFS
IFS_TMP=\$IFS
IFS=$'\n'

#-------------------------------------------
export PATH="\${HERE}/data/bin:\${PATH}"
export WINEARCH=win64
export WINEPREFIX="\${HERE}/data/wine64_bottle"
#-------------------------------------------

# wine64 Run:
if [ "\$1" = "wine" ] ; then
	echo "======= Running wine64 only: ======="
	shift
	wine64 "\$@"
	wineserver -w
	echo "======= wine64 run done! ======="
	exit 0
fi

# wineserver Run:
if [ "\$1" = "wineserver" ] ; then
	echo "======= Running wineserver only: ======="
	shift
	wineserver "\$@"
	echo "======= wineserver run done! ======="
	exit 0
fi

# winetricks Run:
if [ "\$1" = "winetricks" ] ; then
	echo "======= Running winetricks only: ======="
	WORKDIR="\$(mktemp -d)"
	wget -c -P \${WORKDIR} https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
	chmod +x \${WORKDIR}/winetricks
	shift
	\${WORKDIR}/winetricks "\$@"
	rm -rf \${WORKDIR}
	echo "======= winetricks run done! ======="
	exit 0
fi

# Indexing Run:
if [ "\$1" = "indexing" ] ; then
	echo "======= Running indexing on the Logos inside this installation only: ======="
	LOGOS_INDEXER_EXE=\$(find \${WINEPREFIX} -name LogosIndexer.exe |  grep "Logos\/System\/LogosIndexer.exe")
	if [ -z "\${LOGOS_INDEXER_EXE}" ] ; then
		echo "* ERROR: the LogosIndexer.exe can't be found!!!"
		exit 1
	fi
	echo "* Closing anything running in this wine bottle:"
	wineserver -k
	echo "* Running the indexer:"
	wine64 "\${LOGOS_INDEXER_EXE}"
	wineserver -w
	echo "======= indexing of LogosBible run done! ======="
	exit 0
fi

LOGOS_EXE=\$(find \${WINEPREFIX} -name Logos.exe | grep "Logos\/Logos.exe")
if [ -z "\$LOGOS_EXE" ] ; then
	echo "======= Running control: ======="
	"\${HERE}/controlPanel.sh"
	echo "======= control run done! ======="
	exit 0
fi

wine64 "\${LOGOS_EXE}"
wineserver -w

#------------- Ending block ----------------
# restore IFS
IFS=\$IFS_TMP
#-------------------------------------------
EOF
	#------------------------------
	chmod +x "${WORKDIR}"/Logos.sh
	mv "${WORKDIR}"/Logos.sh "${INSTALLDIR}"/

	#------- controlPanel.sh ------
	cat > "${WORKDIR}"/controlPanel.sh << EOF
#!/bin/bash
# generated by "${THIS_SCRIPT_VERSION}" script from https://github.com/ferion11/LogosLinuxInstaller

#------------- Starting block --------------
HERE="\$(dirname "\$(readlink -f "\${0}")")"

# Save IFS
IFS_TMP=\$IFS
IFS=$'\n'

#-------------------------------------------
export PATH="\${HERE}/data/bin:\${PATH}"
export WINEARCH=win64
export WINEPREFIX="\${HERE}/data/wine64_bottle"
#-------------------------------------------

# wine64 Run:
if [ "\$1" = "wine" ] ; then
	echo "======= Running wine64 only: ======="
	shift
	wine64 "\$@"
	wineserver -w
	echo "======= wine64 run done! ======="
	exit 0
fi

# wineserver Run:
if [ "\$1" = "wineserver" ] ; then
	echo "======= Running wineserver only: ======="
	shift
	wineserver "\$@"
	echo "======= wineserver run done! ======="
	exit 0
fi

# winetricks Run:
if [ "\$1" = "winetricks" ] ; then
	echo "======= Running winetricks only: ======="
	WORKDIR="\$(mktemp -d)"
	wget -c -P \${WORKDIR} https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
	chmod +x \${WORKDIR}/winetricks
	shift
	\${WORKDIR}/winetricks "\$@"
	rm -rf \${WORKDIR}
	echo "======= winetricks run done! ======="
	exit 0
fi

wine64 control
wineserver -w

#------------- Ending block ----------------
# restore IFS
IFS=\$IFS_TMP
#-------------------------------------------
EOF
	#------------------------------
	chmod +x "${WORKDIR}"/controlPanel.sh
	mv "${WORKDIR}"/controlPanel.sh "${INSTALLDIR}"/
}
#==================================================

#======= Basic Deps =============
echo 'Searching for dependencies:'

if [ "$(id -u)" = 0 ]; then
	echo "* Running Wine/winetricks as root is highly discouraged. See https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.3F"
fi

if [ -z "$DISPLAY" ]; then
	echo "* You want to run without X, but it don't work."
	exit 1
fi

if have_dep mktemp; then
	echo '* mktemp is installed!'
else
	echo '* Your system does not have mktemp. Please install mktemp package.'
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


#======= Main =============

if [ "$1" = "scripts" ]; then
	mkdir "$WORKDIR"

	mkdir /tmp/scripts32 || die "can't create the directory /tmp/scripts32"
	export INSTALLDIR="/tmp/scripts32"
	create_starting_scripts_32

	mkdir /tmp/scripts64 || die "can't create the directory /tmp/scripts64"
	export INSTALLDIR="/tmp/scripts64"
	create_starting_scripts_64

	rm -rf "$WORKDIR"
	exit 0
fi

if [ -d "$INSTALLDIR" ]; then
	gtk_fatal_error "One directory already exists in ${INSTALLDIR}, please remove/rename it or use another location by setting the INSTALLDIR variable"
fi

installationChoice="$(zenity --width=400 --height=250 \
	--title="Question: Install Logos Bible" \
	--text="This script will create one directory in (can changed by setting the INSTALLDIR variable):\n\"${INSTALLDIR}\"\nto be one installation of LogosBible v$LOGOS_VERSION independent of others installations.\nPlease, select the type of installation:" \
	--list --radiolist --column "S" --column "Descrition" \
	TRUE "1- Install LogosBible32 using Wine AppImage (default)." \
	FALSE "2- Install LogosBible32 using the native Wine." \
	FALSE "3- Install LogosBible64 using the native Wine64 (unstable)." )"

case "${installationChoice}" in
	1*)
		echo "Installing LogosBible 32bits using Wine AppImage..."
		export WINEARCH=win32
		export WINEPREFIX="$APPDIR/wine32_bottle"
		export WINE_EXE="wine"
		;;
	2*)
		echo "Installing LogosBible 32bits using the native Wine..."
		export NO_APPIMAGE="1"
		export WINEARCH=win32
		export WINEPREFIX="$APPDIR/wine32_bottle"
		export WINE_EXE="wine"

		# check for wine installation
		WINE_VERSION_CHECK="$(wine --version)"
		if [ -z "${WINE_VERSION_CHECK}" ]; then
			gtk_fatal_error "Wine not found! Please install native Wine first."
		fi
		echo "Using: ${WINE_VERSION_CHECK}"
		;;
	3*)
		echo "Installing LogosBible 64bits using the native Wine..."
		export NO_APPIMAGE="1"
		export WINEARCH=win64
		export WINEPREFIX="$APPDIR/wine64_bottle"
		export WINE_EXE="wine64"

		# check for wine installation
		WINE_VERSION_CHECK="$(wine64 --version)"
		if [ -z "${WINE_VERSION_CHECK}" ]; then
			gtk_fatal_error "Wine64 not found! Please install native Wine64 first."
		fi
		echo "Using: ${WINE_VERSION_CHECK}"
		;;
	*)
		gtk_fatal_error "Installation canceled!"
esac

# Making the setup:
echo "Setup making..."
mkdir -p "$WORKDIR"
mkdir -p "$INSTALLDIR"
mkdir_critical "$APPDIR"
# Making the links (and dir)
mkdir_critical "${APPDIR_BIN}"
cd "${APPDIR_BIN}" || die "ERROR: Can't enter on dir: ${APPDIR_BIN}"
ln -s "../${APPIMAGE_NAME}" wine
ln -s "../${APPIMAGE_NAME}" wineserver
cd - || die "ERROR: Can't go back to preview dir!"
export PATH="${APPDIR_BIN}":$PATH
echo "Setup ok!"

if [ -z "$NO_APPIMAGE" ]; then
	echo "Using AppImage..."
	#-------------------------
	# Geting the AppImage:
	if [ -f "${DOWNLOADED_RESOURCES}/${APPIMAGE_NAME}" ]; then
		echo "${APPIMAGE_NAME} exist. Using it..."
		cp "${DOWNLOADED_RESOURCES}/${APPIMAGE_NAME}" "${APPDIR}/" | zenity --progress --title="Copying..." --text="Copying: $APPIMAGE_NAME\ninto: $APPDIR" --pulsate --auto-close --no-cancel
		cp "${DOWNLOADED_RESOURCES}/$APPIMAGE_NAME.zsync" "$APPDIR" | zenity --progress --title="Copying..." --text="Copying: $APPIMAGE_NAME.zsync\ninto: $APPDIR" --pulsate --auto-close --no-cancel
	else
		echo "${APPIMAGE_NAME} does not exist. Downloading..."
		gtk_download "${WINE_APPIMAGE_URL}" "$WORKDIR"

		mv "$WORKDIR/$APPIMAGE_NAME" "$APPDIR" | zenity --progress --title="Moving..." --text="Moving: $APPIMAGE_NAME\ninto: $APPDIR" --pulsate --auto-close --no-cancel

		gtk_download "${WINE_APPIMAGE_URL}.zsync" "$WORKDIR"
		mv "$WORKDIR/$APPIMAGE_NAME.zsync" "$APPDIR" | zenity --progress --title="Moving..." --text="Moving: $APPIMAGE_NAME.zsync\ninto: $APPDIR" --pulsate --auto-close --no-cancel
	fi
	FILE="$APPDIR/$APPIMAGE_NAME"
	chmod +x "${FILE}"
	#-------------------------
fi

gtk_continue_question "Now the script will create and configure the Wine Bottle on ${WINEPREFIX}. You can cancel the instalation of Mono. Do you wish to continue?"
${WINE_EXE} wineboot

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
${WINE_EXE} regedit.exe "${WORKDIR}"/disable-winemenubuilder.reg | zenity --progress --title="Wine regedit" --text="Wine is blocking in $WINEPREFIX:\nfiletype associations, add menu items, or create desktop links" --pulsate --auto-close --no-cancel
echo "${WINE_EXE} regedit.exe disable-winemenubuilder.reg DONE!"
echo "${WINE_EXE} regedit.exe renderer_gdi.reg"
${WINE_EXE} regedit.exe "${WORKDIR}"/renderer_gdi.reg | zenity --progress --title="Wine regedit" --text="Wine is changing the renderer to gdi:\nthe old DirectDrawRenderer and the new renderer key" --pulsate --auto-close --no-cancel
echo "${WINE_EXE} regedit.exe renderer_gdi.reg DONE!"

gtk_continue_question "Now the script will install the winetricks packages on ${WINEPREFIX}. Do you wish to continue?"

gtk_download "${WINETRICKS_URL}" "$WORKDIR"
chmod +x "$WORKDIR/winetricks"

#-------------------------------------------------
echo "winetricks ${WINETRICKS_EXTRA_OPTION} -q corefonts"
pipe="$(mktemp)"
rm -rf "${pipe}"
mkfifo "${pipe}"

$WORKDIR/winetricks "${WINETRICKS_EXTRA_OPTION}" -q corefonts > "${pipe}" &
JOB_PID="${!}"

zenity --progress --title="Winetricks corefonts" --text="Winetricks installing corefonts" --pulsate --auto-close < "${pipe}"
RETURN_ZENITY="${?}"
rm -rf "${pipe}"

if [ "${RETURN_ZENITY}" == "0" ] ; then
	wait "${JOB_PID}"
	JOB_STATUS="${?}"

	if [ "${JOB_STATUS}" != "0" ] ; then
		echo "ERROR on : winetricks ${WINETRICKS_EXTRA_OPTION} -q corefonts; JOB_STATUS: ${JOB_STATUS}"
		gtk_fatal_error "The installation is cancelled because of sub-job failure!\n * winetricks -q corefonts\n  - JOB_STATUS: ${JOB_STATUS}"
	fi
else
	kill -15 ${JOB_PID}
	gtk_fatal_error "The installation is cancelled!\n * RETURN_ZENITY: ${RETURN_ZENITY}"
fi
echo "winetricks -q corefonts DONE!"
#-------------------------------------------------
#-------------------------------------------------
echo "winetricks ${WINETRICKS_EXTRA_OPTION} -q settings fontsmooth=rgb"
pipe="$(mktemp)"
rm -rf "${pipe}"
mkfifo "${pipe}"

$WORKDIR/winetricks "${WINETRICKS_EXTRA_OPTION}" -q settings fontsmooth=rgb > "${pipe}" &
JOB_PID="${!}"

zenity --progress --title="Winetricks fontsmooth" --text="Winetricks setting fontsmooth=rgb..." --pulsate --auto-close < "${pipe}"
RETURN_ZENITY="${?}"
rm -rf "${pipe}"

if [ "${RETURN_ZENITY}" == "0" ] ; then
	wait "${JOB_PID}"
	JOB_STATUS="${?}"

	if [ "${JOB_STATUS}" != "0" ] ; then
		echo "ERROR on : winetricks ${WINETRICKS_EXTRA_OPTION} -q settings fontsmooth=rgb; JOB_STATUS: ${JOB_STATUS}"
		gtk_fatal_error "The installation is cancelled because of sub-job failure!\n * winetricks -q settings fontsmooth=rgb\n  - JOB_STATUS: ${JOB_STATUS}"
	fi
else
	kill -15 ${JOB_PID}
	gtk_fatal_error "The installation is cancelled!\n * RETURN_ZENITY: ${RETURN_ZENITY}"
fi
echo "winetricks -q settings fontsmooth=rgb DONE!"
#-------------------------------------------------
#-------------------------------------------------
echo "winetricks ${WINETRICKS_EXTRA_OPTION} -q dotnet48"
pipe="$(mktemp)"
rm -rf "${pipe}"
mkfifo "${pipe}"

$WORKDIR/winetricks "${WINETRICKS_EXTRA_OPTION}" -q dotnet48 > "${pipe}" &
JOB_PID="${!}"

zenity --progress --title="Winetricks dotnet48" --text="Winetricks installing DotNet v2.0, v4.0 and v4.8 update (It might take a while)..." --pulsate --auto-close < "${pipe}"
RETURN_ZENITY="${?}"
rm -rf "${pipe}"

if [ "${RETURN_ZENITY}" == "0" ] ; then
	wait "${JOB_PID}"
	JOB_STATUS="${?}"

	if [ "${JOB_STATUS}" != "0" ] ; then
		echo "ERROR on : winetricks ${WINETRICKS_EXTRA_OPTION} -q dotnet48; JOB_STATUS: ${JOB_STATUS}"
		gtk_fatal_error "The installation is cancelled because of sub-job failure!\n * winetricks -q dotnet48\n  - JOB_STATUS: ${JOB_STATUS}"
	fi
else
	kill -15 ${JOB_PID}
	gtk_fatal_error "The installation is cancelled!\n * RETURN_ZENITY: ${RETURN_ZENITY}"
fi
echo "winetricks -q dotnet48 DONE!"
#-------------------------------------------------

gtk_continue_question "Now the script will download and install Logos Bible on ${WINEPREFIX}. You will need to interact with the installer. Do you wish to continue?"

# Geting and install the LogosBible:
case "$WINEARCH" in
	win32)
		echo "Installing LogosBible 32bits..."
		if [ -f "${DOWNLOADED_RESOURCES}/${LOGOS_MSI}" ]; then
			echo "${LOGOS_MSI} exist. Using it..."
			cp "${DOWNLOADED_RESOURCES}/${LOGOS_MSI}" "${WORKDIR}/" | zenity --progress --title="Copying..." --text="Copying: ${LOGOS_MSI}\ninto: $WORKDIR" --pulsate --auto-close --no-cancel
		else
			echo "${LOGOS_MSI} does not exist. Downloading..."
			gtk_download "${LOGOS_URL}" "$WORKDIR"
		fi
		${WINE_EXE} msiexec /i "${WORKDIR}"/"${LOGOS_MSI}"
		create_starting_scripts_32
		;;
	win64)
		echo "Installing LogosBible 64bits..."
		if [ -f "${DOWNLOADED_RESOURCES}/${LOGOS64_MSI}" ]; then
			echo "${LOGOS64_MSI} exist. Using it..."
			cp "${DOWNLOADED_RESOURCES}/${LOGOS64_MSI}" "${WORKDIR}/" | zenity --progress --title="Copying..." --text="Copying: ${LOGOS64_MSI}\ninto: $WORKDIR" --pulsate --auto-close --no-cancel
		else
			echo "${LOGOS64_MSI} does not exist. Downloading..."
			gtk_download "${LOGOS64_URL}" "$WORKDIR"
		fi
		${WINE_EXE} msiexec /i "${WORKDIR}"/"${LOGOS64_MSI}"
		create_starting_scripts_64
		;;
	*)
		gtk_fatal_error "Installation failed!"
esac

if gtk_question "Do you want to clean the temp files?"; then
	clean_all
fi

if gtk_question "Logos Bible Installed!\nYou can run it using the script Logos.sh inside ${INSTALLDIR}.\nDo you want to run it now?\nNOTE: Just close the error on the first execution."; then
	"${INSTALLDIR}"/Logos.sh
fi

echo "End!"
exit 0
#==========================
