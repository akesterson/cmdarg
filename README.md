cmdarg
======

    source cmdarg.sh

Enjoy

Usage
=====

cmdarg is a helper library I wrote for bash scripts because, at current, option parsing in bash (-foo bar, etc) is really hard, lots harder than it should be, given bash's target audience. So here's my solution. There are 4 functions you will care about:

    cmdarg
    cmdarg_info
    cmdarg_parse
    cmdarg_usage

cmdarg
======

This function is used to tell the library what command line arguments you accept. Check cmdarg.sh for the latest syntax.

    cmdarg 'l:' 'source_ldap' 'Source (old) LDAP URI'
    cmdarg 'u:' 'source_ldap_username' 'Source (old) LDAP Username'
    cmdarg 'c:' 'groupmap' 'A CSV file mapping usernames to groups that they should belong to post-conversion' '' 'test -e $OPTARG'

All arguments are OPTIONAL by default. An argument that has ':' on the end of its single character option, and does not specify a default value (empty string is considered "not specified"), is REQUIRED.

cmdarg_info
===========

This function sets up information about your program for use when printing the help/usage message. Again, see cmdarg.sh for the latest syntax.

    cmdarg_info "header" "Convert existing LDAP users to the new LDAP server/schema."
    cmdarg_info "author" "Some Poor Bastard <somepoorbastard@hell.com>"
    cmdarg_info "copyright" "(C) 2013"

cmdarg_parse
============

This command does what you expect, parsing your command line arguments. However you must pass your command line arguments to it. Generally this means:

    cmdarg_parse "$@"

... Beware that "$@" will change depending on your context. So if you have a main() function called in your script, you need to make sure that you pass "$@" from the toplevel script in to it, otherwise the options will be blank when you pass them to cmdarg_parse.

Any argument parsed that has a validator assigned, and whose validator returns nonzero, is considered a failure. Any REQUIRED argument that is not specified is considered a failure.

For every argument, a global associative array "cmdarg_cfg" is populated with the long version of the option. E.g., in the example above, '-c' would become ${cmdarg_cfg['groupmap']}, for friendlier access during scripting.

I love it when a plan comes together
====================================

Given some code like this:

    cmdarg_info "header" "Convert existing old LDAP users to the new LDAP server/schema."
    cmdarg_info "author" "Some Poor Bastard <somepoorbastard@hell.com>"
    cmdarg_info "copyright" "(C) 2013"

    cmdarg 'C:' 'cfgfile' 'Config file that contains options that should be used in place of command line args' '' 'test -e $OPTARG'
    cmdarg 'c:' 'groupmap' 'A CSV file mapping usernames to groups that they should belong to post-conversion' '' 'test -e $OPTARG'
    cmdarg 'l:' 'source_ldap' 'Source (old) LDAP URI'
    cmdarg 'u:' 'source_ldap_username' 'Source (old) LDAP Username'
    cmdarg 'p:' 'source_ldap_password' 'Source (old) LDAP Password'
    cmdarg 'b:' 'source_ldap_basedn' 'Source (old) LDAP Base DN (ou=x,dc=x,dc=x)'
    cmdarg 'o:' 'source_ldap_ou_users' 'Source (old) LDAP ou for Users' 'users'
    cmdarg 'g:' 'source_ldap_ou_groups' 'Source (old) LDAP ou for Groups' 'groups'
    cmdarg 'L:' 'dest_ldap' 'Destination (new) LDAP URI'
    cmdarg 'U:' 'dest_ldap_username' 'Destination (new) LDAP Username'
    cmdarg 'P:' 'dest_ldap_password' 'Destination (new) LDAP Password'
    cmdarg 'B:' 'dest_ldap_basedn' 'Destination (new) LDAP Base DN (dc=x,dc=x)'
    cmdarg 'O:' 'source_ldap_ou_users' 'Destination (new) LDAP ou for Users' 'users'
    cmdarg 'G:' 'source_ldap_ou_groups' 'Destination (new) LDAP ou for Groups' 'groups'
    cmdarg 's:' 'slappasswd_salt' 'Slappasswd salt format (man slappasswd)' 'rofflewaffles%s'
    cmdarg 'S:' 'slappasswd_scheme' 'Slappasswwd hash scheme to use (CRYPT|MD5|SMD5|SSHA|SHA)' 'SSHA' 'echo $OPTARG | grep -E "CRYPT|MD5|SMD5|SSHA|SHA" >/dev/null 2>&1'

    cmdarg_parse "$@"

... Here's what we can expect to see from the usage message:

    $ ./ldap-convert.sh  -h
    ldap-convert.sh (C) 2013 : Some Poor Bastard <somepoorbastard@hell.com>

    Convert existing LDAP users to the new LDAP server/schema.

    Required Arguments:
	-C : Config file that contains options that should be used in place of command line args
	-c : A CSV file mapping usernames to groups that they should belong to post-conversion
	-l : Source (old) LDAP URI
	-u : Source (old) LDAP Username
	-p : Source (old) LDAP Password
	-b : Source (old) LDAP Base DN (ou=x,dc=x,dc=x)
	-L : Destination (new) LDAP URI
	-U : Destination (new) LDAP Username
	-P : Destination (new) LDAP Password
	-B : Destination (new) LDAP Base DN (dc=x,dc=x)

    Optional Arguments:
	-o : Source (old) LDAP ou for Users (Default "users")
	-g : Source (old) LDAP ou for Groups (Default "groups")
	-O : Destination (new) LDAP ou for Users (Default "users")
	-G : Destination (new) LDAP ou for Groups (Default "groups")
	-s : Slappasswd salt format (man slappasswd) (Default "rofflewaffles%s")
	-S : Slappasswwd hash scheme to use (CRYPT|MD5|SMD5|SSHA|SHA) (Default "SSHA")

... And if we run it without '-h', then the argument parser (rather helpfully) tells us which arguments we've failed to specify, before printing the help:

    $ ./ldap-convert.sh
    Invalid value for -c :
    Invalid value for -C :
    Missing arguments :  -C -c -l -u -p -b -L -U -P -B

    ldap-convert.sh (C) 2013 : Some Poor Bastard <somepoorbastard@hell.com>

    Convert existing LDAP users to the new LDAP server/schema.

    Required Arguments:
	-C : Config file that contains options that should be used in place of command line args
	-c : A CSV file mapping usernames to groups that they should belong to post-conversion
	-l : Source (old) LDAP URI
	-u : Source (old) LDAP Username
	-p : Source (old) LDAP Password
	-b : Source (old) LDAP Base DN (ou=x,dc=x,dc=x)
	-L : Destination (new) LDAP URI
	-U : Destination (new) LDAP Username
	-P : Destination (new) LDAP Password
	-B : Destination (new) LDAP Base DN (dc=x,dc=x)

    Optional Arguments:
	-o : Source (old) LDAP ou for Users (Default "users")
	-g : Source (old) LDAP ou for Groups (Default "groups")
	-O : Destination (new) LDAP ou for Users (Default "users")
	-G : Destination (new) LDAP ou for Groups (Default "groups")
	-s : Slappasswd salt format (man slappasswd) (Default "rofflewaffles%s")
	-S : Slappasswwd hash scheme to use (CRYPT|MD5|SMD5|SSHA|SHA) (Default "SSHA")

... And here's what the cmdarg_cfg associate array winds up holding, illustrated with some debug prints:

    $ ./ldap-convert.sh -c ./users_groups_map.csv -l 1 -u 1 -p 1 -b 1 -L 1 -U 1 -P 1 -B 1

    cmdarg_cfg[groupmap]="./users_groups_map.csv"
    cmdarg_cfg[slappasswd_salt]="rofflewaffles%s"
    cmdarg_cfg[source_ldap_ou_groups]="groups"
    cmdarg_cfg[slappasswd_scheme]="SSHA"
    cmdarg_cfg[dest_ldap_username]="1"
    cmdarg_cfg[dest_ldap_password]="1"
    cmdarg_cfg[source_ldap_password]="1"
    cmdarg_cfg[source_ldap_username]="1"
    cmdarg_cfg[cfgfile]="/dev/null"
    cmdarg_cfg[dest_ldap_basedn]="1"
    cmdarg_cfg[source_ldap_basedn]="1"
    cmdarg_cfg[source_ldap_ou_users]="users"
    cmdarg_cfg[source_ldap]="1"
    cmdarg_cfg[dest_ldap]="1"