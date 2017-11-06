#!/bin/bash

function generateExecute() {
	printf '  <item label="%s">\n' "$1"
	printf '    <action name="Execute"><command>%s</command></action>\n' "$2"
	printf '  </item>\n'
}

function generateMenu() {
	declare name="${1}"
	declare -a exec=("${!2}")
	printf '<menu id="%s" label="%s">\n' "$name" "$name"
	for c in "${exec[@]}"; do
	    command="${NETCTL} ${c} ${name}"
	    generateExecute ${c} ${command}
	done
	printf '</menu>\n'
}

function generateSeparator() {
    [[ ${1} ]] && printf '  <separator label="%s"/>\n' "$1" || echo "<separator />"

}

function connectedProfile() {
    p=$(netctl list | grep \*)
    [[ ${p} ]] && p="${CONNECTED} ${p//\*/}" || p="${CONNECTED} []"
    generateSeparator ${p}
}

function profiles() {
    profiles=($(netctl list))
    regex="^\*"
    CMD="start"

    [[ `echo ${profiles[@]} | grep \*` ]] && CMD="switch-to"

    for p in "${profiles[@]}"; do
	    cmd=(${CMD})
	    [[ $p =~ ^\* ]] && cmd=("stop" "restart")
	    p=${p//\*/}
	    p=${p// /}
	    generateMenu "${p}" cmd[@]
    done
}

IFS=$'\n'
NETCTL="sudo netctl"
CONNECTED="Connected profile:"


echo '<?xml version="1.0" encoding="UTF-8"?>'
echo '<openbox_pipe_menu>'
connectedProfile
generateExecute "Stop All" "${NETCTL} stop-all"
generateSeparator "Profiles"
profiles
echo '</openbox_pipe_menu>'
