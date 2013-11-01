source $(dirname ${BASH_SOURCE})/../cmdarg.sh

function shunittest_clean_state_usable()
{
    function parse1()
    {
	cmdarg 'a:' 'a' 'some arg'
	cmdarg 'b' 'b' 'some arg'
	cmdarg_parse "$@"
    }

    function parse2()
    {
	cmdarg_purge
	cmdarg 'c:' 'c' 'some arg'
	cmdarg 'd' 'd' 'some arg'
	cmdarg_parse "$@"
    }
    parse1 -a 3 -b
    parse2 -c 5 -d
    [[ "${cmdarg_cfg['c']}" == "5" ]] || return 1
    [[ "${cmdarg_cfg['d']}" == "true" ]] || return 1
    [[ "${cmdarg_cfg['a']}" == "" ]] || return 1
    [[ "${cmdarg_cfg['b']}" == "" ]] || return 1
    return 0
}

function shunittest_clean_state()
{
    # Tests that cmdarg_purge ensures an empty config state
    function parse1()
    {
	cmdarg 'a:' 'a' 'some arg'
	cmdarg 'b' 'b' 'some arg'
	cmdarg_parse "$@"
    }

    function parse2()
    {
	cmdarg_purge
	cmdarg_parse "$@"
    }

    # This cleans the state from shunit
    cmdarg_purge
    parse1 -a 3 -b
    parse2
    if [[ "${cmdarg_cfg['a']}" == "" ]]; then
	return 0
    else
	cmdarg_dump
	return 1
    fi
}

function shunittest_clean_state_subshells()
{
    # Ensures that, when subsequent cmdarg invocations occur in subshells,
    # that the initial state is empty even without having called cmdarg_purge

    # This is just here to clean the state from shunit
    cmdarg_purge
    function parse1()
    {
	cmdarg 'a:' 'a' 'some arg'
	cmdarg 'b' 'b' 'some arg'
	cmdarg_parse "$@"
    }

    function parse2()
    {
	cmdarg_parse "$@"
    }

    (parse1 -a 3 -b)
    (parse2)
    if [[ "${cmdarg_cfg['a']}" == "" ]]; then
	return 0
    else
	cmdarg_dump
	return 1
    fi
}
