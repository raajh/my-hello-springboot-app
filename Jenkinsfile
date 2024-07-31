pipeline {
    agent any

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account-key')
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
        DOCKERHUB_USERNAME = 'ganshekar'
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        INSTANCE_NAME = 'instance-2' // replace with your instance name
        ZONE = 'us-central1-a' // replace with your GCE zone
        PORT = '8080' // replace with your application's port
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
                            bat 'echo Building Docker image...'
                            bat "docker build --network=host -t ${IMAGE_NAME}:latest ."
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

        stage('Login to GCR') {
            steps {
                script {
                    try {
                        bat 'gcloud auth configure-docker'
                        echo 'Logged in to Google Container Registry'
                    } catch (Exception e) {
                        error "GCR login failed: ${e.getMessage()}"
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

        stage('Deploy to GCE') {
            steps {
                script {
                    try {
                        // Authenticate with GCP
                        bat 'gcloud auth activate-service-account --key-file=%GOOGLE_APPLICATION_CREDENTIALS%'
                        
                        // Create a VM instance if it doesn't exist
                        bat '''
                            gcloud compute instances create %INSTANCE_NAME% ^
                            --project=%PROJECT_ID% ^
                            --zone=%ZONE% ^
                            --machine-type=e2-micro ^
                            --image-family=debian-10 ^
                            --image-project=debian-cloud ^
                            --tags=http-server,https-server
                        '''
                        
                        // SSH into the VM and run Docker commands
                        bat '''
                            gcloud compute ssh %INSTANCE_NAME% --zone=%ZONE% --command "sudo docker pull gcr.io/%PROJECT_ID%/%IMAGE_NAME%:latest"
                            gcloud compute ssh %INSTANCE_NAME% --zone=%ZONE% --command "sudo docker run -d -p %PORT%:%PORT% gcr.io/%PROJECT_ID%/%IMAGE_NAME%:latest"
                        '''
                        
                        echo 'Deployment to GCE completed'
                    } catch (Exception e) {
                        error "GCE deployment failed: ${e.getMessage()}"
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
