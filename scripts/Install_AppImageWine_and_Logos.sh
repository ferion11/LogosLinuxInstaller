#!/bin/bash
# version of Logos from: https://wiki.logos.com/The_Logos_8_Beta_Program
LOGOS_URL="https://downloads.logoscdn.com/LBS8/Installer/8.15.0.0004/Logos-x86.msi"
LOGOS_MVERSION=$(echo $LOGOS_URL | cut -d/ -f4)
LOGOS_VERSION=$(echo $LOGOS_URL | cut -d/ -f6)
WORKDIR="/tmp/workingLogosTemp"
APPDIR="$HOME/AppImage"
APPDIR_BIN="$APPDIR/bin"
APPIMAGE_NAME="wine-i386_x86_64-archlinux.AppImage"
#WINEDIR=~/.wine32
WINEDIR="$HOME/.wine32"

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
	echo "End!"
	exit 1
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

	pipe="/tmp/.pipe__gtk_download__function"
	rm -rf $pipe
	mkfifo $pipe

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
		# shellcheck disable=SC2028
		echo "#Downloading: $FILENAME\ninto: $2\n\n$current of $total_size ($percent%)\nSpeed : $speed/Sec\nEstimated time : $remain"
	done > $pipe &

	zenity --progress --title "Downloading $FILENAME..." --text="Downloading: $FILENAME\ninto: $2\n" --percentage=0 --auto-close --auto-kill < $pipe

	if [ "$?" = -1 ] ; then
		#pkill -15 wget
		killall -15 wget
		rm -rf $pipe
		gtk_fatal_error "The installation is cancelled!"
	fi

	rm -rf $pipe
}

#--------------
#==========================

#======= Basic Deps =============
echo 'Searching for dependencies:'

if [ -z "$DISPLAY" ]; then
	echo "* You want to run without X, but it don't work."
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
	gtk_fatal_error "Your system does not have wget. Please install wget package."
fi

if have_dep find; then
	echo '* command find is installed!'
else
	gtk_fatal_error "Your system does not have command find. Please install command find package."
fi

if have_dep sed; then
	echo '* command sed is installed!'
else
	gtk_fatal_error "Your system does not have command sed. Please install command sed package."
fi

if have_dep grep; then
	echo '* command grep is installed!'
else
	gtk_fatal_error "Your system does not have command grep. Please install command grep package."
fi

echo "Starting Zenity GUI..."
#==========================

#======= Main =============

gtk_continue_question "This script will download and install the AppImage of wine, configure, and install Logos Bible v$LOGOS_VERSION. Do you wish to continue?"

mkdir -p "$WORKDIR"

# Geting the AppImage:
FILE="$APPDIR/$APPIMAGE_NAME"
if [ -f "$FILE" ]; then
	echo "$FILE exist. Using it..."
else 
	echo "$FILE does not exist. Downloading..."
	gtk_download "https://github.com/ferion11/Wine_Appimage/releases/download/continuous/wine-i386_x86_64-archlinux.AppImage" "$WORKDIR"
	chmod +x "$WORKDIR/$APPIMAGE_NAME"
	
	mkdir -p "$APPDIR"
	mv "$WORKDIR/$APPIMAGE_NAME" "$APPDIR" | zenity --progress --title="Moving..." --text="Moving: $APPIMAGE_NAME\ninto: $APPDIR" --pulsate --auto-close
	
	gtk_download "https://github.com/ferion11/Wine_Appimage/releases/download/continuous/wine-i386_x86_64-archlinux.AppImage.zsync" "$WORKDIR"
	mv "$WORKDIR/$APPIMAGE_NAME.zsync" "$APPDIR" | zenity --progress --title="Moving..." --text="Moving: $APPIMAGE_NAME.zsync\ninto: $APPDIR" --pulsate --auto-close
fi

# Making the links (and dir)
if ! [ -d "$APPDIR_BIN" ] ; then
	mkdir -p "$APPDIR_BIN"
	ln -s "$FILE" "$APPDIR_BIN/wine"
	ln -s "$FILE" "$APPDIR_BIN/wineserver"
fi

gtk_continue_question "Now the script will create, if you don't have, one Wine Bottle in $WINEDIR. You can cancel the instalation of Mono, because we will install the MS DotNet. Do you wish to continue?"

export PATH=$APPDIR_BIN:$PATH
wine wineboot | zenity --progress --title="Wineboot" --text="Wine is updating $WINEDIR..." --pulsate --auto-close

cat > $WORKDIR/disable-winemenubuilder.reg << EOF
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"winemenubuilder.exe"=""


EOF

cat > $WORKDIR/renderer_gdi.reg << EOF
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"DirectDrawRenderer"="gdi"
"renderer"="gdi"


EOF

wine regedit.exe $WORKDIR/disable-winemenubuilder.reg | zenity --progress --title="Wine regedit" --text="Wine is blocking in $WINEDIR:\nfiletype associations, add menu items, or create desktop links" --pulsate --auto-close
wine regedit.exe $WORKDIR/renderer_gdi.reg | zenity --progress --title="Wine regedit" --text="Wine is changing the renderer to gdi:\nthe old DirectDrawRenderer and the new renderer keys" --pulsate --auto-close

gtk_continue_question "Now the script will install the winetricks packages in your $WINEDIR. You will need to interact with some of these installers. Do you wish to continue?"

gtk_download "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" "$WORKDIR"
chmod +x "$WORKDIR/winetricks"

env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks ddr=gdi | zenity --progress --title="Winetricks" --text="Winetricks setting ddr=gdi..." --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks settings fontsmooth=rgb | zenity --progress --title="Winetricks" --text="Winetricks setting fontsmooth=rgb..." --pulsate --auto-close

env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks andale | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (01/21) andale" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks arial | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (02/21) arial" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks calibri | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (03/21) calibri" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks cambria | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (04/21) cambria" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks candara | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (05/21) candara" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks comicsans | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (06/21) comicsans" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks consolas | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (07/21) consolas" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks constantia | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (08/21) constantia" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks corbel | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (09/21) corbel" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks courier | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (10/21) courier" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks georgia | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (11/21) georgia" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks impact | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (12/21) impact" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks times | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (13/21) times" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks trebuchet | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (14/21) trebuchet" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks verdana | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (15/21) verdana" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks webdings | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (16/21) webdings" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks corefonts | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (17/21) corefonts" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks eufonts | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (18/21) eufonts" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks lucida | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (19/21) lucida" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks meiryo | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (20/21) meiryo" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks tahoma | zenity --progress --title="Winetricks" --text="Winetricks installing fonts... (21/21) tahoma" --pulsate --auto-close

env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks dotnet40 | zenity --progress --title="Winetricks" --text="Winetricks installing DotNet 4.0...\nNOTE: Will need interaction" --pulsate --auto-close
env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks dotnet48 | zenity --progress --title="Winetricks" --text="Winetricks installing DotNet 4.8 update...\nNOTE: Will need interaction" --pulsate --auto-close

gtk_continue_question "Now the script will download and install Logos Bible in your $WINEDIR. You will need to interact with the installer. Do you wish to continue?"

gtk_download "${LOGOS_URL}" "$WORKDIR"

wine msiexec /i $WORKDIR/Logos-x86.msi | zenity --progress --title="Logos Bible Installer" --text="Starting the Logos Bible Installer...\nNOTE: Will need interaction" --pulsate --auto-close

#------- making the start script -------
IFS_TMP=$IFS
IFS=$'\n'
LOGOS_EXE=$(find $HOME/.wine32 -name Logos.exe |  grep "Logos\/Logos.exe")
rm -rf $WORKDIR/Logos.sh

cat > $WORKDIR/Logos.sh << EOF
#!/bin/bash
export PATH=$APPDIR_BIN:\$PATH
# Save IFS
IFS_TMP=\$IFS
IFS=$'\n'

wine "$LOGOS_EXE"

# restore IFS
IFS=\$IFS_TMP
EOF

chmod +x $WORKDIR/Logos.sh
IFS=$IFS_TMP
#------------------------------

mkdir -p "$HOME/Desktop"
mv $WORKDIR/Logos.sh $HOME/Desktop

#env WINEPREFIX=$WINEDIR sh $WORKDIR/winetricks winxp

if gtk_question "Do you want to clean the temp files?"; then
	clean_all
fi

if gtk_question "Logos Bible Installed!\nYou can run it from the script Logos.sh on your Desktop.\nDo you want to run it now?\nNOTE: Just close the error on the first execution."; then
	$HOME/Desktop/Logos.sh
fi

echo "End!"
exit 0
#==========================
