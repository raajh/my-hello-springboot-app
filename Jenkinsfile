pipeline {
    agent any

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account-key') // Ensure this ID matches the one configured in Jenkins
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
        DOCKERHUB_USERNAME = 'ganshekar'
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    // Verify GitHub connectivity
                    def gitRepoUrl = 'https://github.com/raajh/my-hello-springboot-app.git'
                    bat "curl --head ${gitRepoUrl} | findstr /R /C:\"HTTP/\""
                    
                    // Clone the repository
                    git url: gitRepoUrl, branch: 'master'
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    // Use Maven to build the project
                    bat 'mvn clean package'
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    // Run tests
                    bat 'mvn test'
                }
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
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                        echo 'Logged in to DockerHub'
                    }
                }
            }
        }

        stage('Tag and Push Docker Image') {
            steps {
                script {
                    bat "docker tag ${IMAGE_NAME}:latest ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
                    bat "docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
                }
            }
        }


        stage('Deploy to GCP') {
            steps {
                script {
                    // Authenticate with GCP
                    bat 'gcloud auth activate-service-account --key-file=%GOOGLE_APPLICATION_CREDENTIALS%'

                    // Deploy the Docker image to Google Cloud Run
                    bat '''
                        gcloud run deploy my-spring-boot-app ^
                        --image gcr.io/%PROJECT_ID%/%IMAGE_NAME%:latest ^
                        --platform managed ^
                        --region your-region ^
                        --allow-unauthenticated
                    '''
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
            cleanWs()  // Clean workspace after build
        }
    }
}
