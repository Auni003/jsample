pipeline {
    agent any

    environment {
        IMAGE_NAME       = "myapi-img"
        IMAGE_TAG        = "v1"
        CONTAINER_NAME   = "myapi-container"
        NETWORK_NAME     = "jenkins-net"
        API_PORT         = "8290"
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
                sh """
                    docker network inspect ${NETWORK_NAME} >/dev/null 2>&1 \
                    || docker network create ${NETWORK_NAME}
                """
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
                    docker stop ${CONTAINER_NAME} >/dev/null 2>&1 || true
                    docker rm   ${CONTAINER_NAME} >/dev/null 2>&1 || true
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

                        def ok = false

                        for (int i = 1; i <= 18; i++) {

                            sleep 10

                            def code = sh(
                                script: "curl -o /dev/null -s -w '%{http_code}' -X ${api.method} http://localhost:${API_PORT}${api.path}",
                                returnStdout: true
                            ).trim()

                            echo "Attempt ${i}: HTTP ${code}"

                            if (code == "200" || code == "202") {
                                echo "✔ ${api.method} ${api.path} is READY"
                                ok = true
                                break
                            }
                        }

                        if (!ok) {
                            error "❌ ${api.method} ${api.path} NOT ready after 3 minutes"
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
