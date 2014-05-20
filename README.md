cmdarg
======

[![Build Status](http://jenkins.aklabs.net/buildStatus/icon?job=cmdarg-test)](http://jenkins.aklabs.net/job/cmdarg-test/)

Requires bash >= 4.

    source cmdarg.sh

Enjoy

Installation
============

From source

    cd cmdarg
    make install

From RPM

    # add http://yum.aklabs.net/el/[5|6]/noarch as a yum repo for your system
    yum install cmdarg

Usage
=====

cmdarg is a helper library I wrote for bash scripts because, at current, option parsing in bash (-foo bar, etc) is really hard, lots harder than it should be, given bash's target audience. So here's my solution. There are 4 functions you will care about:

    cmdarg
    cmdarg_info
    cmdarg_parse
    cmdarg_usage

TL;DR
=====

Cmdarg lets you specify arguments (things you require), options (things you don't require), and lets you easily parse them. The arguments can be set on the command line either via '-X' or '--Y', where X is the short option and Y is the long option.

    cmdarg 'r:' 'required-thing' 'Some thing I require'
    cmdarg 'o?' 'optional-thing' 'Some optional thing'
    cmdarg 'b' 'boolean-thing' 'Some boolean thing'
    cmdarg_parse "$@"

    echo ${cmdarg_cfg['required-thing']}
    echo ${cmdarg_cfg['optional-thing']}
    echo ${cmdarg_cfg['boolean-thing']}

    # your_script.sh -r some_thingy -b -o optional_thing
    # your_script.sh --required-thing some_thingy --boolean-thing

Because cmdarg does key off of the short options, you are limited to as many options as you have unique single characters in your character set (likely 61 - 26 lower & upper alpha, +9 numerics).

cmdarg
======

This function is used to tell the library what command line arguments you accept.

    cmdarg FLAGS LONGOPT DESCRIPTION DEFAULT VALIDATOR

Examples:

    cmdarg 'f' 'boolean-flag' 'Some boolean flag'
    cmdarg 'a:' 'required-arg' 'Some required arg'
    cmdarg 'a?' 'optional-arg' 'Some optional arg with a default' 'default_value'
    cmdarg 'a:' 'required-validated-arg' 'Some required argument with a validator' '' validator_function

*FLAGS* : The first argument to cmdarg must be an argument specification. Argument specifications take the form 'NOT', where:

- N : The single letter Name of the argument
- O : Whether the option is optional or not. Use ':' here for a required argument, '?' for an optional argument. If you provide a default value for a required argument (:), then it becomes optional.
- T : The type. Leave empty for a string argument, use '[]' for an array argument, use '{}' for a hash argument.

If O and T are both unset, and only the single letter N is provided, then the argument is a boolean argument which will default to false.

*LONGOPT* is a long option name (such as long-option-name) that can be used to set your argument via --LONGOPT instead of via -N (from your FLAGS).

*DESCRIPTION* is a string that describes what this argument is for.

*DEFAULT* is any default value that you want to be set for this option if the user does not specify one

*VALIDATOR* The name of a bash function which will validate this argument (see VALIDATORS below).


Validators
==========

Validators must be bash function names - not bash statements - and they must accept one argument, being the value to validate. Validators are not told the name of the option, only the value. Validator functions must return 0 if they value they are given is valid, and 1 if it is invalid. Validators should refrain from producing output on stdout or stderr.

For example, this is a valid validator:

    function validate_int
    {
        echo "$1" | grep -E '^[0-9]+$'
    }

    cmdarg 'x' 'x-option' 'some opt' '' validate_int

... While this is not:

    cmdarg 'x' 'x-option' 'some opt' '' "grep -E '^[0-9]+$'"

cmdarg_info
===========

This function sets up information about your program for use when printing the help/usage message. Again, see cmdarg.sh for the latest syntax.

    cmdarg_info "header" "Some script that needed argument parsing"
    cmdarg_info "author" "Some Poor Bastard <somepoorbastard@hell.com>"
    cmdarg_info "copyright" "(C) 2013"

cmdarg_parse
============

This command does what you expect, parsing your command line arguments. However you must pass your command line arguments to it. Generally this means:

    cmdarg_parse "$@"

... Beware that "$@" will change depending on your context. So if you have a main() function called in your script, you need to make sure that you pass "$@" from the toplevel script in to it, otherwise the options will be blank when you pass them to cmdarg_parse.

Any argument parsed that has a validator assigned, and whose validator returns nonzero, is considered a failure. Any REQUIRED argument that is not specified is considered a failure. However, it is worth noting that if a required argument has a default value, and you provide an empty value to it, we won't know any better and that will be accepted (how do we know you didn't actually *mean* to do that?).

For every argument integer, boolean or string argument, a global associative array "cmdarg_cfg" is populated with the long version of the option. E.g., in the example above, '-c' would become ${cmdarg_cfg['groupmap']}, for friendlier access during scripting.

    cmdarg 'x:' 'some required thing'
    cmdarg_parse "$@"
    echo ${cmdarg_cfg['x']}

For array and hash arguments, you must declare the hash or array beforehand for population:

    declare -a myarray
    cmdarg 'a?[]' 'myarray' 'Some array of stuff'
    cmdarg_parse "$@"
    # Now you will be able to access ${myarray[0]}, ${myarray[1]}, etc. Similarly with hashes, just use declare -A and {}.

Automatic help messages
=======================

cmdarg takes the pain out of creating your --help messages. For example, consider you had this script:

    #!/bin/bash
    source /usr/lib/cmdarg.sh
    declare -a myarray

    cmdarg_info "header" "Some script that needed argument parsing"
    cmdarg_info "author" "Some Poor Bastard <somepoorbastard@hell.com>"
    cmdarg_info "copyright" "(C) 2013"
    cmdarg 'R:' 'required-thing' 'Some thing I REALLY require'
    cmdarg 'r:' 'required-thing-with-default' 'Some thing I require' 'Some default'
    cmdarg 'o?' 'optional-thing' 'Some optional thing'
    cmdarg 'b' 'boolean-thing' 'Some boolean thing'
    cmdarg 'a?[]' 'myarray' 'Some array of stuff'
    cmdarg_parse "$@"

... And you ran it with '--help', you would get a nice preformatted help message:

    test.sh (C) 2013 : Some Poor Bastard <somepoorbastard@hell.com>

    Some script that needed argument parsing

    Required Arguments:
        -R,--required-thing v : String. Some thing I REALLY require

    Optional Arguments:
        -r,--required-thing-with-default v : String. Some thing I require (Default "Some default")
        -o,--optional-thing v : String. Some optional thing
        -b,--boolean-thing : Boolean. Some boolean thing
        -a,--myarray v[, ...] : Array. Some array of stuff. Pass this argument multiple times for multiple values.

Setting arrays and hashes
=========================

You can use the cmdarg function to accept arrays and hashes from the command line as well. Consider:

    declare -a array
    declare -A hash
    cmdarg 'a?[]' 'array' 'Some array you can set indexes in'
    cmdarg 'H?{}' 'hash' 'Some hash you can set keys in'


    your_script -a 32 --array something -H key=value --hash other_key=value


    echo ${array[0]}
    echo ${array[1]}
    echo ${hash['key']}
    echo ${hash['other_key']}

The long option names in this form must equal the name of a previously declared array or hash, appropriately. Cmdarg populates that variable directly with options for these arguments. Remember, arrays and hashes must be declared beforehand and must have the same name as the long argument given to their cmdarg option.

Positional arguments and --
===========================

Like any good option parsing framework, cmdarg understands '--' and positional arguments that are meant to be provided without any kind of option parsing applied to them. So if you have:

    myscript.sh -x 0 --longopt thingy file1 file2

... It would seem reasonable to assume that -x and --longopt would be parsed as expected; with arguments of 0 and thingy. But what to do with file1 and file2? cmdarg puts those into a bash indexed array called cmdarg_argv.

Similarly, cmdarg understands '--' which means "stop processing arguments, the rest of this stuff is just to be passed to the program directly". So in this case:

    myscript.sh -x 0 --longopt thingy -- --some-thing-with-dashes

... Cmdarg would parse -x and --longopt as expected, and then ${cmdarg_argv[0]} would hold "--some-thing-with-dashes", for your program to do with what it will.

getopt vs getopts
=================

cmdarg does not use getopt or getopts for option parsing. Its parser is written in 100% pure bash, and is self contained in cmdarg_parse. It will run the same way anywhere you have bash4.

Tests
=====

cmdarg is testable by the shunit bash unit testing tool (https://www.github.com/akesterson/shunit/). See the tests/ directory.
