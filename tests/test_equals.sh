#!/bin/bash

source $(dirname ${BASH_SOURCE[0]})/../cmdarg.sh

function shunittest_test_equals_parsing_shortopt
{
    cmdarg_purge
    cmdarg 'x:' 'example' 'just an example'
    set -x
    cmdarg_parse -x=3
    set +x
    [[ ${cmdarg_cfg['example']} -eq 3 ]] || return 1
}

function shunittest_test_equals_parsing_longopt
{
    cmdarg_purge
    cmdarg 'x:' 'example' 'just an example'
    set -x
    cmdarg_parse --example=3
    set +x
    [[ ${cmdarg_cfg['example']} -eq 3 ]] || return 1
}