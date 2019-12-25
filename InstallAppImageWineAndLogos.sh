#!/bin/bash
LOGOS_MVERSION="LBS8"
LOGOS_VERSION="8.10.0.0032"
WORKDIR="/tmp/workingLogosTemp"
APPDIR="$HOME/AppImage"

#======= Aux =============
havedep() {
    command -v "$1" >/dev/null 2>&1
}

clean_all() {
}

#zenity------
gtk_info() {
    zenity --info --width=300 --height=200 --text="$@" --title='Information'
}
gtk_warn() {
    zenity --warning --width=300 --height=200 --text="$@" --title='Warning!'
}
gtk_error() {
    zenity --error --width=300 --height=200 --text="$@" --title='Error!'
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
    # $3	title part of what is downloading
    # NOTE: here must be limitation to handle it easily. $2 can be dir, if it already exists or if it ends with '/'
  
    if [ "$2" != "${2%/}" ]; then
        # it has '/' at the end or it is existing directory
        TARGET="$2/${1##*/}"
        [ -d "$2" ] || mkdir -p "$2" || error "Cannot create $2"
    elif [ -d "$2" ]; then
        # it's existing directory
        TARGET="$2/${1##*/}"
    else
        # $2 is file
        TARGET="$2"
        # ensure that directory, where the target file will be exists
        [ -d "${2%/*}" ] || mkdir -p "${2%/*}" || $error "Cannot create directory ${2%/*}"
    fi
    
    # download with output to dialog progress bar
    ( wget -c "$1" -O "$TARGET" -o /dev/stdout | while read I; do
        I="${I//*.......... .......... .......... .......... .......... /}"
        I="${I%%%*}"
        # report changes only
        if [ "$I" ] && [ "$J" != "$I" ]; then
            echo "$I"
            J="$I"
        fi      
    done | zenity --title "Downloading $3..." --progress --text="Downloading:\n$1\n\ninto:\n$2" --auto-close --auto-kill )
}

testeBar() {
    # Dummy tests
    (
        echo 25
        echo "# Setting up..."
        sleep 2
        
        echo 30
        echo "# Reading files..."
        sleep 2
        
        echo 70
        echo "# Creating content..."
        sleep 1
        
        echo 100
        echo "# Done!"
    ) | zenity --width=400 --height=100 --title "Progress bar example" --progress --auto-kill
}
#--------------
#==========================

#======= Basic Deps =============
echo 'Searching for dependencies:'

if [ -z "$DISPLAY" ]; then
    echo "You want to run without X, but it don't work."
    exit 1
fi

if havedep zenity; then
    echo 'Zenity is installed!'
else
    echo 'Your system does not have Zenity. Please install Zenity package.'
    exit 1
fi

echo "Starting Zenity GUI..."
#==========================

#======= Devs =============

gtk_continue_question "This script will download and install the AppImage of wine, configure, and install Logos Bible v$LOGOS_VERSION. Do you wish to continue?"

#TODO: remove the exit 0
echo "End!"
exit 0


#showInfo "Testando erro para ver se tamanho eh adequado ao requerido pelo script"
gtk_download "https://github.com/ferion11/Wine_Appimage/releases/download/continuous/wine-i386_x86_64-archlinux.AppImage" "/tmp" "WineAppimage"


echo "WORKDIR: $WORKDIR"
echo "APPDIR: $APPDIR"

echo "End!"
exit 0


mkdir $WORK
cd $WORK
#==========================
