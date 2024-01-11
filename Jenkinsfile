pipeline {
    agent any

    stages {
        stage('Testing Webhook') {
            steps {
                sh '''
                    echo 'Hello, world from the GitLab webhook!'
                    uname -a
                    echo "Current user: $USER"
                '''
            }
        }
    }
}
