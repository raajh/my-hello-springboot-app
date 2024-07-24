pipeline {
    agent any

    environment {
        PROJECT_ID = 'ds-ms-microservices'
        IMAGE_NAME = 'my-spring-boot-app'
        DOCKERHUB_USERNAME = 'ganshekar'
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        MAVEN_HOME = 'C:\\Program Files\\apache-maven-3.9.8'
        PATH = "${env.MAVEN_HOME}\\bin;${env.PATH}"
    }

    stages {
        stage('Check PATH Variable') {
            steps {
                bat 'echo %PATH%'
            }
        }

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
                bat 'mvn clean package'
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
