pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        DOCKERHUB_USER  = 'ridazainab24'
        IMAGE_NAME      = 'flask-app'
        SONAR_PROJECT   = 'cloud-devops-project-2026'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                sh 'docker run --rm -v $(pwd)/app:/app -w /app python:3.9-slim sh -c "pip install -r requirements.txt && pytest"'
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh '''
                        docker run --rm \
                          -e SONAR_HOST_URL="$SONAR_HOST_URL" \
                          -v "$PWD":/usr/src \
                          -w /usr/src sonarsource/sonar-scanner-cli:latest \
                          -Dsonar.projectKey="$SONAR_PROJECT" \
                          -Dsonar.projectName="$SONAR_PROJECT" \
                          -Dsonar.sources=app \
                          -Dsonar.login="$SONAR_AUTH_TOKEN" \
                          -Dsonar.exclusions=**/__pycache__/**,**/*.pyc,**/venv/**,**/.venv/**,**/terraform/**,**/ansible/**
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build') {
            steps {
                sh "docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:latest ./app"
            }
        }

        stage('Push') {
            steps {
                withEnv(['DOCKER_PASSWORD=' + sh(script: "aws ssm get-parameter --name '/jenkins/dockerhub_password' --with-decryption --region eu-north-1 --query 'Parameter.Value' --output text", returnStdout: true).trim()]) {
                    sh 'echo "$DOCKER_PASSWORD" | docker login -u "$DOCKERHUB_USER" --password-stdin'
                    sh "docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Deploy') {
            steps {
                sh "docker stop ${IMAGE_NAME} || true"
                sh "docker rm ${IMAGE_NAME} || true"
                sh "docker run -d --name ${IMAGE_NAME} --network=cloud-devops-project-2026_default -p 5000:5000 ${DOCKERHUB_USER}/${IMAGE_NAME}:latest"
            }
        }
    }
}