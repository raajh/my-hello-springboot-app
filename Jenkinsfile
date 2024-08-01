pipeline {
    agent any

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account-key')
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
        DOCKERHUB_USERNAME = 'ganshekar'
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        INSTANCE_NAME = 'instance-2'
        ZONE = 'us-central1-b'
        PORT = '8080'
        LOCAL_IMAGE_PATH = 'my-spring-boot-app.tar'
        REMOTE_IMAGE_PATH = '/tmp/my-spring-boot-app.tar'
        PUBLIC_IP = '34.132.144.80' // Public IP for testing
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        TAG_NAME = "v${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    def gitRepoUrl = 'https://github.com/raajh/my-hello-springboot-app.git'
                    echo "Checking GitHub repository: ${gitRepoUrl}"
                    git url: gitRepoUrl, branch: 'master'
                    bat 'git rev-parse HEAD'
                }
            }
        }

        stage('List Files') {
            steps {
                script {
                    bat 'dir'
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
                            echo 'Building Docker image...'
                            bat "docker build --network=host -t ${IMAGE_NAME}:${TAG_NAME} ."
                            bat "docker images ${IMAGE_NAME} --format '{{.Tag}}'"
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
                        bat "docker save -o ${LOCAL_IMAGE_PATH} ${IMAGE_NAME}:${TAG_NAME}"
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

        stage('Ensure VM Exists') {
            steps {
                script {
                    try {
                        def instanceExists = bat (
                            script: "gcloud compute instances describe ${INSTANCE_NAME} --zone=${ZONE} --project=${PROJECT_ID}",
                            returnStatus: true
                        )
                        if (instanceExists != 0) {
                            echo 'VM instance does not exist. Creating VM instance...'
                            bat '''
                                gcloud compute instances create ${INSTANCE_NAME} \
                                    --zone=${ZONE} \
                                    --project=${PROJECT_ID} \
                                    --machine-type=e2-medium \
                                    --image-family=debian-10 \
                                    --image-project=debian-cloud
                            '''
                            bat '''
                                gcloud compute firewall-rules create allow-8080 \
                                    --allow tcp:${PORT} \
                                    --network default \
                                    --source-ranges=0.0.0.0/0 \
                                    --description="Allow port ${PORT} access"
                            '''
                        } else {
                            echo 'VM instance already exists.'
                        }
                    } catch (Exception e) {
                        error "VM creation failed: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Transfer Docker Image to GCE') {
            steps {
                script {
                    try {
                        bat '''
                            set CLOUDSDK_CORE_HTTP_TIMEOUT=600
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
                echo 'Starting deployment to GCE...'
                bat """
                    echo 'Loading Docker image...'
                    gcloud compute ssh ${env.INSTANCE_NAME} --zone=${env.ZONE} --command "sudo docker load -i ${env.REMOTE_IMAGE_PATH}"
                    
                    echo 'Stopping old containers...'
                    gcloud compute ssh ${env.INSTANCE_NAME} --zone=${env.ZONE} --command "sudo docker stop \$(sudo docker ps -q) || true"
                    
                    echo 'Removing old containers...'
                    gcloud compute ssh ${env.INSTANCE_NAME} --zone=${env.ZONE} --command "sudo docker rm \$(sudo docker ps -a -q) || true"
                    
                    echo 'Running new container...'
                    gcloud compute ssh ${env.INSTANCE_NAME} --zone=${env.ZONE} --command "sudo docker run -d -p ${env.PORT}:${env.PORT} ${env.IMAGE_NAME}:${env.TAG_NAME}"
                """
                echo 'Deployment to GCE completed'
            } catch (Exception e) {
                error "GCE deployment failed: ${e.getMessage()}"
            }
        }
    }
}


    post {
        success {
            echo 'Pipeline completed successfully!'
            script {
                echo "Check the deployed application at: http://${PUBLIC_IP}:${PORT}/health"
            }
        }
        failure {
            echo 'Pipeline failed.'
        }
        always {
            cleanWs()
        }
    }
}
