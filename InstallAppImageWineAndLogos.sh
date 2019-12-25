#!/bin/bash
LOGOS_MVERSION="LBS8"
LOGOS_VERSION="8.10.0.0032"
WORKDIR="/tmp/workingLogosTemp"
APPDIR="$HOME/AppImage"
APPDIR_BIN="$APPDIR/bin"
APPIMAGE_NAME="wine-i386_x86_64-archlinux.AppImage"
WINEDIR="$HOME/.wine32"

#======= Aux =============
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
    # NOTE: here must be limitation to handle it easily. $2 can be dir, if it already exists or if it ends with '/'
    
    URI="$1"
    FILENAME="${URI##*/}"                   # extract last field of URI as filename
    
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
    done ) | zenity --progress --title "Downloading $FILENAME..." --text="Downloading:\n$1\n\ninto:\n$2" --percentage=0 --auto-close --auto-kill
    
    if [ "$?" = -1 ] ; then
        pkill -9 wget
        gtk_fatal_error "The installation is cancelled!"
    fi
}

#--------------
#==========================

#======= Basic Deps =============
echo 'Searching for dependencies:'

if [ -z "$DISPLAY" ]; then
    echo "You want to run without X, but it don't work."
    exit 1
fi

if have_dep zenity; then
    echo '* Zenity is installed!'
else
    echo 'Your system does not have Zenity. Please install Zenity package.'
    exit 1
fi

if have_dep wget; then
    echo '* wget is installed!'
else
    gtk_fatal_error "Your system does not have wget. Please install wget package."
fi

echo "Starting Zenity GUI..."
#==========================

#======= Devs =============

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
    mv "$WORKDIR/$APPIMAGE_NAME" "$APPDIR"
fi

# Making the links (and dir)
if ! [ -d "$APPDIR_BIN" ] ; then
    make_dir "$APPDIR_BIN"
    ln -s "$FILE" "$APPDIR_BIN/wine"
    ln -s "$FILE" "$APPDIR_BIN/wineserver"
fi

gtk_continue_question "Now the script will create, if you don't have, one Wine Bottle in ~/.wine32. You can cancel the instalation of Mono, because we will install the MS DotNet. Do you wish to continue?"

export PATH=$APPDIR_BIN:$PATH
wine wineboot

gtk_continue_question "Now the script will install the winetricks packages in your ~/.wine32. You will need to interact with some of these installers. Do you wish to continue?"

gtk_download "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" "$WORKDIR"
chmod +x "$WORKDIR/winetricks"

env WINEPREFIX=~/.wine32 sh $WORKDIR/winetricks ddr=gdi
env WINEPREFIX=~/.wine32 sh $WORKDIR/winetricks settings fontsmooth=rgb
env WINEPREFIX=~/.wine32 sh $WORKDIR/winetricks andale arial calibri cambria candara comicsans consolas constantia corbel courier georgia impact times trebuchet verdana webdings corefonts eufonts lucida meiryo tahoma
env WINEPREFIX=~/.wine32 sh $WORKDIR/winetricks dotnet48

gtk_continue_question "Now the script will download and install Logos Bible in your ~/.wine32. You will need to interact with the installer. Do you wish to continue?"

gtk_download "https://downloads.logoscdn.com/LBS8/Installer/8.10.0.0032/Logos-x86.msi" "$WORKDIR"

LC_ALL=C wine msiexec /i $WORKDIR/Logos-x86.msi

#------- making the start script -------
IFS_TMP=$IFS
IFS=$'\n'
LOGOS_EXE=$(find $HOME/.wine32 -name Logos.exe |  grep "Logos\/Logos.exe")
rm -rf $WORKDIR/Logos.sh

cat > $WORKDIR/Logos.sh << EOF
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

env WINEPREFIX=~/.wine32 sh $WORKDIR/winetricks winxp

if gtk_question "Do you want to clean the temp files?"; then
    clean_all
fi

gtk_info "Logos Bible Installed. You can run it from the script Logos.sh on your Desktop."

echo "End!"
exit 0
#==========================
