#!/bin/bash
#
#     Utility to manage Mattermost users
#     Bob Brandt <projects@brandt.ie>
#

_version=1.0
_brandt_utils=/opt/brandt/common/brandt.sh
_this_script=/opt/brandt/mattermost-utils/utils/mattermostUser.sh
_this_conf=/etc/brandt/mattermostUser.conf

_platform_bin=/opt/mattermost/bin/platform
_platform_config=/etc/mattermost/config.json
_platform_user=mattermost

[ ! -r "$_brandt_utils" ] && echo "Unable to find required file: $_brandt_utils" 1>&2 && exit 6
. "$_brandt_utils"

if [ ! -f "$_this_conf" ]; then
	mkdir $( dirname "$_this_conf" ) 2> /dev/null
	( echo '#     Configuration file for update script'
	  echo '#     Bob Brandt <projects@brandt.ie>'
          echo '# LDAP Settings'
          echo '_LDAP_filter="(&(objectClass=person)(mail=*))"'
          echo '_LDAP_URI="ldap://ldap/"'
          echo '_LDAP_Base=""'
          echo '_LDAP_BindDN=""'
          echo '_LDAP_BindPW=""'
          echo '# Mattermost to LDAP mappings'
          echo '_email="mail"'
          echo '_firstname="givenName"'
          echo '_lastname="sn"'
          echo '_nickname="displayName"'
          echo '_username="sAMAccountName"'
          echo '_default_password="PassW0rd"'
          echo '# Locale (ex: en, fr)'
          echo '_locale="en"'
          echo '# Default Team'
          echo '_default_team="OPW"') > "$_this_conf"
fi
. "$_this_conf"

function usage() {
    local _exitcode=${1-0}
    local _output=2
    [ "$_exitcode" == "0" ] && _output=1
    [ "$2" == "" ] || echo -e "$2"
	( echo -e "Usage: $0 username"
    echo -e " -c, --create             Create account is does not exist."
    echo -e " -p, --password PASSWORD  Change password"
	  echo -e "                           (Default password is: $_password)"
    echo -e " -r, --remote HOST        Use remote Mattermost host. (SSH Keys must be setup)"
    echo -e " -t, --test               Test connection to Mattermost host"
	  echo -e " -h, --help               Display this help and exit"
	  echo -e " -v, --version            Output version information and exit" ) >&$_output
    exit $_exitcode
}

# Execute getopt
if ! _args=$( getopt -o cp:r:tvh -l "create,password:,remote:,test,help,version" -n "$0" -- "$@" 2>/dev/null ); then
    _err=$( getopt -o cp:r:tvh -l "create,password:,remote:test,help,version" -n "$0" -- "$@" 2>&1 >/dev/null )
    usage 1 "${BOLD_RED}$_err${NORMAL}"
fi

#Bad arguments
[ $? -ne 0 ] && usage 1 "${BOLD_RED}$0: No arguments supplied!${NORMAL}"

eval set -- "$_args";

_password=""
_create=0
_remote=""
_test=0
while /bin/true ; do
    case "$1" in
        -c | --create )    _create=1 ;;
        -t | --test )      _test=1 ;;
        -r | --remote )    _remote="$2" ; shift ;;
        -p | --password )  _password="$2" ; shift ;;
        -h | --help )      usage 0 ;;
        -v | --version )   brandt_version $_version ;;
        -- )               shift ; break ;;
        * )                usage 1 "${BOLD_RED}$0: Invalid argument!${NORMAL}" ;;
    esac
    shift
done
_user="$1"
shift 1

[ -z "$_user" ] && usage 1 "${BOLD_RED}$0: A username MUST be supplied!${NORMAL}"





exit 0











[ -d "$( dirname $_platform_bin )" ] || usage 1 "${BOLD_RED}$0: Unable to find Mattermost binarys!${NORMAL}"
[ -x "$_platform_bin" ] || usage 1 "${BOLD_RED}$0: Unable to find Mattermost binarys!${NORMAL}"

_cmd="-LLL -x"
[ -n "$_LDAP_URI" ] && _cmd="$_cmd -H \"$_LDAP_URI\""
[ -n "$_LDAP_Base" ] && _cmd="$_cmd -b \"_LDAP_Base\""
if [ -n "$_LDAP_BindDN" ]; then
	_cmd="$_cmd -D \"$_LDAP_BindDN\" -w \"$_LDAP_BindPW\""
fi
_attrs=""
[ -n "$_email" ] && _attrs="$_attrs $_email"
[ -n "$_firstname" ] && _attrs="$_attrs $_firstname"
[ -n "$_lastname" ] && _attrs="$_attrs $_lastname"
[ -n "$_nickname" ] && _attrs="$_attrs $_nickname"
[ -n "$_username" ] && _attrs="$_attrs $_username"
_LDAP_filter="\"(&$_LDAP_filter($_username=$_user))\""
echo ldapsearch $_cmd \"$_LDAP_filter\" $_attrs | sed -e 's|-w "[^"]*"|-w "*****"|' -e 's|""|"|g' >&2
_ldap_output=$( eval ldapsearch $_cmd "$_LDAP_filter" $_attrs | perl -p00e 's/\r?\n //g' )
echo -e "$_ldap_output" >&2
_email=$( echo -e "$_ldap_output" | grep "^$_email:\s" 2>/dev/null | sed "s|.*:\s*||" )
_firstname=$( echo -e "$_ldap_output" | grep "^$_firstname:\s" 2>/dev/null | sed "s|.*:\s*||" )
_lastname=$( echo -e "$_ldap_output" | grep "^$_lastname:\s" 2>/dev/null | sed "s|.*:\s*||" )
_nickname=$( echo -e "$_ldap_output" | grep "^$_nickname:\s" 2>/dev/null | sed "s|.*:\s*||" )
[ -z "$_email" ] && echo "${BOLD_RED}Unable to retrieve email address from LDAP!${NORMAL}" >&2 && exit 1
[ -z "$_firstname" ] && echo "${BOLD_RED}Unable to retrieve first name from LDAP!${NORMAL}" >&2 && exit 1
[ -z "$_lastname" ] && echo "${BOLD_RED}Unable to retrieve last name from LDAP!${NORMAL}" >&2 && exit 1
[ -z "$_nickname" ] && echo "${BOLD_RED}Unable to retrieve nickname from LDAP!${NORMAL}" >&2 && exit 1

echo ""

pushd $( dirname "$_platform_bin" ) > /dev/null 2>&1
_mm_output=$( "$_platform_bin" --config "$_platform_config" user search "$_user" 2>&1 )
popd > /dev/null 2>&1
if echo -e "$_mm_output" | grep "^username:\s" >/dev/null 2>&1
then
	echo -e "User Already Exists!\n$_mm_output" >&2
	if [ -n "$_password" ]; then
	        pushd $( dirname "$_platform_bin" ) > /dev/null 2>&1
        	_output=$( "$_platform_bin" --config "$_platform_config" user password "$_user" "$_password" 2>&1 )
	        popd > /dev/null 2>&1
	        if [ -z "$_output" ]; then
        	        logger -st "mm-createuser" "Password updated successfully for user ($_user) with password ($_password)"
	        else
			logger -st "mm-createuser" "$_output"
			exit 1
		fi
	fi
	exit 0
else
	_rc=1
	[ -z "$_password" ] && _password="$_default_password"
	pushd $( dirname "$_platform_bin" ) > /dev/null 2>&1
	_mm_output=$( "$_platform_bin" --config "$_platform_config" user create --username "$_user" --email "$_email" --firstname "$_firstname" --lastname "$_lastname" --locale "$_locale" --nickname "$_nickname" --password "$_password" 2>&1 )
        echo -e "$_mm_output" >&2
	if echo -e "$_mm_output" | grep -i "^Created User" >/dev/null 2>&1
	then
		logger -st "mm-createuser" "Created user $_user with the password ($_password)"
		_rc=0
	fi

	if [ -n "$_default_team" ]; then
	        if "$_platform_bin" --config "$_platform_config" team add "$_default_team" "$_user" >&2
        	then
                	logger -st "mm-createuser" "User $_user added to default Team ($_default_team)"
        	fi
	fi
        popd > /dev/null 2>&1
	exit $_rc
fi

exit 1
