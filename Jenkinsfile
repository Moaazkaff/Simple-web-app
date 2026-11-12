pipeline{
    agent any

    environment{
        DOCKERHUB_CREDENTIALS=credentials('dockerhub')
    }

    stages{

        stage('Dockerhub login'){
            sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
        }

        stage('Build and Push Dockerfile'){
            sh 'ansible-playbook playbook2.yml'
        }
    }
}