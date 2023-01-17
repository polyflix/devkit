#!/bin/bash
set -euo pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )/..";
PATH=$(pwd)/.bin:$PATH

STACK="${STACK:-}"
banner_min_width=80

# Print a big banner in which you can give text to make sections in your console
function banner()
{
  local chrlen=${#1}
  if [ "${chrlen}" -lt "${banner_min_width}" ]; then 
    chrlen=${banner_min_width}
  fi
  local width=$((chrlen + 5))
  local width_border=$((width + 2))
  local border=$(printf '%*s' "${width_border}" | tr ' ' "-")
  echo
  echo "+${border}+"
  printf "| %-${width}s |\n" "`date`"
  printf "| %-${width}s |\n" ""
  printf "|`tput bold` %-${width}s `tput sgr0`|\n" "$1"
  echo "+${border}+"
}

# Print a smaller banner in which you can give text to make sub-sections in your console
function small_banner()
{
  local chrlen=${#1}
  if [ "${chrlen}" -lt "${banner_min_width}" ]; then 
    chrlen=${banner_min_width}
  fi
  local width=$((chrlen + 5))
  local width_border=$((width + 2))
  local border=$(printf '%*s' "${width_border}" | tr ' ' "-")
  echo
  echo "+${border}+"
  printf "|`tput bold` %-${width}s `tput sgr0`|\n" "$1"
  echo "+${border}+"
}

function read_until_set {
  local __v=${1}
  local message="${2}"
  local silent=${3:-"false"}
  
  if [ -z "${!__v:-}" ]
  then
    local v=""
    while [ -z "$v" ]; do
      printf "%s: " "$message"
      read -r v
    done
    eval $__v="'$v'"
  fi
  if [ "${silent}" != "true" ]; then
    printf "%s: '%s'\n" ${1} ${!1}
  fi
}

function read_optionally {
  local __v=${1}
  local message="${2}"
  local silent=${3:-"false"}
  
  if [ -z "${!__v:-}" ]
  then
    local v=""
    
    printf "%s: " "$message"
    read -r -e v
    
    if [ -z "${v:-}" ] && [ ! -z "${4:-}" ]
    then
      v="${3}" 
    fi
    eval $__v="'$v'"
  fi
  if [ "${silent}" != "true" ]; then
    printf "%s: '%s'\n" ${1} ${!1}
  fi
}

# Can be used to determine some needed commands
function checkPrerequisite {
  if ! command -v ${1} &> /dev/null
  then
    echo "COMMAND '${1}' could not be found! Please install first!"
    exit
  fi
}

# Parse input parameters, and use the first one to determine the command to run
# in the script. The command will be used to call the function `sub_${COMMNAND}`
# If the command is not found, it will run `sub_default` function to show helper.
#
# Example:
#    // myscript.sh
#    function sub_default(){
#      local progname=`basename "$0"`
#      echo "This script will show an hello world"
#      print_generic_options
#    }
#    function sub_test() {
#    	echo "Hello world!"
#    }
#    parse_and_execute $@
#    // What to run
#    -> myscript.sh test
function parse_and_execute() {
  if [[ $# = 0 ]]; then
    sub_default
    exit 0
  fi 

  while [[ $# -gt 0 ]]
  do
  arg="$1"
  case $arg in
      "" | "-h" | "--help")
          sub_default
          shift
          ;;
      --debug)
          set -x
          DEBUG=true
          shift
          ;;
      *)
          shift
          sub_${arg} $@
          ret_value=$?
          if [ $ret_value = 127 ]; then
              echo "Error: '$arg' is not a known subcommand." >&2
              echo "       Run '$progname --help' for a list of known subcommands." >&2
              exit 1
          elif [ $ret_value = 0 ]; then
              exit 0
          else
              exit $ret_value
          fi
          ;;
  esac
  done
}

function print_generic_options() {
  echo "Generic Options:"
  echo "  --debug simply does a set -x and prints out each command."
}
