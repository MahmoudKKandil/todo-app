Example of: Docker container with their 'getting-started' app.

Important: This app is NOT maintained for security or performance problems and therefore should NOT be installed on a production environment. However, as this is open source software, feel free to fork and improve upon things if you wish on your own.

License:
 - Originally: MIT (I suppose as is indicated in the package.json file).
 - As of 2020: Apache 2.0 (https://github.com/docker/getting-started)

Modifications by: William Paul Liggett of https://junktext.com

To get the app working, clone the repo, then there are three options:

 - Docker Compose: Production Demo: `docker compose up -d`
 - Docker Compose: Development Env: `docker compose -f compose-dev.yaml up -d`
 - Kubernetes/Helm: https://artifacthub.io/packages/helm/junktext-direct/todo-app

Then, open up a web browser and navigate to: http://localhost:3000/

Tip: When in Docker Compose dev-mode, you must specify the `-f compose-dev.yaml` for every Docker Compose command.

Also, if you want to create a new dev-specific Docker image, then do the following, but replace DOCKERHUBACCOUNT with your own Docker Hub account and replace the #.#.# with the appropriate semver:

`docker image build -t DOCKERID/getting-started:dev-latest -t DOCKERID/getting-started:dev-#.#.# -f Dockerfile-dev .`

Finally, if you want a great explanation of YAML files and Docker's specific syntax with YAML, look at:
 - YAML_File_Example.yaml
 - compose-dev-from-pub-imgs.yaml