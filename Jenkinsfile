pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        GCP_SERVICE_ACCOUNT_KEY = credentials('gcp-service-account-key')
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
    }

    stages {
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

       

stage('Push Docker Image') {
    steps {
        script {
            docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS) {
                docker.image("my-spring-boot-app:latest").push("latest")
            }
        }
    }
}





        
        stage('Deploy to GCP Cloud Run') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GCP_KEY_FILE')]) {
                        bat '''
                            echo %GCP_KEY_FILE% > keyfile.json
                            gcloud auth activate-service-account --key-file=keyfile.json
                            gcloud config set project %PROJECT_ID%
                            gcloud run deploy my-springboot-app --image gcr.io/%PROJECT_ID%/${IMAGE_NAME}:latest --platform managed --region us-central1 --allow-unauthenticated
                        '''
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
