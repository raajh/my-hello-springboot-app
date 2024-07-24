
pipeline {
    agent any

    environment {
        // Define environment variables
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials') // Jenkins credentials ID for DockerHub
        GCP_SERVICE_ACCOUNT_KEY = credentials('gcp-service-account-key') // Jenkins credentials ID for GCP service account
        PROJECT_ID = 'ds-ms-microservices' // GCP project ID
        IMAGE_NAME = 'my-spring-boot-app'
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout the source code from the master branch
                git branch: 'master', url: 'https://github.com/raajh/my-hello-springboot-app.git'
            }
        }

        stage('Build') {
            steps {
                // Build the Spring Boot application using Maven
                sh './mvnw clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                // Build Docker image
                script {
                    docker.build("${IMAGE_NAME}:latest")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                // Push the Docker image to DockerHub
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS) {
                        docker.image("${IMAGE_NAME}:latest").push()
                    }
                }
            }
        }

        stage('Deploy to GCP Cloud Run') {
            steps {
                // Deploy the Docker image to GCP Cloud Run
                script {
                    withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GCP_KEY_FILE')]) {
                        sh '''
                            echo $GCP_KEY_FILE > keyfile.json
                            gcloud auth activate-service-account --key-file=keyfile.json
                            gcloud config set project $PROJECT_ID
                            gcloud run deploy my-springboot-app --image gcr.io/$PROJECT_ID/${IMAGE_NAME}:latest --platform managed --region us-central1 --allow-unauthenticated
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up workspace after the build
            cleanWs()
        }
    }
}
