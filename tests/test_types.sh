source $(dirname ${BASH_SOURCE})/../cmdarg.sh

function shunittest_array_undefined()
{
    # Tests that cmdarg and cmdarg_parse return an error when an array
    # is undefined
    cmdarg_purge
    err=$(cmdarg 'a:[]' 'missingarray' 2>&1)
    if [[ $? -eq 0 ]]; then
	echo "cmdarg fails to throw an error for undefined array variables"
    else
	echo "$err" | grep "Array variable missingarray does not exist" >/dev/null
	if [[ $? -ne 0 ]]; then
	    echo "cmdarg does not report errors on stderr for undefined arrays"
	    echo "$err"
	    return 1
	fi
    fi
    return 0
}

function shunittest_array_values
{
    cmdarg_purge
    declare -a array
    cmdarg 'a:[]' 'array'
    cmdarg_parse -a a -a b -a c
    if [[ "${array[@]}" != "a b c" ]]; then
    	echo "Array does not contain expected arguments"
    	cmdarg_dump >&2
    	return 1
    fi
    return $?
}

function shunittest_hash_undefined()
{
    # Tests that cmdarg and cmdarg_parse return an error when an array
    # is undefined
    cmdarg_purge
    err=$(cmdarg 'a:{}' 'missingarray' 2>&1)
    if [[ $? -eq 0 ]]; then
	echo "cmdarg fails to throw an error for undefined hash variables"
    else
	echo "$err" | grep "Hash variable missingarray does not exist" >/dev/null
	if [[ $? -ne 0 ]]; then
	    echo "cmdarg does not report errors on stderr for undefined hashes"
	    echo "$err"
	    return 1
	fi
    fi
    return 0
}

function shunittest_hash_values
{
    cmdarg_purge
    declare -A hash
    cmdarg 'H:{}' 'hash'
    cmdarg_parse -H a=1 -H b=2 -H c=3
    base="a=1 b=2 c=3"
    cmp=""
    for k in a b c
    do
	cmp="$cmp ${k}=${hash[$k]}"
    done
    cmp=$(echo "$cmp" | sed s/'^ *'//)
    if [[ "$cmp" != "$base" ]]; then
    	echo "Hash does not contain expected arguments ($cmp vs $base)"
    	cmdarg_dump >&2
    	return 1
    fi
    return $?
}