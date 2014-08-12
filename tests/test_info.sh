#!/usr/bin/bash4

source $(dirname ${BASH_SOURCE[0]})/../cmdarg.sh

function shunittest_info_reject_invalid
{
    cmdarg_purge
    cmdarg_info INVALID_SECTION || return 0
}

function shunittest_info_accept_valid
{
    set -e
    cmdarg_purge
    cmdarg_info header 'Some header from the info'
    cmdarg_parse --help 2>&1 | grep 'Some header from the info'
    set +e
}
