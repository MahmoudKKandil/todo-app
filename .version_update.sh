#!/bin/bash
# Purpose: Update this app's version info in a coordinated way after
#          performing: $ yarn version [--major | --minor | --patch]
#
# By:      William Paul Liggett (https://junktext.com)

# For script debugging:
#set -x

# Exit with a non-zero result if any command in this script fails.
set -euo pipefail

# Prerequisite: Ensure a file called `.yarnrc` exists in the main folder (above 'src/') with at least:
#version-git-tag false
# This will disable Yarn v1's default behavior to update only the `package.json` file with the new version,
# which Yarn then commits and then performs a `git tag -a` on that change. We'll do this as well, but we need to
# prevent Yarn from making these changes as we also want to update the version details publicly on the app's frontend.

# So, the purpose of this `.version_update.sh` script is to handle all of this after we tell Yarn to do a semver update.
# Once Yarn changes the app's version number in the `package.json` file to something like: "version": "1.0.22",
# We will then grab just the 1.0.22 portion and store it as $new_app_ver
declare new_app_ver="$(echo $(yarn version) | awk '{print $7}')"
declare pub_ver_file='src/static/js/app.js'
declare helm_chart_file='Kubernetes/helm-chart/todo-app/Chart.yaml'
declare helm_chart_folder='Kubernetes/helm-chart'
declare helm_chart_semver_string=''

echo -e "\n@}-;--- Yarn has updated the app's version to $new_app_ver in file: package.json"
echo "@}-;--- Updating the app's version as shown in the web frontend at: $pub_ver_file"

# In the React code that gets shown to the browser, there is a line that says (with an example):
#   Modified by junktext (v1.0.21)
# So, the following will update that portion of text with the new version number as (v1.0.22):
sed -i -E "s/v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+/v$new_app_ver/" "$pub_ver_file"

# Updates the Helm chart with the new 'appVersion' number (the app's container version)
sed -i -E "s/appVersion: \"[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\"/appVersion: \"$new_app_ver\"/" "$helm_chart_file"

# Updates the Helm chart 'version' (which is the version of the chart itself) as a PATCH, such as: 1.0.21 to 1.0.22
helm_chart_semver_string=$(cat "$helm_chart_file" | grep -E '^version: "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+"$' | grep -Eo '[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+')
helm_chart_semver_string=$(yarn -s semver -i patch "$helm_chart_semver_string")
sed -i -E "s/version: \"[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\"/version: \"$helm_chart_semver_string\"/" "$helm_chart_file"

# Creates the new Helm chart package
cd $helm_chart_folder
ls
helm lint todo-app
helm package todo-app
helm repo index .
ls
cd ../..

echo "@}-;--- Performing a Git commit and tag to save the changes."

# We can then make a commit of all the version-related file changes.
git add \
    package.json \
    "$pub_ver_file" \
    "$helm_chart_folder/index.yaml" \
    "$helm_chart_folder/todo-app/Chart.yaml" \
    "$helm_chart_folder/todo-app-$helm_chart_semver_string.tgz"

git commit -m "Version: $new_app_ver"

# Next, we can then create a Git tag to reflect this as well:
git tag -a "$new_app_ver" -m "Version: $new_app_ver"

# For sanity's sake, we'll confirm we want to publicly perform the Git commit/tag.
git show "$new_app_ver"

echo -e "\n@}-;--- The changes, SHOWN ABOVE, are scheduled to be pushed to the remote Git repo..."

# Gets user input and stores everything in lowercase format.
declare -l update_remote_repo
read -rp "CONFIRMATION --> Do you wish to proceed (y/n)? " update_remote_repo

if [[ "$update_remote_repo" == 'yes' || "$update_remote_repo" == 'y' ]]; then
    echo -e "\n@}-;--- Pushing the changes to the remote Git repo..."

    # Finally, we can push both the commit and tag to the remote repo at the same time (using the --atomic flag):
    git push --atomic origin master "$new_app_ver"

    echo "@}-;--- Success! The app's version details have been updated correctly."

else
    echo -e "\n@}-;--- Git push halted as neither 'yes' or 'y' was provided as a response."
    declare -l undo_version_changes
    read -rp "Would you like to UNDO the LOCAL version change Git commit and tag (y/n)? " undo_version_changes

    if [[ "$undo_version_changes" == 'yes' || "$undo_version_changes" == 'y' ]]; then
        git tag -d "$new_app_ver"
        git reset --soft HEAD~1
        echo -e "\n@}-;--- Undo complete! The Git tag was deleted, but the last commit has been put back to Git's --staged area to be safe."
    fi

fi
