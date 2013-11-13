#!/usr/bin/bash4

source $(dirname ${BASH_SOURCE[0]})/../cmdarg.sh

function shunittest_longopt
{
    cmdarg_purge
    cmdarg 'l:' 'long-required-opt' 'Some long opt that requires a value'
    cmdarg 'o' 'long-boolean-opt' 'Some long option that is boolean'
    cmdarg 'L:' 'long-required-default-opt' 'Some long opt that requires a value but has a default' '(nil)'

    cmdarg_parse --long-required-opt hooha --long-boolean-opt

    [[ "${cmdarg_cfg['long-required-opt']}" == "hooha" ]] || return 1
    [[ "${cmdarg_cfg['long-boolean-opt']}" == "true" ]] || return 1
    [[ "${cmdarg_cfg['long-required-default-opt']}" == "(nil)" ]] || return 1
}

function shunittest_longopt_shortopts_still_work
{
    cmdarg_purge
    cmdarg 'l:' 'long-required-opt' 'Some long opt that requires a value'
    cmdarg 'o' 'long-boolean-opt' 'Some long option that is boolean'
    cmdarg 'L:' 'long-required-default-opt' 'Some long opt that requires a value but has a default' '(nil)'

    cmdarg_parse -l hooha -o

    [[ "${cmdarg_cfg['long-required-opt']}" == "hooha" ]] || return 1
    [[ "${cmdarg_cfg['long-boolean-opt']}" == "true" ]] || return 1
    [[ "${cmdarg_cfg['long-required-default-opt']}" == "(nil)" ]] || return 1
}