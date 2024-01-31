# To-Do App

A Helm chart for Kubernetes with Docker's To-Do App with modifications by [junktext](https://junktext.com).

## Maintenance Status

This app is just used to demonstrate a working Helm chart, so the codebase itself is not kept up-to-date for security and performance issues.
Therefore, unless you fork the code and maintain it yourself, it is NOT advised to run this app for production usage!

## Usage

Get the To-Do app running in a browser by opening up port 3000, by default.

For instance, run the following command and get the EXTERNAL-IP listed:

  $ kubectl get svc

If you are running the app in minikube, you first need to open up another 
terminal and run the following as a non-root user with sudo access:

  $ minikube tunnel  # Please wait to type in your password.
  
## Source Code

https://gitlab.com/junktext/example-docker-getting-started
