pipeline {
    agent any

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account-key')
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
        DOCKERHUB_USERNAME = 'ganshekar'
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    def gitRepoUrl = 'https://github.com/raajh/my-hello-springboot-app.git'
                    bat "curl --head ${gitRepoUrl} | findstr /R /C:\"HTTP/\""
                    git url: gitRepoUrl, branch: 'master'
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    bat 'mvn clean package'
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    bat 'mvn test'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    retry(3) {
                        try {
                            docker.build("${IMAGE_NAME}:latest")
                        } catch (Exception e) {
                            error "Docker build failed: ${e.getMessage()}"
                        }
                    }
                }
            }
        }

        stage('Login to DockerHub') {
            steps {
                script {
                    try {
                        docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                            echo 'Logged in to DockerHub'
                        }
                    } catch (Exception e) {
                        error "Docker login failed: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Tag and Push Docker Image') {
            steps {
                script {
                    try {
                        bat "docker tag ${IMAGE_NAME}:latest gcr.io/${PROJECT_ID}/${IMAGE_NAME}:latest"
                        bat "docker push gcr.io/${PROJECT_ID}/${IMAGE_NAME}:latest"
                    } catch (Exception e) {
                        error "Docker push failed: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Deploy to GCP') {
            steps {
                script {
                    try {
                        bat 'gcloud auth activate-service-account --key-file=%GOOGLE_APPLICATION_CREDENTIALS%'
                        bat '''
                            gcloud run deploy my-spring-boot-app ^
                            --image gcr.io/%PROJECT_ID%/%IMAGE_NAME%:latest ^
                            --platform managed ^
                            --region us-central1 ^
                            --allow-unauthenticated ^
                            --project %PROJECT_ID%
                        '''
                    } catch (Exception e) {
                        error "GCP deployment failed: ${e.getMessage()}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
        always {
            cleanWs()
        }
    }
}
