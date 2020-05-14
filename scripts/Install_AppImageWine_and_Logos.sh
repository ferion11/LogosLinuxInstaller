#!/bin/bash
# version of Logos from: https://wiki.logos.com/The_Logos_8_Beta_Program
LOGOS_MVERSION="LBS8"
LOGOS_VERSION="8.13.0.0008"
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

make_dir() {
	[ ! -d "$1" ] && mkdir "$1"
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
	FILENAME="${URI##*/}"                   # extract last field of URI as filename
	
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
	
	pipe="/tmp/.pipe__gtk_download__function"
	rm -rf $pipe
	mkfifo $pipe
	
	# download with output to dialog progress bar
	wget -c "$1" -O "$TARGET" 2>&1 | while read data; do
		if [ "`echo $data | grep '^Length:'`" ]; then
			total_size=`echo $data | grep "^Length:" | sed 's/.*\((.*)\).*/\1/' |  tr -d '()'`
			if [ ${#total_size} -ge 10 ]; then total_size="Getting..." ; fi
		fi
	
		if [ "`echo $data | grep '[0-9]*%' `" ];then
			percent=`echo $data | grep -o "[0-9]*%" | tr -d '%'`
			if [ ${#percent} -ge 3 ]; then percent="0" ; fi
			
			current=`echo $data | grep "[0-9]*%" | sed 's/\([0-9BKMG]\+\).*/\1/' `
			if [ ${#current} -ge 10 ]; then current="Getting..." ; fi
			
			speed=`echo $data | grep "[0-9]*%" | sed 's/.*\(% [0-9BKMG.]\+\).*/\1/' | tr -d ' %'`
			if [ ${#speed} -ge 10 ]; then speed="Getting..." ; fi
			
			remain=`echo $data | grep -o "[0-9A-Za-z]*$" `
			if [ ${#remain} -ge 10 ]; then remain="Getting..." ; fi
		fi
		
		# report
		echo "$percent"
		echo "#Downloading: $1\ninto: $2\n\n$current of $total_size ($percent%)\nSpeed : $speed/Sec\nEstimated time : $remain"
		
	done > $pipe &
	
	zenity --progress --title "Downloading $FILENAME..." --text="Downloading: $1\ninto: $2\n" --percentage=0 --auto-close --auto-kill < $pipe
	
	if [ "$?" = -1 ] ; then
		pkill -9 wget
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

make_dir "$WORKDIR"

# Geting the AppImage:
FILE="$APPDIR/$APPIMAGE_NAME"
if [ -f "$FILE" ]; then
	echo "$FILE exist. Using it..."
else 
	echo "$FILE does not exist. Downloading..."
	gtk_download "https://github.com/ferion11/Wine_Appimage/releases/download/continuous/wine-i386_x86_64-archlinux.AppImage" "$WORKDIR"
	chmod +x "$WORKDIR/$APPIMAGE_NAME"
	
	make_dir "$APPDIR"
	mv "$WORKDIR/$APPIMAGE_NAME" "$APPDIR" | zenity --progress --title="Moving..." --text="Moving: $APPIMAGE_NAME\ninto: $APPDIR" --pulsate --auto-close
	
	gtk_download "https://github.com/ferion11/Wine_Appimage/releases/download/continuous/wine-i386_x86_64-archlinux.AppImage.zsync" "$WORKDIR"
	mv "$WORKDIR/$APPIMAGE_NAME.zsync" "$APPDIR" | zenity --progress --title="Moving..." --text="Moving: $APPIMAGE_NAME.zsync\ninto: $APPDIR" --pulsate --auto-close
fi

# Making the links (and dir)
if ! [ -d "$APPDIR_BIN" ] ; then
	make_dir "$APPDIR_BIN"
	ln -s "$FILE" "$APPDIR_BIN/wine"
	ln -s "$FILE" "$APPDIR_BIN/wineserver"
fi

gtk_continue_question "Now the script will create, if you don't have, one Wine Bottle in $WINEDIR. You can cancel the instalation of Mono, because we will install the MS DotNet. Do you wish to continue?"

export PATH=$APPDIR_BIN:$PATH
wine wineboot | zenity --progress --title="Wineboot" --text="Wine is updating $WINEDIR..." --pulsate --auto-close

cat > $WORKDIR/disable-winemenubuilder.reg << EOF
[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"winemenubuilder.exe"=""
EOF

wine regedit.exe $WORKDIR/disable-winemenubuilder.reg | zenity --progress --title="Wine regedit" --text="Wine is blocking in $WINEDIR:\nfiletype associations, add menu items, or create desktop links" --pulsate --auto-close

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

gtk_download "https://downloads.logoscdn.com/$LOGOS_MVERSION/Installer/$LOGOS_VERSION/Logos-x86.msi" "$WORKDIR"

LC_ALL=C wine msiexec /i $WORKDIR/Logos-x86.msi | zenity --progress --title="Logos Bible Installer" --text="Starting the Logos Bible Installer...\nNOTE: Will need interaction" --pulsate --auto-close

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

LC_ALL=C wine "$LOGOS_EXE"

# restore IFS
IFS=\$IFS_TMP
EOF

chmod +x $WORKDIR/Logos.sh
IFS=$IFS_TMP
#------------------------------

make_dir "$HOME/Desktop"
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
