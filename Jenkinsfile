pipeline {
    agent any

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account-key')
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
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
                        sudo docker load -i ${REMOTE_IMAGE_PATH}
                        sudo docker stop \$(sudo docker ps -q --filter 'ancestor=${IMAGE_NAME}:latest') || true
                        sudo docker rm \$(sudo docker ps -a -q) || true
                        sudo docker rmi \$(sudo docker images -q ${IMAGE_NAME}:latest) || true
                        sudo docker run -d --name my-spring-boot-app -p ${PORT}:${PORT} ${IMAGE_NAME}:latest
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
