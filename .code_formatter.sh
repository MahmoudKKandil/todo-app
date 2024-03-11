#!/bin/bash
# Purpose: DRY way of interacting with Prettier to either write (apply) or 
#          check code formatting rules for the files we care about.
#
# By:      William Paul Liggett (https://junktext.com)

# Exit with a non-zero result if any command in this script fails.
set -euo pipefail

prettier_arg=''

if [[ "$1" == '--write' ]]; then
    prettier_arg='--write'

elif [[ "$1" == '--check' ]]; then
    prettier_arg='-c'

else
    echo '[ERROR] You must specify an argument of either: --write OR --check'
    exit 1

fi

# Ensures every file tracked by Prettier indeed has the correct code formatting syntax.
# For a real example to prove that Prettier will halt the CI build if it detects formatting
# violations, see: https://gitlab.com/junktext/example-docker-getting-started/-/pipelines/1178600088
# The Bash command below will:
# 1) Look for files not ignored by Prettier (as specified in .prettierignore)
# 2) Strip off the ! symbol for each file found.
# 3) Has Yarn check or write every file accordingly. Example with --check: $ yarn prettier -c ./src/one.js ./src/two.js ...
grep '!' .prettierignore | cut --delimiter='!' -f2 | xargs yarn prettier "$prettier_arg"
