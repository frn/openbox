#!/bin/bash

function generateExecute() {
	printf '  <item label="%s">\n' "${1^}"
	printf '    <action name="Execute"><command>%s %s</command></action>\n' "${NETCTL}" "$2"
	printf '  </item>\n'
}

function generateSeparator() {
    [[ ${1} ]] && printf '  <separator label="%s"/>\n' "${1^}" || echo "<separator />"

}

function connectedProfile() {
    CONNECTED=$(netctl list | grep \*)
    CONNECTED=${CONNECTED//\*/}
    [[ ${CONNECTED} ]] && generateSeparator "${CONNECTED_MSG} ${CONNECTED}" &&
                        generateExecute "stop" "stop ${CONNECTED}" &&
                        generateExecute "restart" "restart ${CONNECTED}" ||
                        generateSeparator "${CONNECTED_MSG} []"
}

function allProfiles() {
    [[ ${CONNECTED} ]] && generateSeparator "All Profiles" && generateExecute "stop-all" "stop-all"
}

function profiles() {
    profiles=($(netctl list))
    regex="^\*"
    if [[ ${CONNECTED} ]]
    then
        CMD="switch-to"
        PROFILES="Other Profiles"
    else
        CMD="start"
        PROFILES="Profiles"
    fi

    generateSeparator ${PROFILES}

    for p in "${profiles[@]}"; do
	    [[ $p =~ ^\* ]] && continue
	    p=${p// /}
	    generateExecute "${CMD} ${p}" "${CMD} ${p}"
    done
}

IFS=$'\n'
NETCTL="sudo netctl"
CONNECTED_MSG="Connected profile:"


echo '<?xml version="1.0" encoding="UTF-8"?>'
echo '<openbox_pipe_menu>'
connectedProfile
allProfiles
profiles
echo '</openbox_pipe_menu>'
