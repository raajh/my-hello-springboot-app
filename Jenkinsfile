pipeline {
    agent any

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account-key')
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
        DOCKERHUB_USERNAME = 'ganshekar'
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        INSTANCE_NAME = 'instance-2' // replace with your instance name
        ZONE = 'us-central1-c' // replace with your GCE zone
        PORT = '8080' // replace with your application's port
        LOCAL_IMAGE_PATH = 'my-spring-boot-app.tar'
        REMOTE_IMAGE_PATH = '/tmp/my-spring-boot-app.tar'
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

        stage('Save Docker Image') {
            steps {
                script {
                    try {
                        bat "docker save -o ${LOCAL_IMAGE_PATH} ${IMAGE_NAME}:latest"
                        echo 'Docker image saved'
                    } catch (Exception e) {
                        error "Saving Docker image failed: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Login to GCP') {
            steps {
                script {
                    try {
                        bat 'gcloud auth activate-service-account --key-file=%GOOGLE_APPLICATION_CREDENTIALS%'
                        bat 'gcloud config set project %PROJECT_ID%'
                        echo 'Authenticated with GCP'
                    } catch (Exception e) {
                        error "GCP authentication failed: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Transfer Docker Image to GCE') {
            steps {
                script {
                    try {
                        bat '''
                            gcloud compute scp %LOCAL_IMAGE_PATH% %INSTANCE_NAME%:%REMOTE_IMAGE_PATH% --zone=%ZONE% --project=%PROJECT_ID%
                        '''
                        echo 'Docker image transferred to GCE VM'
                    } catch (Exception e) {
                        error "Image transfer to GCE failed: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Deploy Docker Image on GCE') {
            steps {
                script {
                    try {
                        // SSH into the VM and run Docker commands
                        bat '''
                            gcloud compute ssh %INSTANCE_NAME% --zone=%ZONE% --command "sudo docker load -i %REMOTE_IMAGE_PATH%"
                            gcloud compute ssh %INSTANCE_NAME% --zone=%ZONE% --command "sudo docker run -d -p %PORT%:%PORT% ${IMAGE_NAME}:latest"
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
} // Add this closing brace to properly close the pipeline block
