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

        stage('Build Docker Image') {
            steps {
                script {
                    bat "docker build --network=host -t ${IMAGE_NAME}:${TAG_NAME} ."
                }
            }
        }

        stage('Save Docker Image') {
            steps {
                script {
                    bat "docker save -o ${LOCAL_IMAGE_PATH} ${IMAGE_NAME}:${TAG_NAME}"
                }
            }
        }

        stage('Login to GCP') {
            steps {
                script {
                    bat 'gcloud auth activate-service-account --key-file=%GOOGLE_APPLICATION_CREDENTIALS%'
                    bat 'gcloud config set project %PROJECT_ID%'
                }
            }
        }

        stage('Ensure VM Exists') {
            steps {
                script {
                    def instanceExists = bat (
                        script: "gcloud compute instances describe ${INSTANCE_NAME} --zone=${ZONE} --project=${PROJECT_ID}",
                        returnStatus: true
                    )
                    if (instanceExists != 0) {
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
                    }
                }
            }
        }

        stage('Transfer Docker Image to GCE') {
            steps {
                script {
                    bat '''
                        set CLOUDSDK_CORE_HTTP_TIMEOUT=600
                        gcloud compute scp %LOCAL_IMAGE_PATH% %INSTANCE_NAME%:%REMOTE_IMAGE_PATH% --zone=%ZONE% --project=%PROJECT_ID%
                    '''
                }
            }
        }

        stage('Deploy Docker Image on GCE') {
            steps {
                script {
                    bat "gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE} --command \"sudo docker load -i ${REMOTE_IMAGE_PATH}\""
                    bat "gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE} --command \"sudo docker run -d -p ${PORT}:${PORT} ${IMAGE_NAME}:${TAG_NAME}\""
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
