Simple 'To-Do' app that uses Node.js, React, Jest unit tests, and SQLite / MySQL

Important: Do NOT use for production purposes! junktext is NOT maintaining this app for security or feature enhancements. However, the app code is useful for testing out CI/CD pipelines and for demonstrating if various codebase security scanning tools are working (since the Node/NPM/Yarn versions and the app dependencies are intentionally NOT being upgraded for this reason).

Core code from Docker's Getting Started tutorial from 2020:
https://github.com/docker/getting-started

Note: Docker now has a newer, different Getting Started codebase:
https://github.com/docker/getting-started-app

License:

-   Originally: MIT (I suppose as is indicated in the package.json file).
-   As of 2020: Apache 2.0 (https://github.com/docker/getting-started)

Modifications by: William Paul Liggett of https://junktext.com

To get the app working, clone the repo, then there are four options:

1.  Docker Compose: Production Demo: `docker compose up -d`
2.  Docker Compose: Development Env: `docker compose -f compose-dev.yaml up -d`
3.  Kubernetes/Helm: https://artifacthub.io/packages/helm/junktext-direct/todo-app
4.  Local JS development without Docker by doing:
    -   Install Node v12.22.12 (NPM v6.14.16) -- If using NVM: `$ nvm install lts/erbium`
    -   Install Yarn v1.22.21: `$ npm install --global yarn`
    -   Create a local folder to be used for SQLite: `$ mkdir sqlite_for_non_docker_dev`
    -   Add that folder to your OS env vars: `$ export SQLITE_DB_LOCATION="$(pwd)/sqlite_for_non_docker_dev/todo.db"`
    -   Run the Jest (JS) unit tests to ensure everything passes: `$ yarn test`
    -   Start the local dev server: `$ yarn run dev`

Then, open up a web browser and navigate to: http://localhost:3000/

Tip: When in Docker Compose dev-mode, you must specify the `-f compose-dev.yaml` for every Docker Compose command.

Also, if you want to create a new dev-specific Docker image, then do the following, but replace DOCKERHUBACCOUNT with your own Docker Hub account and replace the #.#.# with the appropriate semver:

`docker image build -t DOCKERID/getting-started:dev-latest -t DOCKERID/getting-started:dev-#.#.# -f Dockerfile-dev .`

Finally, if you want a great explanation of YAML files and Docker's specific syntax with YAML, look at:

-   YAML_File_Example.yaml
-   compose-dev-from-pub-imgs.yaml
