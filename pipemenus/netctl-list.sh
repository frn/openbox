#!/bin/bash

function generateExecute() {
	printf '  <item label="%s">\n' "$1"
	printf '    <action name="Execute"><command>%s</command></action>\n' "$2"
	printf '  </item>\n'
}

function generateSeparator() {
    [[ ${1} ]] && printf '  <separator label="%s"/>\n' "$1" || echo "<separator />"

}

function connectedProfile() {
    p=$(netctl list | grep \*)
    p=${p//\*/}
    [[ ${p} ]] && activeName="${CONNECTED} ${p}" || activeName="${CONNECTED} []"
    generateSeparator ${activeName}
    generateExecute "Stop" "${NETCTL} stop ${p}"
    generateExecute "Restart" "${NETCTL} restart ${p}"
}

function profiles() {
    profiles=($(netctl list))
    regex="^\*"
    CMD="start"

    [[ `echo ${profiles[@]} | grep \*` ]] && CMD="switch-to"

    for p in "${profiles[@]}"; do
	    [[ $p =~ ^\* ]] && continue
	    p=${p// /}
	    generateExecute "${CMD} ${p}" "${NETCTL} ${CMD} ${p}"
    done
}

IFS=$'\n'
NETCTL="sudo netctl"
CONNECTED="Connected profile:"


echo '<?xml version="1.0" encoding="UTF-8"?>'
echo '<openbox_pipe_menu>'
connectedProfile
generateSeparator "All Profiles"
generateExecute "Stop All" "${NETCTL} stop-all"
generateSeparator "Other Profiles"
profiles
echo '</openbox_pipe_menu>'
