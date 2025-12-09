pipeline {
    agent any

    environment {
        IMAGE_NAME     = "myapi-img"
        IMAGE_TAG      = "v1"
        CONTAINER_NAME = "myapi-container"
        NETWORK_NAME   = "jenkins-net"
        API_PORT       = "8290"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Create Docker Network') {
            steps {
                sh "docker network inspect ${NETWORK_NAME} || docker network create ${NETWORK_NAME}"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Stop & Remove Old Container') {
            steps {
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                """
            }
        }

        stage('Run API Container') {
            steps {
                sh """
                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    --network ${NETWORK_NAME} \
                    -p ${API_PORT}:${API_PORT} \
                    ${IMAGE_NAME}:${IMAGE_TAG}
                """

                echo "⏳ Waiting 40 seconds for WSO2 MI to fully start and deploy CAR file..."
                sleep 40
            }
        }

        stage('Verify API Health') {
            steps {
                script {
                    def apis = [
                        [method: 'GET', path: '/appointmentservices/getAppointment'],
                        [method: 'PUT', path: '/appointmentservices/setAppointment']
                    ]

                    apis.each { api ->
                        echo "Checking: ${api.method} ${api.path}"

                        def ready = false
                        for (int i = 1; i <= 10; i++) {
                            sleep 10
                            def status = sh(
                                script: "curl -o /dev/null -s -w '%{http_code}' -X ${api.method} http://${CONTAINER_NAME}:${API_PORT}${api.path}",
                                returnStdout: true
                            ).trim()

                            echo "Attempt ${i}: HTTP ${status}"

                            if (status == "200" || status == "202") {
                                ready = true
                                echo "✔ API ready: ${api.method} ${api.path}"
                                break
                            }
                        }

                        if (!ready) {
                            error "❌ API FAILED: ${api.method} ${api.path} not ready"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline completed."
            cleanWs()
        }
    }
}
