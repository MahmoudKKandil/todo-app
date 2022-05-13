Example of: Docker container with their 'getting-started' app.

License:
 - Originally: MIT (I suppose as is indicated in the package.json file).
 - As of 2020: Apache 2.0 (https://github.com/docker/getting-started)

Modifications by: William Paul Liggett of https://junktext.com

To get the app working, clone the repo, then there are two options:

 - Production: `docker compose up -d`
 - Development: `docker compose -f compose-dev.yaml up -d`

Then, open up a web browser and navigate to: http://localhost:3000/

Tip: When in dev-mode, you must specify the `-f compose-dev.yaml` for every Docker Compose command.

Also, if you want to create a new dev-specific Docker image, then do the following, but replace DOCKERHUBACCOUNT with your own Docker Hub account and replace the #.#.# with the appropriate semver:

`docker image build -t DOCKERHUBACCOUNT/getting-started:dev-latest -t DOCKERHUBACCOUNT/getting-started:dev-#.#.# -f Dockerfile-dev .`

Finally, if you want a solid explanation of YAML files and Docker's specific syntax with YAML, look at:
 - YAML_File_Example.yaml
 - compose-dev-from-pub-imgs.yaml