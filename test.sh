#!/usr/bin/bash4

declare -a cfg_array
declare -A cfg_hash

source ./cmdarg.sh

cmdarg 'b' 'boolean' 'A boolean argument'
cmdarg 's:' 'string' 'A string argument'
cmdarg 'a:[]' 'cfg_array' 'An array argument'
cmdarg 'H:{}' 'cfg_hash' 'A hash argument'

cmdarg_parse "$@"

cmdarg_dump
