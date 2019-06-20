# cmdarg_var_declare.sh

CMDARG_ERROR_BEHAVIOR=return

CMDARG_FLAG_NOARG=0
CMDARG_FLAG_REQARG=2
CMDARG_FLAG_OPTARG=4

CMDARG_TYPE_ARRAY=1
CMDARG_TYPE_HASH=2
CMDARG_TYPE_STRING=3
CMDARG_TYPE_BOOLEAN=4



# Holds the final map of configuration options
declare -xA cmdarg_cfg
# Maps (short arg) -> (long arg)
declare -xA CMDARG
# Maps (long arg) -> (short arg)
declare -xA CMDARG_REV
# A list of optional arguments (e.g., no :)
declare -xa CMDARG_OPTIONAL
# A list of required arguments (e.g., :)
declare -xa CMDARG_REQUIRED
# Maps (short arg) -> (description)
declare -xA CMDARG_DESC
# Maps (short arg) -> default
declare -xA CMDARG_DEFAULT
# Maps (short arg) -> validator
declare -xA CMDARG_VALIDATORS
# Miscellanious info about this script
declare -xA CMDARG_INFO
# Map of (short arg) -> flags
declare -xA CMDARG_FLAGS
# Map of (short arg) -> type (string, array, hash)
declare -xA CMDARG_TYPES
# Array of all elements found after --
declare -xa cmdarg_argv
# Hash of functions that are used for user-extensible functionality
declare -xA cmdarg_helpers
cmdarg_helpers['describe']=cmdarg_describe_default
cmdarg_helpers['usage']=cmdarg_usage

CMDARG_GETOPTLIST="h"
