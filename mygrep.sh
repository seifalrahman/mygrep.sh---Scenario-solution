#!/bin/bash

print_usage() {
cat <<EOF
Usage: $0 [OPTIONS]... PATTERNS [FILE]...
Search for PATTERNS in each FILE.
Example:  ./mygrep.sh -i hello testfile.txt
PATTERNS can contain multiple patterns separated by newlines.

Pattern selection and interpretation:
  -i,       ignore case distinctions in patterns and data
            do not ignore case distinctions (default)
Miscellaneous:
  -v,       select non-matching lines
Output control:
  -n,       print line number with output lines
  -c,       print only a count of selected lines per FILE
  -l        print only names of FILEs with selected lines

  --help    Show this help message and exit

EOF
}

show_line_numbers=0
invert_match=0
ignore_case=0
only_count=0
only_list_files=0

MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
RED=$'\033[1;31m'
NC=$'\033[0m'

for arg in "$@"; do
  [[ "$arg" == "--help" ]] && print_usage && exit 0
done

while getopts ":nvilc" opt; do
  case $opt in
    n) show_line_numbers=1 ;;
    v) invert_match=1 ;;
    i) ignore_case=1 ;;
    c) only_count=1 ;;
    l) only_list_files=1 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; print_usage; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

if [[ $# -lt 1 ]]; then
  echo "Error: Missing search string." >&2
  print_usage
  exit 1
elif [[ $# -lt 2 ]]; then
  if [[ -f "$1" ]]; then
    echo "Error: Missing search string." >&2
    print_usage
    exit 1
  else
    echo "Error: Missing filename." >&2
    print_usage
    exit 1
  fi
fi


if [[ -f "$1" && -f "$2" ]]; then
  echo "Error: Missing search string." >&2
  print_usage
  exit 1
fi

search_string=$1
shift

files=("$@")
for file in "${files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Error: File '$file' not found." >&2
    exit 1
  fi
done

highlight() {
  local pattern="$1"
  local ignore_case="$2"
  local text="$3"
  if [[ "$ignore_case" -eq 1 ]]; then
    printf '%s\n' "$text" | perl -pe "s/($pattern)/\e[1;31m\$1\e[0m/ig"
  else
    printf '%s\n' "$text" | perl -pe "s/($pattern)/\e[1;31m\$1\e[0m/g"
  fi
}

grep_flags=""
[[ "$ignore_case" -eq 1 ]] && grep_flags="$grep_flags -i"
[[ "$invert_match" -eq 1 ]] && grep_flags="$grep_flags -v"

# Count mode
if [[ $only_count -eq 1 ]]; then
  for file in "${files[@]}"; do
    count=$(grep $grep_flags -c -- "$search_string" "$file")
    if [[ ${#files[@]} -gt 1 ]]; then
      printf "${MAGENTA}%s${NC}${CYAN}:${NC}%s\n" "$file" "$count"
    else
      printf "%s\n" "$count"
    fi
  done
  exit 0
fi

if [[ $only_list_files -eq 1 ]]; then
  for file in "${files[@]}"; do
    if grep $grep_flags -q -- "$search_string" "$file"; then
      printf "${MAGENTA}%s${NC}\n" "$file"
    fi
  done
  exit 0
fi

for file in "${files[@]}"; do
  line_number=0
  while IFS= read -r line; do
    ((line_number++))
    if echo "$line" | grep $grep_flags -q -- "$search_string"; then
      out=""
      if [[ ${#files[@]} -gt 1 ]]; then
        out+="${MAGENTA}${file}${NC}${CYAN}:${NC}"
      fi
      if [[ $show_line_numbers -eq 1 ]]; then
        out+="${GREEN}${line_number}${NC}${CYAN}:${NC}"
      fi
      out+="$(highlight "$search_string" "$ignore_case" "$line")"
      printf "%b\n" "$out"
    fi
  done < "$file"
done
