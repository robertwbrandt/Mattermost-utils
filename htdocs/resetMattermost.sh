#!/bin/bash
#
#     Script to update Mattermost password on remote server
#  
VERSION=0.1

runas=mattermost
server=kopano-teams.i.opw.ie
target=/opt/brandt/mattermost-utils/utils/createLDAPUser.sh

username="$1"
password="$2"


usage() {
        [ "$2" == "" ] || echo -e "$2"
        echo -e "Usage: $0 username password"
        echo -e "Options:"
        echo -e " -u, --username  Username can also be given as an option."
        echo -e " -p, --password  Password can also be given as an option."
        echo -e " -s, --server    Mattermost Server. (Default: $server)"
        echo -e " -t, --target    Target script. (Default: $target)"
        echo -e " -r, --runas     Run as user (on remote server. Default: $runas)"
        echo -e " -h, --help      Display this help and exit"
        echo -e " -v, --version   Output version information and exit"
        exit ${1:-0}
}

version() {
        echo -e "$0 $VERSION"
        echo -e "Copyright (C) 2011 Free Software Foundation, Inc."
        echo -e "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>."
        echo -e "This is free software: you are free to change and redistribute it."
        echo -e "There is NO WARRANTY, to the extent permitted by law.\n"
        echo -e "Written by Bob Brandt <projects@brandt.ie>."
        exit 0
}


# Execute getopt
ARGS=$(getopt -o u:p:r:s:t:vh -l "username:,password:runas:,server:,target:,help,version" -n "$0" -- "$@") || usage 1 " "

#Bad arguments
#[ $? -ne 0 ] && usage 1 "$0: No arguments supplied!\n"

eval set -- "$ARGS";

while /bin/true ; do
        case "$1" in
        -u | --username )     username="$2" ; shift ;;
        -p | --password )     password="$2" ; shift ;;
        -r | --runas )        runas="$2" ; shift ;;
        -s | --server )       server="$2" ; shift ;;
        -t | --target )       target="$2" ; shift ;;
        -h | --help )         usage 0 ;;
        -v | --version )      version ;;
        -- )                  shift ; break ;;
        * )                   usage 1 "$0: Invalid argument!\n" ;;
        esac
        shift
done

test -z "$username" && username="$1"
test -z "$password" && password="$2"

_error=$( ssh $runas@$server $target --password "$password" "$username" 2>&1 )
_returncode=$?

if [ "$_returncode" == "0" ]; then
        logger -st "mm-createuser" "Created user ($username)."
else
        logger -st "mm-createuser" "Failed to created user ($username). ($_error)"
        echo -e "$_error"
fi

exit $_returncode


