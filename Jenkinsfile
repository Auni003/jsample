pipeline {
    agent any
    environment {
        IMAGE_NAME = "myapi"
        CONTAINER_NAME = "myapi-container"
        API_PORT = "8290"
        MANAGEMENT_PORT = "8253"
        INTERNAL_PORT = "9164"
    }
    stages {
        stage('Prepare') {
            steps {
                echo 'Workspace ready: Jenkins will clone repository automatically'
            }
        }
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image ${IMAGE_NAME}:v1"
                sh "docker build -t ${IMAGE_NAME}:v1 -f api/Dockerfile.api ./api"
            }
        }
        stage('Stop & Remove Old Container') {
            steps {
                echo 'Stopping and removing old container if exists'
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                """
            }
        }
        stage('Run Docker Container') {
            steps {
                echo 'Running API container'
                sh """
                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    -p ${API_PORT}:${API_PORT} \
                    -p ${MANAGEMENT_PORT}:${MANAGEMENT_PORT} \
                    -p ${INTERNAL_PORT}:${INTERNAL_PORT} \
                    ${IMAGE_NAME}:v1
                """
            }
        }
        stage('Verify') {
            steps {
                echo 'Listing running Docker containers'
                sh "docker ps"
            }
        }
        stage('Test API') {
            steps {
                echo 'Testing API endpoint from Jenkins container'
                sh "sleep 10 && curl -I http://${CONTAINER_NAME}:${API_PORT}/appointmentservices/getAppointment || true"
            }
        }
    }
    post {
        always {
            echo 'Pipeline finished!'
        }
    }
}
