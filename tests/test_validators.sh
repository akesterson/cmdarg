#!/usr/bin/bash4

source $(dirname ${BASH_SOURCE[0]})/../cmdarg.sh

function shunittest_validator_for_hash
{
    function my_hash_validator
    {
	value=${1:-$OPTARG}
	echo "my_hash_validator $value" >&2
	[[ "$value" == "value" ]]
    }

    declare -A something

    cmdarg_purge
    cmdarg 'x:{}' 'something' 'something' '' my_hash_validator || return 1
    set -x
    cmdarg_parse --something key=notavalue && return 1
    return 0
}

function shunittest_validator_for_array
{
    function my_array_validator
    {
	value=${1:-$OPTARG}
	echo "my_array_validator $value" >&2
	[[ "$value" == "value" ]]
    }

    declare -a something

    cmdarg_purge
    cmdarg 'x:[]' 'something' 'something' '' my_array_validator || return 1
    cmdarg_parse --something notavalue && return 1
    return 0
}

function shunittest_validator_failure_recognized
{

    function my_validator
    {
	value=${1:-$OPTARG}
	echo "my_validator $value" >&2
	[[ "$value" == "value" ]]
    }

    cmdarg_purge
    cmdarg 'x:' 'something' 'something' '' my_validator
    cmdarg_parse --something notavalue || return 0
    return 1
}

function shunittest_validator_works_with_set_e
{
    set -e

    function my_validator
    {
	value=${1:-$OPTARG}
	echo "my_validator $value" >&2
	[[ "$value" == "value" ]]
    }

    cmdarg_purge
    cmdarg 'x:' 'something' 'something' '' my_validator
    cmdarg_parse --something notavalue || return 0
    return 1

    set +e
}
