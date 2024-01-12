pipeline {
    agent any

    stages {
        /*
        stage('Testing Webhook') {
            steps {
                sh '''
                    echo 'Hello, world from the GitLab webhook!'
                    uname -a
                    echo "Current user: $USER"
                    echo "Current directory: $PWD"
                '''
            }
        }
        */

        stage('Build & Test') {
            steps {
                nodejs('NodeJS-v12-with-Yarn-v1') {
                    sh '''
                        echo ---[ Versions of Yarn, Node.js, and related dependencies. ]---
                        yarn versions

                        echo ---[ Installing the app's JS dependencies via Yarn. ]---
                        yarn install

                        echo ---[ JS Unit Testing via Jest ]---
                        yarn test
                    '''
                }
            }
        }
    }
}
