pipeline {
    agent any

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account-key')
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
        GCR_IMAGE_NAME = "gcr.io/${PROJECT_ID}/${IMAGE_NAME}"
        PORT = '8080'
        LOCAL_IMAGE_PATH = 'my-spring-boot-app.tar'
        REMOTE_IMAGE_PATH = '/tmp/my-spring-boot-app.tar'
        INSTANCE_NAME = 'instance-2'
        ZONE = 'us-central1-b'
        PUBLIC_IP = '34.132.144.80'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/raajh/my-hello-springboot-app.git', branch: 'master'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build --network=host -t ${IMAGE_NAME}:latest ."
            }
        }

        stage('Tag and Push Docker Image') {
            steps {
                sh """
                    docker tag ${IMAGE_NAME}:latest ${GCR_IMAGE_NAME}:latest
                    docker push ${GCR_IMAGE_NAME}:latest
                """
            }
        }

        stage('Save Docker Image') {
            steps {
                sh "docker save -o ${LOCAL_IMAGE_PATH} ${IMAGE_NAME}:latest"
            }
        }

        stage('Login to GCP') {
            steps {
                sh 'gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}'
                sh 'gcloud config set project ${PROJECT_ID}'
            }
        }

        stage('Ensure VM Exists') {
            steps {
                script {
                    def instanceExists = sh(script: "gcloud compute instances describe ${INSTANCE_NAME} --zone=${ZONE} --project=${PROJECT_ID}", returnStatus: true)
                    if (instanceExists != 0) {
                        sh '''
                            gcloud compute instances create ${INSTANCE_NAME} \
                                --zone=${ZONE} \
                                --project=${PROJECT_ID} \
                                --machine-type=e2-medium \
                                --image-family=debian-10 \
                                --image-project=debian-cloud
                        '''
                        sh '''
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
                sh '''
                    gcloud compute scp ${LOCAL_IMAGE_PATH} ${INSTANCE_NAME}:${REMOTE_IMAGE_PATH} --zone=${ZONE} --project=${PROJECT_ID}
                '''
            }
        }

        stage('Deploy Docker Image on GCE') {
            steps {
                sh '''
                    gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE} --command "
                        # Load Docker image
                        sudo docker load -i ${REMOTE_IMAGE_PATH}

                        # Pull the image from GCR
                        sudo docker pull ${GCR_IMAGE_NAME}:latest

                        # Stop any running containers using the old image
                        sudo docker stop \$(sudo docker ps -q --filter 'ancestor=${IMAGE_NAME}:latest') || true

                        # Remove all stopped containers
                        sudo docker rm \$(sudo docker ps -a -q) || true

                        # Remove the old image if exists
                        sudo docker rmi \$(sudo docker images -q ${IMAGE_NAME}:latest) || true

                        # Run the new container
                        sudo docker run -d --name my-spring-boot-app -p ${PORT}:${PORT} ${GCR_IMAGE_NAME}:latest

                        # Ensure the container is running
                        sudo docker ps
                    "
                '''
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
