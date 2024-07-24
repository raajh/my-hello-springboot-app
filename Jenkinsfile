pipeline {
    agent any

    environment {
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
        DOCKERHUB_USERNAME='ganshekar'
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'  // Use credentials ID here
    }

    stages {
        stage('Check GitHub Connectivity') {
            steps {
                script {
                    def response = bat(script: 'curl -I https://github.com', returnStdout: true).trim()
                    echo "Response: ${response}"
                }
            }
        }

        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/raajh/my-hello-springboot-app.git'
            }
        }

        stage('Build') {
            steps {
                bat '.\\mvnw clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${IMAGE_NAME}:latest")
                }
            }
        }

        stage('Login to DockerHub') {
            steps {
                script {
                    // Login to DockerHub using Jenkins credentials
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                        echo 'Logged in to DockerHub'
                    }
                }
            }
        }

        stage('Tag and Push Docker Image') {
            steps {
                script {
                    // Tag the image
                    bat "docker tag ${IMAGE_NAME}:latest ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
                    
                    // Push the image to DockerHub
                    bat "docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Deploy to GCP Cloud Run') {
            steps {
                echo 'Deploy to GCP Cloud Run stage is not using DockerHub credentials.'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
