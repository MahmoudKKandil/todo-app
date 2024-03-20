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
set -x

# Exit with a non-zero result if any command in this script fails.
set -euo pipefail

# Ensures that we have Git running (we want it to error if it is NOT installed)
echo "@}-;--- Git version:"
git --version

echo -e "\n@}-;--- Running the '.version_update_prechecks.sh' to watch for certain problems before a release...\n"

declare current_branch=''
declare last_yarn_ver_tag=''
declare helm_semver_search_method=''
declare helm_chart_semver_string=''
declare -A helm_chart_semver_results
declare error_detected=''

# Checks whether any changes have occurred with the Helm chart files.
# declare chart_changed
# chart_changed="$(git status | grep 'Kubernetes/helm-chart/todo-app/')"

# Finds the Helm chart semver details for both the old and latest chart files.
# It is meant to only be called in either of these two ways:
#   find_chart_semver last_chart
#   find_chart_semver current_chart
function find_chart_semver() {
    if [[ "$1" == 'last_chart' ]]; then
        helm_semver_search_method="git show $last_yarn_ver_tag:Kubernetes/helm-chart/todo-app/Chart.yaml"

    elif [[ "$1" == 'current_chart' ]]; then
        helm_semver_search_method='cat Kubernetes/helm-chart/todo-app/Chart.yaml'

    fi

    helm_chart_semver_string=$($helm_semver_search_method | grep -E '^version: "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+"$' | grep -Eo '[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+')
    helm_chart_semver_results["$1"]="$helm_chart_semver_string"

    return 0
}

# The Helm chart wasn't changed, so we don't need to do anything else as the
# other parts of the CI/CD pipeline will handle the semver patch increment.
# if [[ "$chart_changed" == '' ]]; then
#     echo -e "@}-;--- Helm chart: The files have not been changed.\n\tSo '.version_update.sh' should only increment the chart's semver as a PATCH.\n"

# But, if the Helm chart was changed, we should double-check the semver number.
# else
if [[ $(git status | grep 'Kubernetes/helm-chart/todo-app/') ]]; then
    echo -e "@}-;--- Helm chart: The files HAVE been changed in some way.\n\tDetermining if the chart's semver seems accurate...\n"

    # We'll first get the chart's last `version` from the last release per Yarn.
    last_yarn_ver_tag="$(echo $(yarn version) | awk '{print $7}')"
    current_branch="$(git branch --show-current)"

    # Grabs the Helm chart's semver based on the previous and current Git branches.
    for branch in "$last_yarn_ver_tag" "$current_branch"
    do
        # Inside our Helm's Chart.yaml, we are looking for something like:
        #version: "1.2.3"
        #helm_chart_semver_string=$(git show "$branch":Kubernetes/helm-chart/todo-app/Chart.yaml | grep -E '^version: "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+"$' | grep -Eo '[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+')

        if [[ "$branch" == "$last_yarn_ver_tag" ]]; then
            #helm_chart_semver_results[last_chart]="$helm_chart_semver_string"
            find_chart_semver last_chart

        elif [[ "$branch" == "$current_branch" ]]; then
            #helm_chart_semver_results[current_chart]="$helm_chart_semver_string"
            find_chart_semver current_chart

        fi
    done

    # DEBUGGING:
    #declare | grep helm_chart_semver_results
    # echo "${helm_chart_semver_results[last_chart]}"
    # echo "${helm_chart_semver_results[current_chart]}"
    # echo $(yarn -s semver -i patch "${helm_chart_semver_results[last_chart]}")

    if [[ $(yarn -s semver -i major "${helm_chart_semver_results[last_chart]}") == "${helm_chart_semver_results[current_chart]}" ]]; then
        echo "@}-;--- GOOD NEWS: A valid semver increment of MAJOR was detected!"

    elif [[ $(yarn -s semver -i minor "${helm_chart_semver_results[last_chart]}") == "${helm_chart_semver_results[current_chart]}" ]]; then
        echo "@}-;--- GOOD NEWS: A valid semver increment of MINOR was detected!"

    elif [[ $(yarn -s semver -i patch "${helm_chart_semver_results[last_chart]}") == "${helm_chart_semver_results[current_chart]}" ]]; then
        echo "@}-;--- GOOD NEWS: A valid semver increment of PATCH was detected!"

    else
        echo "@}-;--- ERROR: An invalid semver increment of the Helm chart was detected!"
        echo -e "\tIf you manually modified any aspect of the chart, then manually set\n\tthe 'version:' to an appropriate semver value inside of: Chart.yaml"
        error_detected='yes'

    fi

    echo -e "\n\tLast chart release: ${helm_chart_semver_results[last_chart]}"
    echo -e "\tCurrent chart ver:  ${helm_chart_semver_results[current_chart]}\n"

    if [[ "$error_detected" == 'yes' ]]; then
        exit 1
    fi

else
    echo -e "@}-;--- Helm chart: The files have not been changed.\n\tSo '.version_update.sh' should only increment the chart's semver as a PATCH.\n"

fi
