#!/usr/bin/bash4

declare -a cmdarg_array
declare -A cmdarg_hash

source ./cmdarg.sh

cmdarg 'b' 'boolean' 'A boolean argument'
cmdarg 's:' 'string' 'A string argument'
cmdarg 'a:[]' 'array' 'An array argument'
cmdarg 'H:{}' 'hash' 'A hash argument'

cmdarg_parse "$@"

cmdarg_dump
