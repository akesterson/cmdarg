#!/bin/bash

bashversion=$(${BASH} --version | head -n 1 | grep -o "version [0-9]" | cut -d ' ' -f 2)
if [ $bashversion -lt 4 ]; then
    echo "cmdarg is incompatible with bash versions < 4.0, please upgrade bash" >&2
    exit 1
fi


CMDARG_FLAG_NOARG=0
CMDARG_FLAG_WITHARG=1

CMDARG_TYPE_ARRAY=1
CMDARG_TYPE_HASH=2
CMDARG_TYPE_STRING=3
CMDARG_TYPE_BOOLEAN=4

function cmdarg
{
    # cmdarg <option> <key> <description> [default value] [validator function]
    #
    # option : The short name (single letter) of the option
    # key : The long key that should be placed into cmdarg_cfg[] for this option
    # description : The text description for this option to be used in cmdarg_usage
    #
    # default value : The default value, if any, for the argument
    # validator : This is passed through eval(), with $OPTARG equal to the current
    #             value of the argument in question, and must return non-zero if
    #             the argument value is invalid. Can be straight bash, but it really
    #             should be the name of a function. This may be enforced in future versions
    #             of the library.
    shortopt=${1:0:1}
    key="$2"
    if [[ "$shortopt" == "h" ]]; then
	echo "-h is reserved for cmdarg usage" >&2
	exit 1
    fi
    if  [[ "$(type -t cmdarg_$key)" != "" ]] || \
	[[ "${CMDARG_FLAGS[$shortopt]}" != "" ]] || \
	[[ "${CMDARG_TYPES[$key]}" != "" ]]; then
	echo "command line key '$shortopt ($key)' is reserved by cmdarg or defined twice" >&2
	exit 1
    fi

    if [[ "${1:1:1}" == ":" ]]; then
	CMDARG_FLAGS[$shortopt]=$CMDARG_FLAG_WITHARG
	if [[ "${1:2:4}" == "[]" ]]; then
	    declare -p ${key} >/dev/null 2>&1
	    if [[ $? -ne 0 ]]; then
		echo 'Array variable '"${key}"' does not exist. Array variables MUST be declared by the user!' >&2
		exit 1
	    fi
	    CMDARG_TYPES[$key]=$CMDARG_TYPE_ARRAY
	elif [[ "${1:2:4}" == "{}" ]]; then
	    declare -p ${key} >/dev/null 2>&1
	    if [[ $? -ne 0 ]]; then
		echo 'Hash variable '"${key}"' does not exist. Hash variables MUST be declared by the user!' >&2
		exit 1
	    fi
	    CMDARG_TYPES[$key]=$CMDARG_TYPE_HASH
	else
	    CMDARG_TYPES[$key]=$CMDARG_TYPE_STRING
	fi
    else
	CMDARG_FLAGS[$shortopt]=$CMDARG_FLAG_NOARG
	CMDARG_TYPES[$key]=$CMDARG_TYPE_BOOLEAN
	cmdarg_cfg[$key]=false
    fi

    CMDARG["$shortopt"]=$2
    CMDARG_REV["$2"]=$shortopt
    CMDARG_DESC["$shortopt"]=$3
    CMDARG_DEFAULT["$shortopt"]=${4:-}
    if [[ ${CMDARG_FLAGS[$shortopt]} -eq $CMDARG_FLAG_WITHARG ]] && [[ "${4:-}" == "" ]]; then
	CMDARG_REQUIRED+=($shortopt)
    else
	CMDARG_OPTIONAL+=($shortopt)
    fi
    cmdarg_cfg["$2"]="${4:-}"
    CMDARG_VALIDATORS["$shortopt"]="${5:-}"
    CMDARG_GETOPTLIST="${CMDARG_GETOPTLIST}$1"
}

function cmdarg_info
{
    # cmdarg <flag> <value>
    #
    # Sets various flags about your script that are printed during cmdarg_usage
    #
    FLAGS="header|copyright|footer|author"
    echo "$1" | grep -E "$FLAGS" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
	echo "cmdarg_info <flag> <value>" >&2
	echo "Where <flag> is one of $FLAGS" >&2
	exit 1
    fi
    CMDARG_INFO["$1"]=$2
}

function cmdarg_describe
{
    local key default
    longopt=${CMDARG[$1]}
    opt=$1
    if [ "${CMDARG_DEFAULT[$opt]}" != "" ]; then
	default="(Default \"${CMDARG_DEFAULT[$opt]}\")"
    fi
    case ${CMDARG_TYPES[$longopt]} in
	$CMDARG_TYPE_STRING)
	    echo "-${opt} v : String. ${CMDARG_DESC[$opt]} $default"
	    ;;
	$CMDARG_TYPE_BOOLEAN)
	    echo "-${opt} : Boolean. ${CMDARG_DESC[$opt]} $default"
	    ;;
	$CMDARG_TYPE_ARRAY)
	    echo "-${opt} v[, ...]  : Array. ${CMDARG_DESC[$opt]}. Pass this argument multiple times for multiple values. $default"
	    ;;
	$CMDARG_TYPE_HASH)
	    echo "-${opt} k=v{, ..} : Hash. ${CMDARG_DESC[$opt]}. Pass this argument multiple times for multiple key/value pairs. $default"
	    ;;
	*)
	    echo "Unable to return string description for ${key}; unknown type ${CMDARG_TYPES[$opt]}" >&2
	    exit 1
	    ;;
    esac
}

function cmdarg_usage
{
    # cmdarg_usage
    #
    # Prints a very helpful usage message about the current program.
    echo "$(basename $0) ${CMDARG_INFO['copyright']} : ${CMDARG_INFO['author']}"
    echo
    echo "${CMDARG_INFO['header']}"
    echo
    local key
    if [[ "${!CMDARG_REQUIRED[@]}" != "" ]]; then
	echo "Required Arguments:"
	for key in "${CMDARG_REQUIRED[@]}"
	do
	    echo "    $(cmdarg_describe $key)"
	done
	echo
    fi
    if [[ "${!CMDARG_OPTIONAL[@]}" != "" ]]; then
	echo "Optional Arguments":
	for key in "${CMDARG_OPTIONAL[@]}"
	do
	    echo "    $(cmdarg_describe $key)"
	done
    fi
    echo
    echo "${CMDARG_INFO['footer']}"
}

function cmdarg_set_opt
{
    local key arg
    key=$1
    arg="$2"
    case ${CMDARG_TYPES[$key]} in
	$CMDARG_TYPE_STRING)
	    cmdarg_cfg[$key]=$OPTARG
	    ;;
	$CMDARG_TYPE_BOOLEAN)
	    cmdarg_cfg[$key]=true
	    ;;
	$CMDARG_TYPE_ARRAY)
	    arrname="${key}"
	    str='${#'"$arrname"'[@]}'
	    prevlen=$(eval "echo $str")
	    eval "${arrname}[$((prevlen + 1))]=\"$arg\""
	    ;;
	$CMDARG_TYPE_HASH)
	    arrname="${key}"
	    # Want to know WTF I named this variable like this?
	    # http://stackoverflow.com/questions/10258686/bash-associative-array-error
	    # ... Apparently there is a bug in bash.
	    cmdarghashkeythingy31337=$(echo "$arg" | cut -d = -f 1)
	    v=$(echo "$arg" | cut -d = -f 2-)
	    lval="${arrname}['${cmdarghashkeythingy31337}']"
	    eval "$lval=\"$v\""
	    ;;
	*)
	    echo "Unable to return string description for ${key}; unknown type ${CMDARG_TYPES[$key]}" >&2
	    exit 1
	    ;;
    esac
}

function cmdarg_check_empty
{
    local key longopt
    key=$1
    longopt=${CMDARG[$key]}
    type=${CMDARG_TYPES[$longopt]}

    case $type in
	$CMDARG_TYPE_STRING)
            echo ${cmdarg_cfg[$longopt]}
            ;;
	$CMDARG_TYPE_BOOLEAN)
	    echo ${cmdarg_cfg[$longopt]}
	    ;;
	$CMDARG_TYPE_ARRAY)
	    arrname="${longopt}"
	    lval='${!'"${arrname}"'[@]}'
	    eval "echo $lval"
	    ;;
	$CMDARG_TYPE_HASH)
	    arrname="${longopt}"
	    lval='${!'"${arrname}"'[@]}'
	    eval "echo $lval"
	    ;;
	*)
	    echo "${cmdarg_cfg[$longopt]}"
	    ;;
    esac
}

function cmdarg_parse
{
    # cmdarg_parse "$@"
    #
    # Call it EXACTLY LIKE THAT, and it will parse your arguments for you.
    # This function only knows about the arguments that you previously called 'cmdarg' for.
    local OPTIND

    while getopts "$CMDARG_GETOPTLIST" opt "$@"; do
    	if [ "$opt" == "h" ]; then
	    cmdarg_usage
    	    exit 1
    	elif [ ${CMDARG["${opt}"]+abc} ]; then
	    cmdarg_set_opt "${CMDARG[$opt]}" "$OPTARG"
    	else
    	    cmdarg_usage
    	    exit 1
    	fi
	OPTARG=""
    done

    # --- Don't exit early during validation, tell the user
    # everything they did wrong first
    failed=0
    missing=""

    for key in "${CMDARG_REQUIRED[@]}"
    do
	if [[ "$(cmdarg_check_empty $key)" == "" ]]; then
	    missing="${missing} -${key}"
	    failed=1
	fi
    done

    local opt
    local optarg
    for opt in "${!cmdarg_cfg[@]}"
    do
	shortopt=${CMDARG_REV[$opt]}
    	if [ "${CMDARG_VALIDATORS[$shortopt]}" != "" ]; then
    	    OPTARG=${cmdarg_cfg[$opt]}
	    ( eval "${CMDARG_VALIDATORS[${shortopt}]}" && [ "$OPTARG" != "" ])
	    if [ $? -ne 0 ]; then
		echo "Invalid value for -$shortopt : ${cmdarg_cfg[$opt]}"
		failed=1
	    fi
    	fi
    done
    if [ $failed -eq 1 ]; then
	if [[ "$missing" != "" ]]; then
	    echo "Missing arguments : ${missing}"
	fi
	echo
	cmdarg_usage
	exit 1
    fi

    if [ ! -z "${cmdarg_cfg[cfgfile]}" ]; then
	. ${cmdarg_cfg[cfgfile]}
    fi
}

function cmdarg_traceback
{
    # This code lifted from http://blog.yjl.im/2012/01/printing-out-call-stack-in-bash.html
    local i=0
    local FRAMES=${#BASH_LINENO[@]}
    # FRAMES-2 skips main, the last one in arrays
    for ((i=FRAMES-2; i>=1; i--)); do
	echo '  File' \"${BASH_SOURCE[i+1]}\", line ${BASH_LINENO[i]}, probably in ${FUNCNAME[i+1]} >&2
	# Grab the source code of the line
	sed -n "${BASH_LINENO[i]}{s/^/    /;p}" "${BASH_SOURCE[i+1]}" >&2
    done
    echo "  Error: $LASTERR"
    unset FRAMES
}

function cmdarg_dump
{
    for key in ${!cmdarg_cfg[@]}
    do
	repr="${key}:${CMDARG_TYPES[$key]}"
	if [[ ${CMDARG_TYPES[$key]} == $CMDARG_TYPE_ARRAY ]] || [[ ${CMDARG_TYPES[$key]} == $CMDARG_TYPE_HASH ]] ; then
	    arrname="${key}"
	    echo "${repr} => "
	    keys='${!'"$arrname"'[@]}'
	    for idx in $(eval "echo $keys")
	    do
		ref='${'"$arrname"'[$idx]}'
		value=$(eval "echo $ref")
		echo "        ${idx} => $value"
	    done
	else
	    echo "${repr} => ${cmdarg_cfg[$key]}"
	fi
    done
}

function cmdarg_purge
{
    arrays="cmdarg_cfg CMDARG CMDARG_REV CMDARG_OPTIONAL CMDARG_REQUIRED"
    arrays="$arrays CMDARG_DESC CMDARG_DEFAULT CMDARG_VALIDATORS CMDARG_INFO"
    arrays="$arrays CMDARG_FLAGS CMDARG_TYPES"
    unset $arr
    unset $arr[*]
    CMDARG_GETOPTLIST="h"
}

# Holds the final map of configuration options
declare -A cmdarg_cfg
# Maps (short arg) -> (long arg)
declare -A CMDARG
# Maps (long arg) -> (short arg)
declare -A CMDARG_REV
# A list of optional arguments (e.g., no :)
declare -a CMDARG_OPTIONAL
# A list of required arguments (e.g., :)
declare -a CMDARG_REQUIRED
# Maps (short arg) -> (description)
declare -A CMDARG_DESC
# Maps (short arg) -> default
declare -A CMDARG_DEFAULT
# Maps (short arg) -> validator
declare -A CMDARG_VALIDATORS
# Miscellanious info about this script
declare -A CMDARG_INFO
# Map of (short arg) -> flags
declare -A CMDARG_FLAGS
# Map of (short arg) -> type (string, array, hash)
declare -A CMDARG_TYPES

if [[ "${CMDARG_GETOPTLIST}" == "" ]]; then
    CMDARG_GETOPTLIST="h"
fi
