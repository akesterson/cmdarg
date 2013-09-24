#!/bin/bash

bashversion=$(bash --version | head -n 1 | grep "version [0-9]" | cut -d ' ' -f 2)
if [ $bashversion -lt 4 ]; then
    echo "cmdarg is incompatible with bash versions < 4.0, please upgrade bash" >&2
    exit 1
fi

CMDARG_FLAG_WITHARG=1

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
    if [[ "${1:1:2}" == ":" ]]; then
	CMDARG_FLAGS[$shortopt]=$CMDARG_FLAG_WITHARG
    else
	CMDARG_FLAGS[$shortopt]=0
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
	    local default=""
	    if [ "${CMDARG_DEFAULT[$key]}" != "" ]; then
		default="(Default \"${CMDARG_DEFAULT[$key]}\")"
	    fi
	    echo "    -${key} : ${CMDARG_DESC[$key]} $default"
	done
	echo
    fi
    if [[ "${!CMDARG_OPTIONAL[@]}" != "" ]]; then
	echo "Optional Arguments:"
	for key in "${CMDARG_OPTIONAL[@]}"
	do
	    local default=""
	    if [ "${CMDARG_DEFAULT[$key]}" != "" ]; then
		default="(Default \"${CMDARG_DEFAULT[$key]}\")"
	    fi
	    echo "    -${key} : ${CMDARG_DESC[$key]} $default"
	done
    fi
    echo
    echo "${CMDARG_INFO['footer']}"
}

function cmdarg_parse
{
    # cmdarg_parse "$@"
    #
    # Call it EXACTLY LIKE THAT, and it will parse your arguments for you.
    # This function only knows about the arguments that you previously called 'cmdarg' for.
    local OPTIND
    local ARGS="$@"

    while getopts "$CMDARG_GETOPTLIST" opt $ARGS; do
    	if [ "$opt" == "h" ]; then
	    cmdarg_usage
    	    exit 1
    	elif [ ${CMDARG["${opt}"]+abc} ]; then
	    if [ ${CMDARG_FLAGS[${opt}]} -eq 0 ]; then
		cmdarg_cfg[${CMDARG[$opt]}]=true
	    else
    		cmdarg_cfg[${CMDARG[$opt]}]=$OPTARG
	    fi
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
	if [[ "${cmdarg_cfg[${CMDARG[$key]}]}" == "" ]]; then
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

if [[ "${_DEFINED_CMDARG}" == "" ]]; then
    export _DEFINED_CMDARG=0
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
    CMDARG_GETOPTLIST="h"
fi
