pipeline {
    agent any

    environment {
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
        DOCKERHUB_USERNAME='ganshekar'
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'  // Use credentials ID here
        CLOUD_RUN_SERVICE_NAME=my-spring-boot-app
        REGION=us-central1
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
                script {
                    // Deploy to Google Cloud Run
                    withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GCP_KEY_FILE')]) {
                        bat "echo %GCP_KEY_FILE% > keyfile.json"
                        bat "gcloud auth activate-service-account --key-file=keyfile.json"
                        bat "gcloud config set project ${PROJECT_ID}"
                        bat "gcloud run deploy ${CLOUD_RUN_SERVICE_NAME} --image gcr.io/${PROJECT_ID}/${IMAGE_NAME}:latest --platform managed --region ${REGION} --allow-unauthenticated"
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
