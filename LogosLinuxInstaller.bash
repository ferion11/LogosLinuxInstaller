# shellcheck disable=SC2207
_logoslinuxinstaller_completions() {
	LOGOSLINUXINSTALLER_OPTIONS='-h --help -v --version -D --debug -c --config -r --regenerate-scripts -F --skip-fonts -f --force-root'
	COMPREPLY=($(compgen -W "${LOGOSLINUXINSTALLER_OPTIONS}" -- "${COMP_WORDS[1]}"))
}

complete -F _logoslinuxinstaller_completions ./LogosLinuxInstaller.sh
complete -F _logoslinuxinstaller_completions LogosLinuxInstaller

_logos_completions() {
	LOGOS_OPTIONS='-h --help -v --version -D --debbug -f --force-root -R --check-resources -e --edit-config -i --indexing -b --backup -r --restore -l --logs -d --dirlink -s --shortcut --remove-all-index --remove-library-catalog --install-bash-completion'
	COMPREPLY=($(compgen -W "${LOGOS_OPTIONS}" -- "${COMP_WORDS[1]}"))
}

complete -F _logos_completions ./Logos.sh
complete -F _logos_completions ./Verbum.sh
complete -F _logos_completions Logos
complete -F _logos_completions Verbum
complete -F _logos_completions logos
complete -F _logos_completions verbum
complete -F _logos_completions lbs

_logos_controlpanel_completions() {
	CONTROLPANEL_OPTIONS='-h --help -v --version -D --debug -f --force-root --wine64 --wineserver --winetricks --setAppImage'
	COMPREPLY=($(compgen -W "${CONTROLPANEL_OPTIONS}" -- "${COMP_WORDS[1]}"))
}

complete -F _logos_controlpanel_completions ./controlPanel.sh
complete -F _logos_controlpanel_completions controlPanel

# ex: filetype=sh

