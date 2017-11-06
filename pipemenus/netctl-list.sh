#!/bin/bash

to_execute() {
	printf '  <item label="%s">\n' "$1"
	printf '    <action name="Execute"><command>sudo netctl %s %s</command></action>\n' "$1" "$2"
	printf '  </item>\n'
}

to_menu() {
	declare name="${1}"
	declare -a exec=("${!2}")
	printf '<menu id="%s" label="%s">\n' "$name" "$name"
	for c in "${exec[@]}"; do
	    to_execute ${c} ${name}
	done
	printf '  </menu>\n'
}

netctl_prof() {
profiles=($(netctl list))

regex="^\*"
for p in "${profiles[@]}"; do
	cmd=("start")
	[[ $p =~ ^\* ]] && cmd=("stop" "restart")
	to_menu "${p// /}" cmd[@]
done
}

IFS=$'\n'

echo '<?xml version="1.0" encoding="UTF-8"?>'
echo '<openbox_pipe_menu>'
to_execute 'stop-all'
netctl_prof
echo '</openbox_pipe_menu>'