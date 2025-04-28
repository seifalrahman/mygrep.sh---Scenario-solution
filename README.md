# How the Script Handles Arguments and Options
### Options Parsing:
The script uses Bash’s getopts to process short options like -n, -v, -i, -c, and -l.
### Argument Validation
1-Check if there are any positional arguments left after options
```bash
if [[ $# -lt 1 ]]; then
  echo "Error: Missing search string."
  print_usage
  exit 1
```
  Purpose:
    If there are no arguments after option flags, neither a search pattern nor filenames were provided.
  Result:
    Shows "Error: Missing search string." and exits.

2- If only one argument is present
```bash
elif [[ $# -lt 2 ]]; then
  # Only one argument present
  if [[ -f "$1" ]]; then
    echo "Error: Missing search string."
  else
    echo "Error: Missing filename."
  fi
  print_usage
  exit 1
```
  Purpose:
    If a single argument remains after parsing options, the script needs to decide whether the user gave only:
    
    a search pattern (missing filename)
    or only a filename (missing search pattern)
    It does this by checking if the argument is a file.
  
  Scenarios:
  
  ./mygrep.sh testfile.txt ("testfile.txt" is a file)
  → "Error: Missing search string."
  ./mygrep.sh pattern (not a file)
  → "Error: Missing filename."
3- If user gave two  arguments but both are files
```bash
if [[ -f "$1" && -f "$2" ]]; then
  echo "Error: Missing search string."
  print_usage
  exit 1
fi
```
  Purpose:
  If both the first and second argument look like files, the user almost certainly forgot to supply a search pattern (and gave two files instead).
  Result:
  Shows "Error: Missing search string." and exits.




#### I have used Perl’s regex engine to handle regex
