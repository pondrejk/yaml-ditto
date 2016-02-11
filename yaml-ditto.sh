#!/bin/sh

# yaml-ditto -- detect duplicate keys in yaml files.
# by Peter Ondrejka

# Script name
NAME="yaml-ditto"

# Command-line options:
OPT_DROPPED=1
OPT_MULTI=0
OPT_ALL=0
OPT_COMPARE=0
OPT_TOP=0
FILE=$1
DRAFT=

# get key structure in condensed form
function parse_keys {
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e 's|`||g;s|\$||g;' \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |

   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s\n", vn, $2, $3);
      }
   }'
}

# get bottom-level keys
function parse_last_key {
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e 's|`||g;s|\$||g;' \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
         printf("%s\n", $2, $3);
   }'
}

# list invalid duplicate keys
function list_dropped_keys {
   echo -e "\e[32m$1:\e[0m"
   parse_keys $1 | sort | uniq -i --count | grep -v 1 | awk '{ print } END { if (!NR) print "   No invalid duplicates found" }'
}

# list invalid duplicate keys
function list_safe_duplicates {
   echo -e "\e[32m$1:\e[0m"
   parse_last_key $1 | sort | uniq -i --count | grep -v 1 | awk '{ print } END { if (!NR) print "   No duplicates found" }'
}

# run -d on multiple files
function multiple_files {
   for i in $1
   do
     list_dropped_keys $i
   done
}

# compare yaml to one on more other yamls
function compare_files {
   #local to_compare=`parse_last_key $1 | sed -r 's/_+$//' | sort | uniq -i | sort`
   local to_compare=`parse_last_key $1 | sort | uniq -i`

   for i in $2
   do
     if [[ "$1" != "$i" ]]
     then
       echo -e "\e[32mIn $1 and $i:\e[0m"
       local compared=`parse_last_key $i | sort | uniq -i | sort`
       for j in $to_compare
       do
         [[ $compared =~ $j ]] && echo "    $j"
       done
     fi
   done
}

# self-explanatory :)
function show_help {
  echo "Usage: $NAME [-da] FILE"
  echo "       $NAME -c FILE1 FILE2..."
  echo "       $NAME -m FILE1 FILE2..."
  echo "       $NAME -h"
  echo
  echo "  -d  print invalid duplicate yaml keys in condensed form"
  echo "      (with occurrence count, case insensitive, default option)"
  echo "  -m  same as -d, but for multiple files"
  echo "  -a  print all duplicate yaml keys (with occurrence count, case insensitive)"
  echo "  -c  compare keys in two yaml files"
  echo "  -h  display this help and exit"
  echo
}

# Print error message, terminate with given exit status
function exit_with_error {
  local error_message=${1:-'An unexpected error has occurred.'}
  local exit_status=${2:-1}
  echo -e "$NAME: $error_message" >&2
  exit $exit_status
}

# No options or files specified = show help
if [[ "$#" -eq 0 ]]; then
  show_help
  exit 0
fi

# Process command-line options:
while getopts ':dmach' OPTION; do
  case "$OPTION" in
    d)
      OPT_DROPPED=1
      FILE=$2
      ;;
    m)
      OPT_DROPPED=0
      OPT_MULTI=1
      FILE=${@:2}
      ;;
    a)
      OPT_ALL=1
      OPT_DROPPED=0
      FILE=$2
      ;;
    c)
      OPT_COMPARE=1
      OPT_DROPPED=0
      DRAFT=$2
      FILE=${@:3}
      ;;
    h)
      show_help
      exit 0
      ;;
    \?)
      exit_with_error "Invalid option -- '$OPTARG'" 22
      ;;
  esac
done

# Verify that the file exists:
for FIL in $FILE
do
  [[ -e "$FIL" ]] || exit_with_error "$FIL: No such file or directory" 2
  [[ -r "$FIL" ]] || exit_with_error "$FIL: Permission denied" 13
  [[ -f "$FIL" ]] || exit_with_error "$FIL: Not a file" 21
done

# Decide which action to perform:
if [[ "$OPT_DROPPED" -ne 0 ]]; then
  echo -e "\e[90mInvalid duplicate keys\e[0m"
  list_dropped_keys "$FILE"
elif [[ "$OPT_MULTI" -ne 0 ]]; then
  echo -e "\e[90mInvalid duplicate keys\e[0m"
  multiple_files "$FILE"
elif [[ "$OPT_ALL" -ne 0 ]]; then
  echo -e "\e[90mAll duplicate keys\e[0m"
  list_safe_duplicates "$FILE"
elif [[ "$OPT_COMPARE" -ne 0 ]]; then
  compare_files "$DRAFT" "$FILE"
fi

# Terminate the script:
exit 0
