#!/bin/bash

# Include main config
if [ -e ./login.conf ]; then
  source ./login.conf
else 
  echo "ERROR: Config file not found";
  exit 1
fi

usage(){
  echo "Usage: $0 -i <ip> -a <action> [-o <option>]"
  echo "Actions:"
  echo "- list        - list of all servers"
  echo "- reboot      - reboot server [-o sw|hw|man]"
  echo "- wol         - wake on lan server"
  echo "- rescue      - boot server in rescue system"
  echo "- setup       - setup system on server"
  echo "- rdns        - set reverse DNS entry"
  echo "- server_name - set server_name"
  exit 1
}

verify(){
  read -p "$1 (Y/N)? "
  if [ "$(echo $REPLY | tr [:upper:] [:lower:])" == "n" ]; then
    echo "Action canceled"
    exit 1
  fi
  return
}

parse(){
  echo $1 | sed "s/[{}\"]//g" | tr "," "\n" | tr -d "[]" | sed "s/^$2:/\n$2:\n/g"
}

while getopts i:a:o: option
do
  case "${option}" in
    i) server=${OPTARG};;
    a) action=${OPTARG};;
    o) opt=${OPTARG};;
  esac
done

CMD="curl -s -u $login:$passwd https://robot-ws.your-server.de"

case "$action" in
  list)
    parse "`$CMD/server/$server`" "server"
    echo $data 
  ;;
  reboot)
    verify "Are you sure to reboot the server $server"
    if [ "$opt" == "" ]; then
      echo "Type of reboot not specified. Used type 'software'."
      opt='sw';
    fi
    parse "`$CMD/reset/$server -d "type=$opt"`" "reset"
  ;;
  wol)
    if [ "$opt" == '' ]; then
      parse "`$CMD/wol/$server`" "wol"
    else
      verify "Are you sure to send Wake On LAN packet to $server"
      parse "`$CMD/wol/$server -d foo`" "wol"
    fi
  ;;
  rescue)
    verify "Are you sure to request rescue system for $server"
    parse "`$CMD/boot/$server/rescue -d "os=linux&arch=64"`" "rescue"
    verify "Send software reset to $server"
    parse "`$CMD/reset/$server -d "type=sw"`" "reset"
  ;;
  setup)
    if [ "$opt" == '' ]; then
      parse "`$CMD/boot/$server/linux`" "linux"
    else
      verify "Are you sure to setup new system on $server"
      parse "`$CMD/boot/$server/linux -d 'dist=Ubuntu 12.04 LTS minimal&arch=64&lang=en'`" "linux"
      verify "Send software reset to $server"
      parse "`$CMD/reset/$server -d "type=sw"`" "reset"
    fi
  ;;
  rdns)
    if [ "$opt" == '' ]; then
      parse "`$CMD/rdns/$server`" "rdns"
    else  
      verify "Are you sure to set RDNS entry to '$opt' for $server"
      parse "`$CMD/rdns/$server -d "ptr=$opt"`" "rdns"
    fi
  ;;
  server_name)
    verify "Are you sure to set the server name '$opt' for $server"
    parse "`$CMD/server/$server -d "server_name=$opt"`" "server"
  ;;
  *)
    usage
  ;;
esac

echo
