#!/bin/bash
# Purpose: Meant to complement the "preversion" portion of `package.json` such
# that when `$ yarn version` is run, this script will perform sanity checks.
#
# Note: We're not defining the Prettier & Jest tests here as these are
# separate CI jobs so we don't want to aggregate everything here. Instead, as
# you'll see in `package.json`, we can simply do:
#   "preversion": "yarn prettier_check && yarn test && ./.version_update_prechecks.sh",
#
# So, in other words, this prechecks script can look for other problems,
# in particular with the Helm chart being at the correct version.
#
# By: William Paul Liggett (https://junktext.com)

# For script debugging:
#set -x

# Exit with a non-zero result if any command in this script fails.
set -euo pipefail

# Looks for problems with the Helm version information.
# We'll first get the chart's last `version` from the last release per Yarn.
last_yarn_ver_tag="$(echo $(yarn version) | awk '{print $7}')"

# TODO: This is a WIP section...
last_helm_chart_ver=$(grep -E "^version: '[[:digit:]]+.[[:digit:]]+.[[:digit:]]+'$" 'Kubernetes/helm-chart/todo-app/Chart.yaml')

git checkout "$last_ver_tag"; blah='Coffee'; git checkout master

# Checks whether any changes have occurred with the Helm chart files.
chart_changed=$(git status | grep 'Kubernetes/helm-chart/todo-app/')

if [[ "$chart_changed" == '' ]]; then
    # The Helm chart files have NOT been changed at all.
    echo 'NOT CHANGED'

else
    # The Helm chart files HAVE BEEN changed in some way.
    echo 'CHANGED'

fi