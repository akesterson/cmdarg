#!/usr/bin/bash4

source $(dirname ${BASH_SOURCE[0]})/../cmdarg.sh

function shunittest_dashdash
{
    set -x
    cmdarg_purge
    cmdarg_parse -- lolzors something
    [[ "${cmdarg_argv[0]}" == "lolzors" ]] || return 1
    [[ "${cmdarg_argv[1]}" == "something" ]] || return 1
}

function shunittest_missing_dashdash
{
    set -x
    cmdarg_purge
    ( cmdarg_parse --lolzors ) || return 0
    return 1
}

function shunittest_withbool_missing_dashdash
{
    set -x
    cmdarg_purge
    cmdarg 'x' 'xray' 'thingy for xray'
    ( cmdarg_parse -x lolzors ) || return 0
    cmdarg_parse -x -- lolzors
}

function shunittest_withopt_with_dashdash
{
    set -x
    cmdarg_purge
    cmdarg 'x:' 'xray' 'thingy for xray'
    ( cmdarg_parse -x -- lolzors ) || return 0
}