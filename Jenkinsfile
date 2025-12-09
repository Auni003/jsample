pipeline {
    agent any

    environment {
        DOCKER_IMG = "myapi-img:v1"
        DOCKER_CONTAINER = "myapi-container"
        NETWORK = "jenkins-net"
        API_HEALTH_URL = "http://${DOCKER_CONTAINER}:8290/health"
        API_TEST_URL = "http://${DOCKER_CONTAINER}:8290/appointmentservices/getAppointment"
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Clean Workspace') {
            steps {
                deleteDir()
                checkout scm
            }
        }

        stage('Prepare Workspace') {
            steps {
                sh 'mkdir -p results'
                sh 'rm -rf results/*'
            }
        }

        stage('Create Docker Network') {
            steps {
                sh '''
                    if ! docker network inspect ${NETWORK} >/dev/null 2>&1; then
                        docker network create ${NETWORK}
                    fi
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image ${DOCKER_IMG}"
                sh "docker build --no-cache -t ${DOCKER_IMG} ."
            }
        }

        stage('Stop & Remove Old Containers') {
            steps {
                sh '''
                    docker stop ${DOCKER_CONTAINER} || true
                    docker rm ${DOCKER_CONTAINER} || true
                    docker stop jmeter-agent || true
                    docker rm jmeter-agent || true
                '''
            }
        }

        stage('Run Docker Container') {
            steps {
                sh """
                    docker run -d --name ${DOCKER_CONTAINER} \
                    --network ${NETWORK} \
                    -p 8290:8290 \
                    ${DOCKER_IMG}
                """
            }
        }

        stage('Wait for MI to Start') {
            steps {
                script {
                    echo "⏳ Waiting for Micro Integrator to start (max 60 seconds)..."

                    def ready = false

                    for (int i = 1; i <= 12; i++) {
                        def code = sh(
                            script: "curl -o /dev/null -s -w '%{http_code}' ${API_HEALTH_URL}",
                            returnStdout: true
                        ).trim()

                        if (code == "200") {
                            echo "✅ Micro Integrator is UP!"
                            ready = true
                            break
                        } else {
                            echo "MI not ready yet... (${i}/12). Returned HTTP: ${code}"
                            sleep 5
                        }
                    }

                    if (!ready) {
                        error("❌ Micro Integrator failed to start within timeout.")
                    }
                }
            }
        }

        stage('Test API Endpoint') {
            steps {
                script {
                    echo "Testing API: ${API_TEST_URL}"
                    def code = sh(
                        script: "curl -o /dev/null -s -w '%{http_code}' ${API_TEST_URL}",
                        returnStdout: true
                    ).trim()

                    echo "API Response Code: ${code}"

                    if (code != "200") {
                        error("❌ API endpoint test failed (returned ${code})")
                    }
                }
            }
        }

        stage('Verify JMX File') {
            when {
                expression { fileExists('test-plan.jmx') }
            }
            steps {
                echo "JMX file found."
            }
        }

        stage('Run JMeter Load Test') {
            when {
                expression { fileExists('test-plan.jmx') }
            }
            steps {
                sh '''
                    docker run --rm --name jmeter-agent \
                    --network ${NETWORK} \
                    -v $PWD:/tests \
                    justb4/jmeter \
                    -n -t /tests/test-plan.jmx \
                    -l /tests/results/results.jtl \
                    -e -o /tests/results/html
                '''
            }
        }

        stage('Archive JMeter Report') {
            when {
                expression { fileExists('results/results.jtl') }
            }
            steps {
                archiveArtifacts artifacts: 'results/**/*', fingerprint: true
            }
        }

        stage('Publish JMeter HTML Report') {
            when {
                expression { fileExists('results/html/index.html') }
            }
            steps {
                publishHTML([
                    reportDir: 'results/html',
                    reportFiles: 'index.html',
                    reportName: 'JMeter HTML Report'
                ])
            }
        }
    }

    post {
        always {
            echo "🔥 Cleaning workspace..."
            cleanWs()
            echo "🏁 Pipeline finished!"
        }
    }
}
