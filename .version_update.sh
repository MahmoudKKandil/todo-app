#!/bin/bash
# Purpose: Update this app's version info in a coordinated way after
#          performing: $ yarn version [--major | --minor | --patch]
#
# By: William Paul Liggett (https://junktext.com)

# Prerequisite: Ensure a file called `.yarnrc` exists in the main folder (above 'src/') with at least:
#version-git-tag false
# This will disable Yarn v1's default behavior to update only the `package.json` file with the new version,
# which Yarn then commits and then performs a `git tag -a` on that change. We'll do this as well, but we need to
# prevent Yarn from making these changes as we also want to update the version details publicly on the app's frontend.

# So, the purpose of this `.version_update.sh` script is to handle all of this after we tell Yarn to do a semver update.
# Once Yarn changes the app's version number in the `package.json` file to something like: "version": "1.0.22",
# We will then grab just the 1.0.22 portion and store it as $NEW_APP_VER
NEW_APP_VER="$(echo $(yarn version) | awk '{print $7}')"

echo -e "\n@}-;--- Yarn has updated the app's version to $NEW_APP_VER in file: package.json"
echo "@}-;--- Updating the app's version as shown in the web frontend at: src/static/js/app.js"

# In the React code that gets shown to the browser, there is a line that says:
#   Modified by junktext (v1.0.21)
# So, the following will update that portion of text with the new version number as (v1.0.22):
sed -i "s/(v[[:digit:]].[[:digit:]].[[:digit:]])/(v$NEW_APP_VER)/" src/static/js/app.js

echo "@}-;--- Performing a Git commit and tag to save the changes."

# We can then make a commit which will have the changes of the `package.json` and that `app.js` file.
git commit -m "Version: $NEW_APP_VER"

# Next, we can then create a Git tag to reflect this as well:
git tag -a $NEW_APP_VER -m "Version: $NEW_APP_VER"

echo "@}-;--- Pushing the changes to the remote Git repo..."

# Finally, we can push both the commit and tag to the remote repo at the same time (using the --atomic flag):
git push --atomic origin master $NEW_APP_VER

echo "@}-;--- Success! The app's version details have been updated correctly."
