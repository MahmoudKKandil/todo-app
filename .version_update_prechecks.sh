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

declare current_branch=''
declare last_yarn_ver_tag=''
declare helm_chart_ver_string=''

# Usage:   helm_chart_semver_array varname
# Purpose: Will obtain the Helm semantic version (semver) of the app's chart on
#          the current Git branch. varname becomes an associative array, such
#          that if the chart is at v1.2.3, then:
#            varname["major"]='1'
#            varname["minor"]='2'
#            varname["patch"]='3'
function helm_chart_semver_array() {
    if [[ "$1" == '' ]]; then
        echo "@}-;--- ERROR: get_helm_semver() requires an argument to be used as the variable name to create."
        return 1

    elif [[ "helm_chart_ver_string" == '' ]]; then
        echo -e "@}-;--- ERROR: get_helm_semver() requires the \$helm_chart_ver_string variable to be assigned."
        return 2

    else
        # Creates a new associative, global array from the varname to represent the Helm chart's semver.
        declare -gA "$1"=(
            [major]="$(echo "$helm_chart_ver_string" | grep -Eo ' "[[:digit:]]+\.' | grep -Eo '[[:digit:]]+')"
            [minor]="$(echo "$helm_chart_ver_string" | grep -Eo '\.[[:digit:]]+\.' | grep -Eo '[[:digit:]]+')"
            [patch]="$(echo "$helm_chart_ver_string" | grep -Eo '\.[[:digit:]]+"' | grep -Eo '[[:digit:]]+')"
        )

        return 0

    fi
}

# Checks whether any changes have occurred with the Helm chart files.
declare chart_changed=$(git status | grep 'Kubernetes/helm-chart/todo-app/')

# The Helm chart wasn't changed, so we don't need to do anything else as the
# other parts of the CI/CD pipeline will handle the semver patch increment.
if [[ "$chart_changed" == '' ]]; then
    echo -e "@}-;--- Helm chart: The files have not been changed, so Yarn should only\n\tincrement the semver patch number of the chart."

# But, if the Helm chart was changed, we should double-check the semver number.
else
    echo -e "@}-;--- Helm chart: The files HAVE been changed in some way. Determining if the\n\tchart's semver seems accurate..."

    # Looks for problems with the Helm version information.
    # We'll first get the chart's last `version` from the last release per Yarn.
    last_yarn_ver_tag="$(echo $(yarn version) | awk '{print $7}')"
    current_branch="$(git branch --show-current)"

    # TODO: Use another Git capability to grab this instead of `checkout` to avoid needing to stash/unstash.
    # git checkout "$last_ver_tag"
    # helm_chart_ver_string=$()
    # helm_chart_semver_array last_helm_semver

    # git checkout "$current_branch"
    # helm_chart_ver_string=$(grep -E '^version: "[[:digit:]]+.[[:digit:]]+.[[:digit:]]+"$' 'Kubernetes/helm-chart/todo-app/Chart.yaml')
    # helm_chart_semver_array current_helm_semver

    #------
    # Grabs the Helm chart's semver based on the previous and current Git branches.
    for branch in "$last_yarn_ver_tag" "$current_branch"
    do
        git checkout "$branch"
        helm_chart_ver_string=$(grep -E '^version: "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+"$' 'Kubernetes/helm-chart/todo-app/Chart.yaml')

        if [[ "$branch" == "$last_yarn_ver_tag" ]]; then
            helm_chart_semver_array last_helm_semver

        elif [[ "$branch" == "$current_branch" ]]; then
            helm_chart_semver_array current_helm_semver

        fi
    done

fi