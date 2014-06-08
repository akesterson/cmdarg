#!/usr/bin/bash4

source $(dirname ${BASH_SOURCE[0]})/../cmdarg.sh

function shunittest_test_usage_helper
{
    function usage_helper
    {
	echo "LOL I AM A HELPER"
	return 0
    }
    function parser {
	cmdarg_purge
	cmdarg_helpers['usage']=usage_helper
	cmdarg_parse --help
    }
    [[ "$(parser 2>&1)" == "LOL I AM A HELPER" ]] || return 1
}

function shunittest_test_describe_helper
{
    function always_succeed
    {
	return 0
    }

    function describe
    {
	set -u
	local longopt opt argtype default description
	longopt=$1
	opt=$2
	argtype=$3
	default="$4"
	description="$5"
	flags="$6"
	validator="$7"
	set +u

	echo "${opt}:${longopt}:${argtype}:${description}:${default}:${flags}:${validator}"
    }
    function parser
    {
	declare -a array
	declare -A hash
	cmdarg_purge
	cmdarg_helpers['describe']=describe
	cmdarg 's:' 'string' 'some string' '12345' always_succeed
	cmdarg 'b' 'boolean' 'some boolean'
	cmdarg 'a?[]' 'array' 'some array'
	cmdarg 'H?{}' 'hash' 'some hash'
	set -x
	[[ "$(cmdarg_describe s)" == "s:string:${CMDARG_TYPE_STRING}:some string:12345:${CMDARG_FLAG_REQARG}:always_succeed" ]] || return 1
	[[ "$(cmdarg_describe b)" == "b:boolean:${CMDARG_TYPE_BOOLEAN}:some boolean::${CMDARG_FLAG_NOARG}:" ]] || return 1
	[[ "$(cmdarg_describe a)" == "a:array:${CMDARG_TYPE_ARRAY}:some array::${CMDARG_FLAG_OPTARG}:" ]] || return 1
	[[ "$(cmdarg_describe H)" == "H:hash:${CMDARG_TYPE_HASH}:some hash::${CMDARG_FLAG_OPTARG}:" ]] || return 1
	set +x
    }
    parser
}

# This test adds no value to the test suite, it simply serves as an example of how to override
# both the describe AND usage helpers
function shunittest_test_describe_and_usage_helper
{
    function always_succeed
    {
	return 0
    }

    function describe
    {
	set -u
	local longopt opt argtype default description
	longopt=$1
	opt=$2
	argtype=$3
	default="$4"
	description="$5"
	flags="$6"
	validator="$7"
	set +u

	echo "${opt}:${longopt}:${argtype}:${description}:${default}:${flags}:${validator}"
    }

    function usage
    {
	echo "I ignore the default header and footer, and substitute my own."
	echo "I do not indent my arguments or separate optional and required."

	# cmdarg helpfully separates options into OPTIONAL or REQUIRED arrays
	# so that you don't have to sort the keys for uniform --help message output
	# and so you can easily break arguments out into required/optional blocks
	# in the usage message ... our helper doesn't care, it just prints them all
	# together, but it still uses the sorted lists.

	for shortopt in ${CMDARG_OPTIONAL[@]} ${CMDARG_REQUIRED[@]}
	do
	    cmdarg_describe $shortopt
	done
    }

    function parser
    {
	declare -a array
	declare -A hash
	cmdarg_purge
	cmdarg_helpers['describe']=describe
	cmdarg_helpers['usage']=usage
	cmdarg 's:' 'string' 'some string' '12345' always_succeed
	cmdarg 'b' 'boolean' 'some boolean'
	cmdarg 'a?[]' 'array' 'some array'
	cmdarg 'H?{}' 'hash' 'some hash'
	cmdarg_parse --help
    }
    output="I ignore the default header and footer, and substitute my own.
I do not indent my arguments or separate optional and required.
s:string:${CMDARG_TYPE_STRING}:some string:12345:${CMDARG_FLAG_REQARG}:always_succeed
b:boolean:${CMDARG_TYPE_BOOLEAN}:some boolean::${CMDARG_FLAG_NOARG}:
a:array:${CMDARG_TYPE_ARRAY}:some array::${CMDARG_FLAG_OPTARG}:
H:hash:${CMDARG_TYPE_HASH}:some hash::${CMDARG_FLAG_OPTARG}:"

    set +e
    capture="$(parser 2>&1)"
    if [[ "${capture}" != "$output" ]]; then
	echo "${capture}" > /tmp/$$.parser 2>&1
	echo "${output}" > /tmp/$$.output
	diff -y /tmp/$$.output /tmp/$$.parser
	return 1
    fi
    set -e
}
