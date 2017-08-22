#!/bin/bash
#
#     Utility to set the password of a Mattermost user
#     Bob Brandt <projects@brandt.ie>
#

_version=1.0
_brandt_utils=/opt/brandt/common/brandt.sh
_this_script=/opt/brandt/mattermost-utils/utils/mattermostSetPassword.sh

_platform_bin=/opt/mattermost/bin/platform

[ ! -r "$_brandt_utils" ] && echo "Unable to find required file: $_brandt_utils" 1>&2 && exit 6
. "$_brandt_utils"

function usage() {
    local _exitcode=${1-0}
    local _output=2
    [ "$_exitcode" == "0" ] && _output=1
    [ "$2" == "" ] || echo -e "$2"
	( echo -e "Usage: $0 username password"
	  echo -e " -h, --help         display this help and exit"
	  echo -e " -v, --version      output version information and exit" ) >&$_output
    exit $_exitcode
}

# Execute getopt
if ! _args=$( getopt -o u:pfvh -l "help,version" -n "$0" -- "$@" 2>/dev/null ); then
    _err=$( getopt -o u:pfvh -l "help,version" -n "$0" -- "$@" 2>&1 >/dev/null )
    usage 1 "${BOLD_RED}$_err${NORMAL}"
fi

#Bad arguments
[ $? -ne 0 ] && usage 1 "${BOLD_RED}$0: No arguments supplied!${NORMAL}"

eval set -- "$_args";

while /bin/true ; do
    case "$1" in
        -h | --help )      usage 0 ;;
        -v | --version )   brandt_version $_version ;;
        -- )               shift ; break ;;
        * )                usage 1 "${BOLD_RED}$0: Invalid argument!${NORMAL}" ;;
    esac
    shift
done
_username="$1"
_password="$2"
shift 2

[ -z "$_username" ] && usage 1 "${BOLD_RED}$0: A username MUST be supplied!${NORMAL}"
[ -z "$_password" ] && usage 1 "${BOLD_RED}$0: A password MUST be supplied!${NORMAL}"
[ -d "$( dirname $_platform_bin )" ] || usage 1 "${BOLD_RED}$0: Unable to find Mattermost binarys!${NORMAL}"
[ -x "$_platform_bin" ] || usage 1 "${BOLD_RED}$0: Unable to find Mattermost binarys!${NORMAL}"

pushd $( dirname "$_platform_bin" ) > /dev/null 2>&1
_output=$( "$_platform_bin" user search "$_username" 2>&1 )
popd > /dev/null 2>&1

if echo -e "$_output" | grep "^username:\s" >/dev/null 2>&1
then
	pushd $( dirname "$_platform_bin" ) > /dev/null 2>&1
	_output=$( "$_platform_bin" user password "$_username" "$_password" 2>&1 )
	popd > /dev/null 2>&1
	if [ -z "$_output" ]; then
		echo "$0: Password updated successfully for user ($_username)" >&2
		exit 0
	fi
else
	echo "${BOLD_RED}The username ($_username) does not exist!${NORMAL}"
	exit 1
fi
exit 1
