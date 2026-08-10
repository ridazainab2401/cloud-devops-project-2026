pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'ridazainab24' # Your DockerHub Username
        IMAGE_NAME     = 'flask-app'
    }

    stages {
        // 1. Checkout Code from Git
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // 2. Run Unit Tests (Using pytest in a docker container)
        stage('Unit Tests') {
            steps {
                sh 'docker run --rm -v $(pwd)/app:/app -w /app python:3.9-slim sh -c "pip install -r requirements.txt && pytest"'
            }
        }

        // 3. Build the Docker Image
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:latest ./app"
            }
        }

        // 4. Push to DockerHub (SSM Credentials Check!)
        stage('Push to DockerHub') {
            steps {
                // Fetch the DockerHub token securely from AWS SSM Parameter Store on-the-fly!
                withEnv(['DOCKER_PASSWORD=' + sh(script: "aws ssm get-parameter --name '/jenkins/dockerhub_password' --with-decryption --region eu-north-1 --query 'Parameter.Value' --output text", returnStdout: true).trim()]) {
                    sh "echo ${DOCKER_PASSWORD} | docker login -u ${DOCKERHUB_USER} --password-stdin"
                    sh "docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:latest"
                }
            }
        }

        
        stage('Deploy') {
            steps {
                // Since Jenkins is mounted to /var/run/docker.sock, it can start containers directly on the host!
                sh "docker stop ${IMAGE_NAME} || true"
                sh "docker rm ${IMAGE_NAME} || true"
                sh "docker run -d --name ${IMAGE_NAME} --network=cloud-devops-project-2026_default -p 5000:5000 ${DOCKERHUB_USER}/${IMAGE_NAME}:latest"
            }
        }
    }
}