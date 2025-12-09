pipeline {
    agent any
 
    environment {
        IMAGE_NAME       = "myapi-img"
        IMAGE_TAG        = "v1"
        CONTAINER_NAME   = "myapi-container"
        NETWORK_NAME     = "jenkins-net"
        API_PORT         = "8290"
        RESULTS_DIR      = "results"
    }
 
    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir() // Ensures a clean start
            }
        }
 
        stage('Checkout SCM') {
            steps {
                checkout scm // Pull latest code
            }
        }
 
        stage('Prepare Workspace') {
            steps {
                sh "mkdir -p ${RESULTS_DIR}"
                sh "rm -rf ${RESULTS_DIR}/* || true"
            }
        }
 
        stage('Create Docker Network') {
            steps {
                sh "docker network inspect ${NETWORK_NAME} || docker network create ${NETWORK_NAME}"
            }
        }
 
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }
 
        stage('Stop & Remove Old Containers') {
            steps {
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                    docker stop ${JMETER_CONTAINER} || true
                    docker rm ${JMETER_CONTAINER} || true
                """
            }
        }
 
        stage('Run Docker Container') {
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
 
        stage('Verify Container') {
            steps {
                sh "docker ps"
            }
        }
 
stage('Test APIs') {
    steps {
        script {
            def apis = [
                [method: 'GET', path: '/appointmentservices/getAppointment'],
                [method: 'PUT', path: '/appointmentservices/setAppointment']
            ]
 
            apis.each { api ->
                echo "Waiting for ${api.method} ${api.path}..."
                def ready = false
                for (int i = 1; i <= 18; i++) { // Increase attempts to 18 (3 minutes)
                    sleep 10
                    def status = sh(script: "curl -o /dev/null -s -w '%{http_code}' -X ${api.method} http://${CONTAINER_NAME}:${API_PORT}${api.path}", returnStdout: true).trim()
                    echo "Attempt ${i}: HTTP ${status}"
                    if (status == "200" || status == "202") {
                        ready = true
                        echo "${api.method} ${api.path} is ready!"
                        break
                    }
                }
                if (!ready) {
                    error "${api.method} ${api.path} not ready after 3 minutes"
                }
            }
        }
    }
}
 
 
stage('Verify JMX File') {
    steps {
        sh "ls -l ${WORKSPACE} || echo 'Workspace missing!'"
        sh "ls -l ${WORKSPACE}/${JMX_FILE} || echo 'JMX file not found!'"
    }
}
 
 

    }
 
    post {
        always {
            echo "✅ Pipeline finished!"
            cleanWs() // Cleanup workspace after build
        }
    }
}