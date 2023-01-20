#!/bin/bash
# shellcheck disable=SC2317
LOGOS_RELEASE_VERSION="10.1.0.0056"
LOGOS_SCRIPT_TITLE="Logos Linux Installer" # From https://github.com/ferion11/LogosLinuxInstaller
export LOGOS_SCRIPT_AUTHOR="Ferion11, John Goodman, T. H. Wright"
export LOGOS_SCRIPT_VERSION="${LOGOS_RELEASE_VERSION}-v6" # Script version to match FaithLife Product version.

#####
# Originally written by Ferion11.
# Modified to install Logoos 10 by Revd. John Goodman M0RVJ
# Made script agnostic to Logos and Verbum as well as version; modified script for and added several optargs; and general code refactoring by Revd. T. H. Wright
#####

# BEGIN ENVIRONMENT
if [ -z "${WINE64_APPIMAGE_FULL_VERSION}" ]; then WINE64_APPIMAGE_FULL_VERSION="v7.18-staging"; export WINE64_APPIMAGE_FULL_VERSION; fi
if [ -z "${WINE64_APPIMAGE_FULL_URL}" ]; then WINE64_APPIMAGE_FULL_URL="https://github.com/ferion11/LogosLinuxInstaller/releases/download/v10.0-1/wine-staging_7.18-x86_64.AppImage"; export WINE64_APPIMAGE_FULL_URL; fi
if [ -z "${WINE64_APPIMAGE_FULL_FILENAME}" ]; then WINE64_APPIMAGE_FULL_FILENAME="$(basename "${WINE64_APPIMAGE_FULL_URL}")"; export WINE64_APPIMAGE_FULL_FILENAME; fi
if [ -z "${WINE64_APPIMAGE_VERSION}" ]; then WINE64_APPIMAGE_VERSION="v7.18-staging"; export WINE64_APPIMAGE_VERSION; fi
if [ -z "${WINE64_APPIMAGE_URL}" ]; then WINE64_APPIMAGE_URL="https://github.com/ferion11/LogosLinuxInstaller/releases/download/v10.0-1/wine-staging_7.18-x86_64.AppImage"; export WINE64_APPIMAGE_URL; fi
if [ -z "${WINE64_APPIMAGE_FILENAME}" ]; then WINE64_APPIMAGE_FILENAME="$(basename "${WINE64_APPIMAGE_URL}" .AppImage)"; export WINE64_APPIMAGE_FILENAME; fi
if [ -z "${APPIMAGE_LINK_SELECTION_NAME}" ]; then APPIMAGE_LINK_SELECTION_NAME="selected_wine.AppImage"; export APPIMAGE_LINK_SELECTION_NAME; fi
if [ -z "${WINETRICKS_URL}" ]; then WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/5904ee355e37dff4a3ab37e1573c56cffe6ce223/src/winetricks"; export WINETRICKS_URL; fi
if [ -z "${LAUNCHER_TEMPLATE_URL}" ]; then LAUNCHER_TEMPLATE_URL="https://raw.githubusercontent.com/thw26/LogosLinuxInstaller/backup-and-restore/Launcher-Template.sh"; export LAUNCHER_TEMPLATE_URL; fi
if [ -z "${CONTROL_PANEL_TEMPLATE_URL}" ]; then CONTROL_PANEL_TEMPLATE_URL="https://raw.githubusercontent.com/thw26/LogosLinuxInstaller/backup-and-restore/controlPanel-Template.sh"; export CONTROL_PANEL_TEMPLATE_URL; fi
if [ -z "${WINETRICKS_DOWNLOADER+x}" ]; then WINETRICKS_DOWNLOADER="wget" ; export WINETRICKS_DOWNLOADER; fi
if [ -z "${WINETRICKS_UNATTENDED+x}" ]; then WINETRICKS_UNATTENDED="" ; export WINETRICKS_UNATTENDED; fi
if [ -z "${WORKDIR}" ]; then WORKDIR="$(mktemp -d /tmp/LBS.XXXXXXXX)"; export WORKDIR ; fi
if [ -z "${PRESENT_WORKING_DIRECTORY}" ]; then PRESENT_WORKING_DIRECTORY="${PWD}" ; export PRESENT_WORKING_DIRECTORY; fi
if [ -z "${LOGOS_FORCE_ROOT+x}" ]; then export LOGOS_FORCE_ROOT="" ; fi
if [ -z "${WINEBOOT_GUI+x}" ]; then export WINEBOOT_GUI="" ; fi
if [ -z "${EXTRA_INFO}" ]; then EXTRA_INFO="The following packages are usually necessary: winbind cabextract libjpeg8."; export EXTRA_INFO; fi
if [ -z "${DEFAULT_CONFIG_PATH}" ]; then DEFAULT_CONFIG_PATH="${HOME}/.config/Logos_on_Linux/Logos_on_Linux.conf"; export DEFAULT_CONFIG_PATH; fi
if [ -z "${WINEDEBUG}" ]; then WINEDEBUG="fixme-all,err-all"; fi; export WINEDEBUG # Make wine output less verbose
# END ENVIRONMENT
# BEGIN FUNCTION DECLARATIONS
usage() {
cat << EOF
$LOGOS_SCRIPT_TITLE, by $LOGOS_SCRIPT_AUTHOR, $LOGOS_SCRIPT_VERSION.

Usage: ./LogosLinuxInstaller.sh
Installs ${FLPRODUCT} Bible Software with Wine on Linux.

Options:
    -h   --help                 Prints this help message and exit.
    -v   --version              Prints version information and exit.
    -D   --debug                Makes Wine print out additional info.
    -c   --config               Use the Logos on Linux config file when
                                setting environment variables. Defaults to:
                                \$HOME/.config/Logos_on_Linux/Logos_on_Linux.conf
                                Optionally can accept a config file provided by
                                the user.
    -r   --regenerate-scripts   Regenerates the Logos.sh and controlPanel.sh
                                scripts using the config file.
    -F   --skip-fonts           Skips installing corefonts and tahoma.
    -f   --force-root           Sets LOGOS_FORCE_ROOT to true, which permits
                                the root user to run the script.
EOF
}

die-if-root() {
	if [ "$(id -u)" -eq '0' ] && [ -z "${LOGOS_FORCE_ROOT}" ]; then
		echo "* Running Wine/winetricks as root is highly discouraged. Use -f|--force-root if you must run as root. See https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.3F"
		gtk_fatal_error "Running Wine/winetricks as root is highly discouraged. Use -f|--force-root if you must run as root. See https://wiki.winehq.org/FAQ#Should_I_run_Wine_as_root.3F"
	fi
}

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
	${WINESERVER_EXE} -w | zenity --progress --title="Waiting for ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to end properly…" --pulsate --auto-close --no-cancel
}

heavy_wineserver_wait() {
	echo "* Waiting for ${WINE_EXE} to end properly…"
	wait_process_using_dir "${WINEPREFIX}" | zenity --progress --title="Waiting ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to end properly…" --pulsate --auto-close --no-cancel
	${WINESERVER_EXE} -w | zenity --progress --title="Waiting for ${WINE_EXE} proper end" --text="Waiting for ${WINE_EXE} to end properly…" --pulsate --auto-close --no-cancel
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

make_skel() {
# ${1} - SET_APPIMAGE_FILENAME
	export SET_APPIMAGE_FILENAME="${1}"

	echo "* Making skel64 inside ${INSTALLDIR}"
	mkdir -p "${INSTALLDIR}"
	mkdir "${APPDIR}" || die "can't make dir: ${APPDIR}"
	mkdir "${APPDIR_BINDIR}" || die "can't make dir: ${APPDIR_BINDIR}"

	# Making the links
	cd "${APPDIR_BINDIR}" || die "ERROR: Can't open dir: ${APPDIR_BINDIR}"
	ln -s "${SET_APPIMAGE_FILENAME}" "${APPDIR_BINDIR}/${APPIMAGE_LINK_SELECTION_NAME}"
	ln -s "${APPIMAGE_LINK_SELECTION_NAME}" wine
	ln -s "${APPIMAGE_LINK_SELECTION_NAME}" wine64
	ln -s "${APPIMAGE_LINK_SELECTION_NAME}" wineserver
	cd - || die "ERROR: Can't go back to preview dir!"

	mkdir "${APPDIR}/wine64_bottle"
	
	echo "skel64 done!"
}

# TODO: Move this to a CLI optarg.

#	#======= Parsing =============
#	case "${1}" in
#		"skel64")
#			export WINE_EXE="wine64"
#			make_skel "${WINE_EXE}" "none.AppImage"
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
			echo "* command ${cmd} not installed!"
			MISSING_CMD+=("${cmd}")
        fi
    done
	if [ "${#MISSING_CMD[@]}" -ne 0 ]; then
		echo "Your system is missing ${MISSING_CMD[*]}. Please install your distro's ${MISSING_CMD[*]} packages."
		gtk_fatal_error "Your system is missing ${MISSING_CMD[*]}. Please install your distro's ${MISSING_CMD[*]} package(s).\n ${EXTRA_INFO}"
	fi
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

checkDependencies() {
	echo "================================================="
	echo "Checking system's for dependencies:"

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

	check_commands mktemp patch lsof wget find sed grep ntlm_auth awk tr;
}

checkDependenciesLogos10() {
	echo "All dependencies found. Continuing…"
}

checkDependenciesLogos9() {
	echo "Checking dependencies for Logos 9."
	check_commands xwd cabextract;
	echo "All dependencies found. Continuing…"
}
## END CHECK DEPENDENCIES FUNCTIONS

## BEGIN INSTALL OPTIONS FUNCTIONS
chooseProduct() {
	if [ -z "${FLPRODUCT}" ]; then
	productChoice="$(zenity --width=700 --height=310 \
		--title="Question: Should the script install Logos or Verbum?" \
		--text="Choose which FaithLife product to install:." \
		--list --radiolist --column "S" --column "Description" \
		TRUE "Logos Bible Software." \
		FALSE "Verbum Bible Software." \
		FALSE "Exit." )"
	else
		productChoice="${FLPRODUCT}"
	fi

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
			export VERBUM_PATH="Verbum/"
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
	if [ -z "$TARGETVERSION" ]; then
		versionChoice="$(zenity --width=700 --height=310 \
		--title="Question: Which version of ${FLPRODUCT} should the script install?" \
		--text="Choose which FaithLife product to install:." \
		--list --radiolist --column "S" --column "Description" \
		TRUE "${FLPRODUCT} 10" \
		FALSE "${FLPRODUCT} 9" \
		FALSE "Exit." )"
	else
		versionChoice="$TARGETVERSION"
	fi
	case "${versionChoice}" in
		*"10")
			checkDependenciesLogos10;
			export TARGETVERSION="10";
			if [ -z "${LOGOS64_URL}" ]; then export LOGOS64_URL="https://downloads.logoscdn.com/LBS10/${VERBUM_PATH}Installer/${LOGOS_RELEASE_VERSION}/${FLPRODUCT}-x64.msi" ; fi
			;;
		*"9")
			checkDependenciesLogos9;
			export TARGETVERSION="9";
			if [ -z "${LOGOS64_URL}" ]; then export LOGOS64_URL="https://downloads.logoscdn.com/LBS9/${VERBUM_PATH}Installer/9.17.0.0010/${FLPRODUCT}-x64.msi" ; fi
			;;
		"Exit.")
			exit
			;;
		*)
			gtk_fatal_error "Installation canceled!"
	esac

	if [ "${FLPRODUCT}" = "Logos" ]; then
		LOGOS_VERSION="$(echo "${LOGOS64_URL}" | cut -d/ -f6)"; 
	elif [ "${FLPRODUCT}" = "Verbum" ]; then
		LOGOS_VERSION="$(echo "${LOGOS64_URL}" | cut -d/ -f7)"; 
	else
		echo "FLPRODUCT not set in config. Please update your config to specify either 'Logos' or 'Verbum'. Installation canceled!"
		gtk_fatal_error "FLPRODUCT not set in config. Please update your config to specify either 'Logos' or 'Verbum'."
	fi
	export LOGOS_VERSION;
	LOGOS64_MSI="$(basename "${LOGOS64_URL}")"; export LOGOS64_MSI

	if [ -z "${INSTALLDIR}" ]; then
		export INSTALLDIR="${HOME}/${FLPRODUCT}Bible${TARGETVERSION}" ;
	fi
	if [ -z "${APPDIR}" ]; then
		export APPDIR="${INSTALLDIR}/data"
	fi
	if [ -z "${APPDIR_BINDIR}" ]; then
		export APPDIR_BINDIR="${APPDIR}/bin"
	fi

	if [ -d "${INSTALLDIR}" ] && [ -z "${REGENERATE}" ] ; then
		echo "A directory already exists at ${INSTALLDIR}. Please remove/rename it or use another location by setting the INSTALLDIR variable"
		gtk_fatal_error "a directory already exists at ${INSTALLDIR}. Please remove/rename it or use another location by setting the INSTALLDIR variable"
	fi              
}

wineBinaryVersionCheck() {
	# Does not check for Staging. Will not implement: expecting merging of commits in time.
	TESTBINARY="${1}"

	if [ "${TARGETVERSION}" == "10" ]; then
		WINE_MINIMUM="7.18"
	elif [ "${TARGETVERSION}" == "9" ]; then
		WINE_MINIMUM="7.0"
	else
		echo "TARGETVERSION not set."
		#gtk_fatal_error "TARGETVERSION not set."
	fi

	# Check if the binary is executable, of if TESTBINARY's version is ≥ WINE_MINIMUM, or if it is Proton, else remove.
	if [ -x "${TESTBINARY}" ]; then
		TESTWINEVERSION=$("$TESTBINARY" --version | awk -F' ' '{print $1}' | awk -F'-' '{print $2}');
		if (( $(echo "$TESTWINEVERSION >= $WINE_MINIMUM" | bc -l) )); then
			return 0;
		elif [[ ${TESTBINARY} =~ .*"Proton - Experimental".* ]]; then
			return 0;
		# If it is a symlink, check its actual path. If it is Proton, let it pass.
		elif [ -L "${TESTBINARY}" ]; then
			TESTWINE=$(readlink -f "$TESTBINARY")
			if [[ "${TESTWINE}" =~ .*"Proton - Experimental".* ]]; then
				return 0;
			fi
		else
			return 1;
		fi
	fi
}

checkPath() {
	IFS=:
	for dir in $PATH; do
		if [ -x "$dir/$1" ]; then
			echo "$dir/$1"
		fi
	done

}

createWineBinaryList() {
	#TODO: Make optarg to add custom path to this array.
	WINEBIN_PATH_ARRAY=( "/usr/local/bin" "$HOME/bin" "$HOME/PlayOnLinux/wine/linux-amd64/*/bin" "$HOME/.steam/steam/steamapps/common/Proton - Experimental/files/bin" )

	# Temporarily modify PATH for additional WINE64 binaries.
	for p in "${WINEBIN_PATH_ARRAY[@]}"; do
		if [[ ":$PATH:" != *":${p}:"* ]] && [ -d "${p}" ]; then
			PATH="$PATH:${p}"
		fi
	done

	# Check each directory in PATH for wine64; add to list
	checkPath wine64 > "${WORKDIR}/winebinaries"

	cp "${WORKDIR}/winebinaries" "${WORKDIR}/winebinaries.bak"

	# Check remaining binary versions
	while read -r i; do
		if wineBinaryVersionCheck "$i"; then
			# Skip
			:
		else
			sed -i "\@$i@d" "${WORKDIR}/winebinaries"
		fi
	done < "${WORKDIR}/winebinaries.bak";
}

getAppImage() {
	if [ -f "${PRESENT_WORKING_DIRECTORY}/${WINE64_APPIMAGE_FULL_FILENAME}" ]; then
    	echo "${WINE64_APPIMAGE_FULL_FILENAME} exists. Using it…"
    	cp "${PRESENT_WORKING_DIRECTORY}/${WINE64_APPIMAGE_FULL_FILENAME}" "${APPDIR_BINDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${WINE64_APPIMAGE_FULL_FILENAME}\ninto: ${APPDIR_BINDIR}" --pulsate --auto-close --no-cancel
	elif [ -f "${HOME}/Downloads/${WINE64_APPIMAGE_FULL_FILENAME}" ]; then
    	echo "${WINE64_APPIMAGE_FULL_FILENAME} exists. Using it…"
    	cp "${HOME}/Downloads/${WINE64_APPIMAGE_FULL_FILENAME}" "${APPDIR_BINDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${WINE64_APPIMAGE_FULL_FILENAME}\ninto: ${APPDIR_BINDIR}" --pulsate --auto-close --no-cancel
	else
    	echo "${WINE64_APPIMAGE_FULL_FILENAME} does not exist. Downloading…"
    	gtk_download "${WINE64_APPIMAGE_FULL_URL}" "${HOME}/Downloads/${WINE64_APPIMAGE_FULL_FILENAME}"
    	cp "${HOME}/Downloads/${WINE64_APPIMAGE_FULL_FILENAME}" "${APPDIR_BINDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${WINE64_APPIMAGE_FULL_FILENAME}\ninto: ${APPDIR_BINDIR}" --pulsate --auto-close --no-cancel
	fi
}

chooseInstallMethod() {
	
	if [ -z "$WINEPREFIX" ]; then
		export WINEPREFIX="${APPDIR}/wine64_bottle"
	fi

	if [ -z "$WINE_EXE" ]; then
		createWineBinaryList;
	
		WINEBIN_OPTIONS=()
		while read -r line; do
			# Set binary code, description, and path based on path
			if [ -L "$line" ]; then
				WINEOPT=$(readlink -f "$line")
			else
				WINEOPT="$line"
			fi
	
			if [[ "$WINEOPT" == *"/usr/bin/"* ]]; then
				WINEOPT_CODE="System"
				WINEOPT_DESCRIPTION="Use system's binary (i.e., /usr/bin/wine64). WINE must be 7.18-staging or later. Stable or Devel do not work."
				WINEOPT_PATH="${line}"
			elif [[ "$WINEOPT" == *"Proton"* ]]; then
				WINEOPT_CODE="Proton"
				WINEOPT_DESCRIPTION="Install using Steam's Proton fork of WINE."
				WINEOPT_PATH="${line}"
			elif [[ "$WINEOPT" == *"PlayOnLinux"* ]]; then
				WINEOPT_CODE="PlayOnLinux"
				WINEOPT_DESCRIPTION="Install using a PlayOnLinux WINE64 binary."
				WINEOPT_PATH="${line}"
			else
				WINEOPT_CODE="Custom"
				WINEOPT_DESCRIPTION="Use a WINE64 bianry from another directory."
				WINEOPT_PATH="${line}"
			fi
	
			# Create wine binary option array
			if [ -z "${WINEBIN_OPTIONS[0]}" ]; then
				WINEBIN_OPTIONS+=(TRUE "${WINEOPT_CODE}" "${WINEOPT_DESCRIPTION}" "${WINEOPT_PATH}")
			else
				WINEBIN_OPTIONS+=(FALSE "${WINEOPT_CODE}" "${WINEOPT_DESCRIPTION}" "${WINEOPT_PATH}")
			fi
		done < "${WORKDIR}/winebinaries"
	
		# Add AppImage to list
		WINEBIN_OPTIONS+=(FALSE "AppImage" "AppImage of Wine64 ${WINE64_APPIMAGE_FULL_VERSION}" "${APPDIR_BINDIR}/${WINE64_APPIMAGE_FULL_FILENAME}" )
	
		column_names=(--column "Choice" --column "Code" --column "Description" --column "Path")
	
		installationChoice="$(zenity --width=1024 --height=480 \
			--title="Question: Which WINE binary should be used to install ${FLPRODUCT}?" \
			--text="This script will install ${FLPRODUCT} v${LOGOS_VERSION} in ${INSTALLDIR} independent of other installations.\n\nPlease select the WINE binary's path or install method:" \
			--list --radiolist "${column_names[@]}" "${WINEBIN_OPTIONS[@]}" --print-column=2,3,4)";
		
		OIFS=$IFS
		IFS='|' read -r -a installArray <<< "${installationChoice}"
		IFS=$OIFS
	
		export WINEBIN_CODE=${installArray[0]}
		export WINE_EXE=${installArray[2]}
	fi

	if [ -n "${WINEBIN_CODE}" ]; then	
		case "${WINEBIN_CODE}" in
			"System"|"Proton"|"PlayOnLinux"|"Custom")
				echo "Installing ${FLPRODUCT} Bible ${TARGETVERSION} using a ${WINEBIN_CODE} WINE64 binary…"
				if [ -z "${REGENERATE}" ]; then
					make_skel "none.AppImage"
				fi
				;;
			"AppImage"*)
				check_lib libfuse;
				echo "Installing ${FLPRODUCT} Bible ${TARGETVERSION} using ${WINE64_APPIMAGE_FULL_VERSION} AppImage…"
				if [ -z "${REGENERATE}" ]; then
					make_skel "${WINE64_APPIMAGE_FULL_FILENAME}"

					# exporting PATH to internal use if using AppImage, doing backup too:
					export OLD_PATH="${PATH}"
					export PATH="${APPDIR_BINDIR}":"${PATH}"
	
					# Geting the AppImage:
					getAppImage;	
					chmod +x "${APPDIR_BINDIR}/${WINE64_APPIMAGE_FULL_FILENAME}"
				fi
				;;
			*)
				gtk_fatal_error "Installation canceled!"
		esac
	else
		echo "WINEBIN_CODE is not set in your config file."
	fi

	echo "Using: $(${WINE_EXE} --version)"

	# Set WINESERVER_EXE based on WINE_EXE.
	if [ -z "${WINESERVER_EXE}" ]; then
		if [ -x "$(dirname "${WINE_EXE}")/wineserver" ]; then
			WINESERVER_EXE="$(echo "$(dirname "${WINE_EXE}")/wineserver" | tr -d '\n')"; export WINESERVER_EXE;
		else
			gtk_fatal_error "$(dirname "${WINE_EXE}")/wineserver not found. Please either add it or create a symlink to it, and rerun."
		fi
	fi
}
## END INSTALL OPTIONS FUNCTIONS
## BEGIN WINE BOTTLE AND WINETRICKS FUNCTIONS
prepareWineBottle() {
	gtk_continue_question "Now the script will create and configure the Wine Bottle at ${WINEPREFIX}. You can cancel the instalation of Mono. Do you wish to continue?"
	echo "${WINE_EXE} wineboot"
	if [ -z "${WINEBOOT_GUI}" ]; then
		(DISPLAY="" ${WINE_EXE} wineboot) | zenity --progress --title="Waiting for ${WINE_EXE} wineboot" --text="Waiting for ${WINE_EXE} wineboot…" --pulsate --auto-close --no-cancel
	else
		${WINE_EXE} wineboot
	fi
	light_wineserver_wait
}

wine_reg_install() {
	REG_FILENAME="${1}"
	echo "${WINE_EXE} regedit.exe ${REG_FILENAME}"
	"${WINE_EXE}" regedit.exe "${WORKDIR}"/"${REG_FILENAME}" | zenity --progress --title="Wine regedit" --text="Wine is installing ${REG_FILENAME} in ${WINEPREFIX}" --pulsate --auto-close --no-cancel

	light_wineserver_wait
	echo "${WINE_EXE} regedit.exe ${REG_FILENAME} DONE!"
}

downloadWinetricks() {
	echo "Downloading winetricks from the Internet…"
	if [ -f "${PRESENT_WORKING_DIRECTORY}/winetricks" ]; then
		echo "A winetricks binary has already been downloaded. Using it…"
		cp "${PRESENT_WORKING_DIRECTORY}/winetricks" "${APPDIR_BINDIR}"
	elif [ -f "${HOME}/Downloads/winetricks" ]; then
		echo "A winetricks binary has already been downloaded. Using it…"
		cp "${HOME}/Downloads/winetricks" "${APPDIR_BINDIR}"
	else
		echo "winetricks does not exist. Downloading…"
		gtk_download "${WINETRICKS_URL}" "${APPDIR_BINDIR}"
	fi
	chmod 755 "${APPDIR_BINDIR}/winetricks"
}

setWinetricks() {
	# Check if local winetricks version available; else, download it
	if [ -z "${WINETRICKSBIN}" ]; then 
		if [ "$(which winetricks)" ]; then
			# Check if local winetricks version is up-to-date; if so, offer to use it or to download; else, download it
			LOCAL_WINETRICKS_VERSION=$(winetricks --version | awk -F' ' '{print $1}')
			if [ "${LOCAL_WINETRICKS_VERSION}" -ge "20220411" ]; then
				winetricksChoice="$(zenity --width=700 --height=310 \
				--title="Question: Should the script use local winetricks or download winetricks fresh?" \
				--text="This script needs to set some Wine options that help or make ${FLPRODUCT} run on Linux. Please select whether to use your local winetricks version or a fresh install." \
				--list --radiolist --column "S" --column "Description" \
				TRUE "1- Use local winetricks." \
				FALSE "2- Download winetricks from the Internet." )"

				case "${winetricksChoice}" in
					1*) 
						echo "Setting winetricks to the local binary…"
						WINETRICKSBIN="$(which winetricks)";
						export WINETRICKSBIN;
						;;
					2*) 
						downloadWinetricks;
						WINETRICKSBIN="${APPDIR_BINDIR}/winetricks";
						export WINETRICKSBIN;
						;;
					*)  
						gtk_fatal_error "Installation canceled!"
					esac
			else
				echo "The system's winetricks is too old. Downloading an up-to-date winetricks from the Internet…"
				downloadWinetricks;
				export WINETRICKSBIN="${APPDIR_BINDIR}/winetricks"
			fi
		else
			echo "Local winetricks not found. Downloading winetricks from the Internet…"
			downloadWinetricks;
			export WINETRICKSBIN="${APPDIR_BINDIR}/winetricks"
		fi
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
				${WINESERVER_EXE} -k;
			echo "ERROR on : winetricks ${*}; WINETRICKS_STATUS: ${WINETRICKS_STATUS}";
			gtk_fatal_error "The installation was cancelled because of sub-job failure!\n * winetricks ${*}\n  - WINETRICKS_STATUS: ${WINETRICKS_STATUS}";
		fi
	else
		"${WINESERVER_EXE}" -k;
		gtk_fatal_error "The installation was cancelled!\n * ZENITY_RETURN: ${ZENITY_RETURN}";
	fi
	echo "winetricks ${*} DONE!";

	heavy_wineserver_wait;
}

winetricks_dll_install() {
	echo "winetricks ${*}"
	gtk_continue_question "Now the script will install the DLL ${*}. There will not be any GUI feedback for this. Continue?"
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
	# This VAR is used to verify the downloaded MSI is latest
	if [ -z "${LOGOS_EXECUTABLE}" ]; then 
		LOGOS_EXECUTABLE="${FLPRODUCT}_v${LOGOS_VERSION}-x64.msi"
	fi

	gtk_continue_question "Now the script will check for the MSI installer. Then it will download and install ${FLPRODUCT} Bible at ${WINEPREFIX}. You will need to interact with the installer. Do you wish to continue?"

	echo "================================================="
	# Geting and install ${FLPRODUCT} Bible
	# First check current directory to see if the .MSI is present; if not, check user's Downloads/; if not, download it new. Once found, copy it to WORKDIR for future use.
	echo "Installing ${FLPRODUCT}Bible 64bits…"
	if [ -f "${PRESENT_WORKING_DIRECTORY}/${LOGOS_EXECUTABLE}" ]; then
		echo "${LOGOS_EXECUTABLE} exists. Using it…"
		cp "${PRESENT_WORKING_DIRECTORY}/${LOGOS_EXECUTABLE}" "${APPDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${LOGOS_EXECUTABLE}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
	elif [ -f "${HOME}/Downloads/${LOGOS_EXECUTABLE}" ]; then
		echo "${LOGOS_EXECUTABLE} exists. Using it…"
		cp "${HOME}/Downloads/${LOGOS_EXECUTABLE}" "${APPDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${LOGOS_EXECUTABLE}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
	else
		echo "${LOGOS_EXECUTABLE} does not exist. Downloading…"
		gtk_download "${LOGOS64_URL}" "${HOME}/Downloads/${LOGOS64_MSI}"
		mv "${HOME}/Downloads/${LOGOS64_MSI}" "${HOME}/Downloads/${LOGOS_EXECUTABLE}"
		cp "${HOME}/Downloads/${LOGOS_EXECUTABLE}" "${APPDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${LOGOS_EXECUTABLE}\ninto: ${APPDIR}" --pulsate --auto-close --no-cancel
	fi
}

installMSI() {
	# Execute the .MSI
	echo "Running: ${WINE_EXE} msiexec /i ${APPDIR}/${LOGOS_EXECUTABLE}"
	"${WINE_EXE}" msiexec /i "${APPDIR}"/"${LOGOS_EXECUTABLE}"
}

installFonts() {
	if [ -z "${WINETRICKS_UNATTENDED}" ]; then
		if [ -z "${SKIP_FONTS}" ]; then
			winetricks_install -q corefonts
			winetricks_install -q tahoma
		fi
		winetricks_install -q settings fontsmooth=rgb
	else
		if [ -z "${SKIP_FONTS}" ]; then
			winetricks_install corefonts
			winetricks_install tahoma
		fi
		winetricks_install settings fontsmooth=rgb
	fi
}

installD3DCompiler() {
	if [ -z "${WINETRICKS_UNATTENDED}" ]; then
		winetricks_dll_install -q d3dcompiler_47;
	else
		winetricks_dll_install d3dcompiler_47;
	fi
}

installLogos9() {	
	getPremadeWineBottle;

	setWineTricks;
	installFonts;
	installD3DCompiler;
	getLogosExecutable;
	installMSI;

	echo "======= Set ${FLPRODUCT}Bible Indexing to Vista Mode: ======="
	"${WINE_EXE}" reg add "HKCU\\Software\\Wine\\AppDefaults\\${FLPRODUCT}Indexer.exe" /v Version /t REG_SZ /d vista /f
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
	installFonts;
	installD3DCompiler;

	if [ -z "${WINETRICKS_UNATTENDED}" ]; then
		winetricks_install -q settings win10
	else
		winetricks_install settings win10
	fi

	getLogosExecutable;
	installMSI;
}
## END LOGOS INSTALL FUNCTIONS

getScriptTemplate() {
	SCRIPT_TEMPLATE="${1}"
	if [ "${SCRIPT_TEMPLATE}" = "Launcher-Template.sh" ]; then
		SCRIPT_TEMPLATE_URL="${LAUNCHER_TEMPLATE_URL}"
	else
		SCRIPT_TEMPLATE_URL="${CONTROL_PANEL_TEMPLATE_URL}"
	fi
	echo "Downloading the launcher script template…"
	if [ -f "${PRESENT_WORKING_DIRECTORY}/${SCRIPT_TEMPLATE}" ]; then
		echo "${SCRIPT_TEMPLATE} found. Using it…"
		cp "${PRESENT_WORKING_DIRECTORY}/${SCRIPT_TEMPLATE}" "${WORKDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${SCRIPT_TEMPLATE} into ${WORKDIR}" --pulsate --auto-close --no-cancel
	elif [ -f "${HOME}/Downloads/${SCRIPT_TEMPLATE}" ]; then
		echo "${SCRIPT_TEMPLATE} found in Downloads. Replacing it…"
		rm -f "${HOME}/Downloads/${SCRIPT_TEMPLATE}"
		gtk_download "${SCRIPT_TEMPLATE_URL}" "${HOME}/Downloads/${SCRIPT_TEMPLATE}"
		cp "${HOME}/Downloads/${SCRIPT_TEMPLATE}" "${WORKDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${SCRIPT_TEMPLATE} into ${WORKDIR}" --pulsate --auto-close --no-cancel
	else
		gtk_download "${SCRIPT_TEMPLATE_URL}" "${HOME}/Downloads/${SCRIPT_TEMPLATE}"
		cp "${HOME}/Downloads/${SCRIPT_TEMPLATE}" "${WORKDIR}/" | zenity --progress --title="Copying…" --text="Copying: ${SCRIPT_TEMPLATE} into ${WORKDIR}" --pulsate --auto-close --no-cancel
	fi
}

# See https://stackoverflow.com/a/17921589/1896800
apply_shell_expansion() {
	file="$1"
	data=$(< "$file")
	delimiter="__apply_shell_expansion_delimiter__"
	command="cat <<$delimiter"$'\n'"$data"$'\n'"$delimiter"
	eval "$command"
}

createLauncher() {
	echo "Creating starting scripts for ${FLPRODUCT}Bible 64 bits…"
	getScriptTemplate "Launcher-Template.sh";
	printf "%s\n" "$(apply_shell_expansion "${WORKDIR}/Launcher-Template.sh")" > "${WORKDIR}"/"${FLPRODUCT}".sh;
	chmod 755 "${WORKDIR}"/"${FLPRODUCT}".sh;
	mv "${WORKDIR}"/"${FLPRODUCT}".sh "${INSTALLDIR}"/
}

createControlPanel() {
	getScriptTemplate "controlPanel-Template.sh";
	printf "%s\n" "$(apply_shell_expansion "${WORKDIR}/controlPanel-Template.sh")" > "${WORKDIR}"/controlPanel.sh;
	chmod 755 "${WORKDIR}"/controlPanel.sh;
	mv "${WORKDIR}"/controlPanel.sh "${INSTALLDIR}"/
}

create_starting_scripts() {
	createLauncher;
	createControlPanel;
}

createConfig() {
	cat > "${HOME}/.config/Logos_on_Linux/Logos_on_Linux.conf" << EOF
# INSTALL OPTIONS
FLPRODUCT="${FLPRODUCT}"
FLPRODUCTi="${FLPRODUCTi}"
TARGETVERSION="${TARGETVERSION}"
INSTALLDIR="${INSTALLDIR}"
APPDIR="${APPDIR}"
APPDIR_BINDIR="${APPDIR_BINDIR}"
WINETRICKSBIN="${WINETRICKSBIN}"
WINEPREFIX="${WINEPREFIX}"
WINEBIN_CODE="${WINEBIN_CODE}"
WINE_EXE="${WINE_EXE}"
WINESERVER_EXE="${WINESERVER_EXE}"
WINE64_APPIMAGE_FULL_URL="${WINE64_APPIMAGE_FULL_URL}"
WINE64_APPIMAGE_FULL_FILENAME="${WINE64_APPIMAGE_FULL_FILENAME}"
APPIMAGE_LINK_SELECTION_NAME="${APPIMAGE_LINK_SELECTION_NAME}"
LOGOS_EXECUTABLE="${LOGOS_EXECUTABLE}"
LOGOS_EXE="${LOGOS_EXE}"
LOGOS_DIR="$(dirname "${LOGOS_EXE}")"

# RUN OPTIONS
LOGS="DISABLED"

# RESTORE OPTIONS
BACKUPDIR=""
EOF
}

regenerateScripts() {
	echo "$LOGOS_SCRIPT_TITLE, $LOGOS_SCRIPT_VERSION by $LOGOS_SCRIPT_AUTHOR."
	die-if-root;
	debug && echo "Debug mode enabled."

	checkDependencies;
	chooseProduct;
	chooseVersion;
	chooseInstallMethod;

	create_starting_scripts;
}
# END FUNCTION DECLARATIONS

main() {
	echo "$LOGOS_SCRIPT_TITLE, $LOGOS_SCRIPT_VERSION by $LOGOS_SCRIPT_AUTHOR."
	die-if-root;
	debug && echo "Debug mode enabled."

	# BEGIN PREPARATION
	checkDependencies; # We verify the user is running a graphical UI and has majority of required dependencies.
	chooseProduct; # We ask user for his Faithlife product's name and set variables.
	chooseVersion; # We ask user for his Faithlife product's version, set variables, and create project skeleton.
	chooseInstallMethod; # We ask user for his desired install method.
	prepareWineBottle; # We run wineboot.
	# END PREPARATION

	# BEGIN INSTALL
	case "${TARGETVERSION}" in
		10*)
				installLogos10; ;; # We run the commands specific to Logos 10.
		9*)
				installLogos9; ;; # We run the commands specific to Logos 9.
		*)
				gtk_fatal_error "Installation canceled!" ;;
	esac

	create_starting_scripts;

	heavy_wineserver_wait;
	clean_all;

	LOGOS_EXE=$(find "${WINEPREFIX}" -name ${FLPRODUCT}.exe | grep "${FLPRODUCT}/${FLPRODUCT}.exe"); export LOGOS_EXE;

	if [ -f "${LOGOS_EXE}" ]; then
		gtk_continue_question "${FLPRODUCT} Bible ${TARGETVERSION} installed!"
		if [ -z "$LOGOS_CONFIG" ] && [ ! -f "${DEFAULT_CONFIG_PATH}" ]; then
			mkdir -p "${HOME}/.config/Logos_on_Linux";
			if [ -d "${HOME/.config/Logos_on_Linux}" ]; then
				createConfig;
				echo "A config file was created at ${DEFAULT_CONFIG_PATH}.";
				gtk_continue_question "A config file was created at ${DEFAULT_CONFIG_PATH}.";
			else
				echo "${HOME}/.config/Logos_on_Linux does not exist. Failed to create config file."
				gtk_continue_question "${HOME}/.config/Logos_on_Linux does not exist. Failed to create config file."
			fi
		elif [ -z "$LOGOS_CONFIG" ] && [ -f "${DEFAULT_CONFIG_PATH}" ]; then
			if gtk_question "The script found a config file at ${DEFAULT_CONFIG_PATH}. Should the script overwrite the existing config?"; then
				if [ -d "${HOME/.config/Logos_on_Linux}" ]; then
					createConfig;
				else
					echo "${HOME}/.config/Logos_on_Linux does not exist. Failed to create config file.";
					gtk_continue_question "${HOME}/.config/Logos_on_Linux does not exist. Failed to create config file."
				fi
			fi
		else
			# Script was run with a config file. Skip modifying the config.
			:
		fi

		if gtk_question "A launch script has been placed in ${INSTALLDIR} for your use. The script's name is ${FLPRODUCT}.sh.\n\nDo you want to run it now?\n\nNOTE: There may be an error on first execution. You can close the error dialog."; then
			"${INSTALLDIR}"/"${FLPRODUCT}".sh
		else echo "The script has finished. Exiting…";
		fi
	else
		echo "Installation failed. ${LOGOS_EXE} not found. Exiting…"
		gtk_fatal_error "The ${FLPRODUCT} executable was not found. This means something went wrong while installing ${FLPRODUCT}. Please contact the Logos on Linux community for help."
	fi
	# END INSTALL
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
		--help)					set -- "$@" -h ;;
		--version)				set -- "$@" -V ;;
		--config)				set -- "$@" -c ;;
		--skip-fonts)			set -- "$@" -F ;;
		--regenerate-scripts)	set -- "$@" -r ;;
		--force-root)			set -- "$@" -f ;;
		--debug)				set -- "$@" -D ;;
		*)						set -- "$@" "$arg" ;;
	esac
done
OPTSTRING=':hvcDfFr' # Available options

# First loop: set variable options which may affect other options
while getopts "$OPTSTRING" opt; do
	case $opt in
			c)  NEXTOPT=$(${OPTIND})
			if [ -n "$NEXTOPT" ] && [ "$NEXTOPT" != "-*" ]; then
				OPTIND=$((OPTIND + 1))
				if [ -f "$NEXTOPT" ]; then
					LOGOS_CONFIG="${NEXTOPT}"
					export LOGOS_CONFIG;
					set -a
					# shellcheck disable=SC1090
					source "$LOGOS_CONFIG";
					set +a
				else
					echo "$LOGOS_SCRIPT_TITLE: -$OPTARG: Invalid config file path." >&2 && usage >&2 && exit;
				fi
			elif [ -f "$HOME/.config/Logos_on_Linux/Logos_on_Linux.conf" ]; then
				LOGOS_CONFIG="$HOME/.config/Logos_on_Linux/Logos_on_Linux.conf"
				export LOGOS_CONFIG
				set -a
				# shellcheck disable=SC1090
				source "$LOGOS_CONFIG";
				set +a
			else
				echo "No config file found."
			fi
			;;
		F)  export SKIP_FONTS="1" ;;
		f)  export LOGOS_FORCE_ROOT="1"; ;;
		D)  export DEBUG=true;
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
		v)  echo "$LOGOS_SCRIPT_TITLE, $LOGOS_SCRIPT_VERSION by $LOGOS_SCRIPT_AUTHOR." && exit ;;
		r)  REGENERATE=1; regenerateScripts;
			echo "Scripts regenerated. Exiting." && exit ;;
		\?) echo "$LOGOS_SCRIPT_TITLE: -$OPTARG: undefined option." >&2 && usage >&2 && exit ;;
		:)  echo "$LOGOS_SCRIPT_TITLE: -$OPTARG: missing argument." >&2 && usage >&2 && exit ;;
	esac
done
# If no options passed.
if [ "$OPTIND" -eq '1' ]; then
		:
fi
shift $((OPTIND-1))
# END OPTARGS

main;

exit 0;


