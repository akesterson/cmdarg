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

function shunittest_longopt_usage_messages_string
{
    cmdarg_purge
    cmdarg 'l:' 'long-required-opt' 'Some long opt that requires a value'
    output=$(cmdarg_parse -h 2>&1 | grep -- '-l,--long-required-opt v : String. Some long opt that requires a value')
    [[ "$output" != "" ]] || return 1
}

function shunittest_longopt_usage_messages_boolean
{
    cmdarg_purge
    cmdarg 'l' 'long-boolean-opt' 'Some long boolean opt'
    output=$(cmdarg_parse -h 2>&1 | grep -- '-l,--long-boolean-opt : Boolean. Some long boolean opt')
    [[ "$output" != "" ]] || return 1
}

function shunittest_longopt_usage_messages_array
{
    cmdarg_purge
    declare -a long_array_opt
    cmdarg 'l:[]' 'long_array_opt' 'Some long array opt'
    output=$(cmdarg_parse -h 2>&1 | grep -- '-l,--long_array_opt v')
    [[ "$output" != "" ]] || return 1
}

function shunittest_longopt_usage_messages_hash
{
    cmdarg_purge
    declare -A long_hash_opt
    cmdarg 'l:{}' 'long_hash_opt' 'Some long hash opt'
    output=$(cmdarg_parse -h 2>&1 | grep -- '-l,--long_hash_opt k=v')
    [[ "$output" != "" ]] || (cmdarg_parse ; return 1)
}
