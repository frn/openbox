#!/bin/bash
#
# based on https://github.com/pbrisbin/wifi-pipe
#

net='/ESSID/ { id=substr($2,2,length($2)-2) }
/^ *Quality/ { split($1,q,"[=/]") }
/^ *Enc.*:on/ { sec="wep" }
/^ *IE.*WPA/ { sec="wpa" }
/^ *Auth.*802/ { sec="ent" }
/^ *Mode/ { mode=$2 }
/^ *Cell|^$/ { if(id) print q[2]/q[3]*100"="id"="sec"="mode; sec="none" }'

err() {
echo "<openbox_pipe_menu>
<item label=\"$*\" />
</openbox_pipe_menu>"
exit
}

z() { zenity --$1 --title="$id" --text="$2" $3; }

check() {
  if [[ $(wpa_cli -i "$iface" ping 2>/dev/null) = "PONG" ]]; then
    is_up=1
  else
    ip link set $iface up || err "$iface unavailable"
    while ! ip link show "$iface" | grep -q UP; do sleep 0.25; done
  fi
}

menu() {
  check
  n=$(iwlist $iface scan | awk -F: "$net" | sort -t= -ruk2 | sort -rn)
  (( is_up )) || ip link set $iface down

  [[ $n ]] || err "no networks found"

  echo "<openbox_pipe_menu>"
  echo '<separator label="Networks" />'
  while IFS='=' read qual id sec mode; do echo "\
<item label=\"$id ($sec) ${qual%.*}%\">
 <action name=\"Execute\">
  <command>sudo $0 $iface connect \"$id\" $sec $mode</command>
 </action>
</item>"
  done <<< "$n"
  echo "</openbox_pipe_menu>"
}

create_pfile() {
  pfile=$PDIR/$id

  case $sec in
  ent)
    u=$(z entry Username) || exit
    p=$(z entry Password --hide-text) || exit
    sec=wpa-configsection
    key="WPAConfigSection=(
	'ssid=\"$id\"'
	'key_mgmt=WPA-EAP'
	'eap=PEAP'
	'phase2=\"auth=MSCHAPV2\"'
	'identity=\"$u\"'
	'password=\"$p\"')";;
  wep|wpa)
    key="Key='$(z entry "Enter $sec key" --hide-text)'" || exit;;
  esac

  cat > "$pfile" << EOF
Connection=wireless
Interface=$iface
IP=dhcp
ESSID="$id"
Security=$sec
$key
EOF
  [[ $mode = Ad-Hoc ]] && printf "WPADriver=wext\nAdHoc=1\n" >> "$pfile"

  chmod 600 "$pfile"
}

connect() {
  id=$3 sec=$4 mode=$5 pfile=$(grep -rEl "ESSID=[\"']?$id" $PDIR | head -1)

  [[ $pfile ]] || create_pfile

  netctl switch-to "${pfile##*/}" |
  z progress Connecting... "--pulsate --no-cancel --auto-close"

  if (( PIPESTATUS )); then
    z question "Connection failed\n\nKeep $pfile?" \
	"--ok-label=Keep --cancel-label=Remove" || rm "$pfile"
  else
    z info "Connection established"
  fi
}

PDIR=/etc/netctl
iface=$1

[[ $2 = connect ]] && connect "$@" || menu