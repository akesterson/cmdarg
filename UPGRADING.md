Upgrade notes for 1.0 users
===========================

cmdarg 2.0 has refined some features that will break your 1.0 software if you do not prepare your codebase for this new functionality.

## argument validators

In 1.0, argument validators were a somewhat documented, but unpublished feature of the 'cmdarg' function. In cmdarg 2.0, they are fully documented and supported. However, their usage has changed, in that free-form bash statements are no longer accepted for validation, and OPTARG is no longer guaranteed to be set in the environment. You should transform any and all validation expressions from this format:

    cmdarg 'x' 'some-arg' 'some description' '' 'echo $OPTARG | grep ...'

... To this format:

    function my_grep_validator {
        echo $1 | grep ...
    }

    cmdarg 'x' 'some-arg' 'some description' '' my_grep_validator

Failure to do this will result in cmdarg 2.0 refusing to parse your argument descriptions, preventing your scripts from running.
