#!/bin/bash
WORKDIR="/tmp/workingLogosTemp"
APPDIR="$HOME/AppImage"
APPDIR_BIN="$APPDIR/bin"
APPIMAGE_NAME="wine-i386_x86_64-archlinux.AppImage"
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
		gtk_fatal_error "Update process cancelled!"
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
	wget -c "$1" -O "$TARGET" 2>&1 | while read -r data; do
		if [ "$(echo "$data" | grep '^Length:')" ]; then
			total_size=$(echo "$data" | grep "^Length:" | sed 's/.*\((.*)\).*/\1/' |  tr -d '()')
			if [ ${#total_size} -ge 10 ]; then total_size="Getting..." ; fi
		fi
		
		if [ "$(echo "$data" | grep '[0-9]*%' )" ];then
			percent=$(echo "$data" | grep -o "[0-9]*%" | tr -d '%')
			if [ ${#percent} -ge 3 ]; then percent="0" ; fi
			
			current=$(echo "$data" | grep "[0-9]*%" | sed 's/\([0-9BKMG]\+\).*/\1/' )
			if [ ${#current} -ge 10 ]; then current="Getting..." ; fi
			
			speed=$(echo "$data" | grep "[0-9]*%" | sed 's/.*\(% [0-9BKMG.]\+\).*/\1/' | tr -d ' %')
			if [ ${#speed} -ge 10 ]; then speed="Getting..." ; fi
			
			remain=$(echo "$data" | grep -o "[0-9A-Za-z]*$" )
			if [ ${#remain} -ge 10 ]; then remain="Getting..." ; fi
		fi
		
		# report
		echo "$percent"
		# shellcheck disable=SC2028
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

if have_dep md5sum; then
	echo '* command md5sum is installed!'
else
	gtk_fatal_error "Your system does not have command md5sum. Please install command md5sum package."
fi

echo "Starting Zenity GUI..."
#==========================

#======= Update =============
#==========================

#======= Main =============
export PATH=$APPDIR_BIN:$PATH

gtk_continue_question "This script will update the AppImage of wine for Logos Bible.\nDo you wish to continue?"

make_dir "$WORKDIR"

# Geting the new the AppImage zsync and compare the md5sum:
gtk_download "https://github.com/ferion11/Wine_Appimage/releases/download/continuous/wine-i386_x86_64-archlinux.AppImage.zsync" "$WORKDIR"

MD5SUM_OLD=$(md5sum "$APPDIR/$APPIMAGE_NAME.zsync" | cut -d " " -f1)
MD5SUM_NEW=$(md5sum "$WORKDIR/$APPIMAGE_NAME.zsync" | cut -d " " -f1)

if [ "$MD5SUM_OLD" = "$MD5SUM_NEW" ]; then
	gtk_info "You already have the latest version of wine's AppImage."
	clean_all
	echo "End!"
	exit 0
fi

# Geting the AppImage:
gtk_download "https://github.com/ferion11/Wine_Appimage/releases/download/continuous/wine-i386_x86_64-archlinux.AppImage" "$WORKDIR"
chmod +x "$WORKDIR/$APPIMAGE_NAME"

make_dir "$APPDIR"

rm -rf "${APPDIR:?}/${APPIMAGE_NAME}"
mv "$WORKDIR/$APPIMAGE_NAME" "$APPDIR" | zenity --progress --title="Moving..." --text="Moving: $APPIMAGE_NAME\ninto: $APPDIR" --pulsate --auto-close

rm -rf "$APPDIR/$APPIMAGE_NAME.zsync"
mv "$WORKDIR/$APPIMAGE_NAME.zsync" "$APPDIR" | zenity --progress --title="Moving..." --text="Moving: $APPIMAGE_NAME.zsync\ninto: $APPDIR" --pulsate --auto-close

wine wineboot | zenity --progress --title="Wineboot" --text="Wine is updating $WINEDIR..." --pulsate --auto-close
gtk_info "Update complete!"

echo "End!"
exit 0
#==========================
