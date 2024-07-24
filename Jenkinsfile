pipeline {
    agent any

    environment {
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
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
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                        def image = docker.image("${IMAGE_NAME}:latest")
                        image.push('latest') // Explicitly specify the tag to push
                    }
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
