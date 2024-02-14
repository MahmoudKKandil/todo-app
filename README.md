Simple 'To-Do' app that uses Node.js, React, Jest unit tests, and MySQL (v5.7) or SQLite

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
    -   Have Yarn install the app dependencies: `$ yarn install`
    -   Create a local folder to be used for SQLite: `$ mkdir sqlite_for_non_docker_dev`
    -   Add that folder to your OS env vars: `$ export SQLITE_DB_LOCATION="$(pwd)/sqlite_for_non_docker_dev/todo.db"`
    -   Run the Jest (JS) unit tests to ensure everything passes: `$ yarn test`
    -   Start the local dev server: `$ yarn run dev`

Then, open up a web browser and navigate to: http://localhost:3000/

Tip: When in Docker Compose dev-mode, you must specify the `-f compose-dev.yaml` for every Docker Compose command.

To build a new production (non-dev) Docker image, do:

`docker image build -t DOCKERID/getting-started:latest -t DOCKERID/getting-started:#.#.# -f Dockerfile .`

Also, if you want to create a new dev-specific Docker image, then do the following, but replace DOCKERHUBACCOUNT with your own Docker Hub account and replace the #.#.# with the appropriate semver:

`docker image build -t DOCKERID/getting-started:dev-latest -t DOCKERID/getting-started:dev-#.#.# -f Dockerfile-dev .`

To push your newly built image to Docker Hub:

`docker push --all-tags DOCKERID/getting-started`

FYI: Uf you want a great explanation of YAML files and Docker's specific syntax with YAML, look at:

-   YAML_File_Example.yaml
-   compose-dev-from-pub-imgs.yaml

---

To spin-up an entire Kubernetes cluster on AWS (EKS) with Terraform / OpenTofu, which uses 3 managed nodes across different AWS availability zones (AZs), then do the following. However, presently having more than 1 node is just for effect as the central DB by default is just SQLite for the "To-Do App" items. Though, you may configure the app to use a MySQL v5.7 server (which you cannot rely on using RDS since AWS has that on an EOL timeline which may have already passed by the time that you read this text).
(Tested with: Terraform CLI v1.7.1 [Linux] on Kubernetes v1.29 [EKS])

1. Initialize Terraform to download the providers and modules:
   `$ cd ./Kubernetes/cluster/1-provision-eks-cluster-with-terraform`
   `$ terraform init`

2. Review what Terraform will do (defaults to using AWS Region: `us-east-1` [N. Virginia]):
   `$ terraform plan`

3. If it all looks good to you, then (which will cost you money at standard EKS rates):
   `$ terraform apply -auto-approve`

4. Configure `kubectl` to be able to administer the newly-created K8s cluster
   and set it as the default K8s context:

    ```
    $ aws eks --region $(terraform output -raw region) update-kubeconfig \
    --name $(terraform output -raw cluster_name)

    # To confirm the K8s context and to get the cluster connection details:
    $ kubectl config current-context

    $ kubectl cluster-info
    ```
