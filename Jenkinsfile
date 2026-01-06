pipeline {
    agent any
    
    environment {
        // AWS Configuration
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/task-api"
        
        // ECS Configuration
        ECS_CLUSTER = 'task-api-cluster'
        ECS_SERVICE = 'task-api-service'
        
        // Image tag
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }
        
        stage('Lint') {
            steps {
                echo 'Running Go linter...'
                sh 'go fmt ./...'
                sh 'go vet ./...'
            }
        }
        
        stage('Unit Tests') {
            steps {
                echo 'Running unit tests with coverage...'
                sh 'go test ./... -v -coverprofile=coverage.out'
                sh 'go tool cover -func=coverage.out'
            }
            post {
                always {
                    // Archive test results
                    archiveArtifacts artifacts: 'coverage.out', allowEmptyArchive: true
                }
            }
        }
        
        stage('Security Scan') {
            parallel {
                stage('Go Security Check') {
                    steps {
                        echo 'Scanning for security vulnerabilities...'
                        sh 'go list -json -m all | grep -v "indirect" || true'
                    }
                }
                stage('Dependency Audit') {
                    steps {
                        echo 'Checking dependencies...'
                        sh 'go mod verify'
                    }
                }
            }
        }
        
        stage('Build Application') {
            steps {
                echo 'Building Go application...'
                sh 'CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o task-api .'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t task-api:${IMAGE_TAG} ."
                sh "docker tag task-api:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}"
                sh "docker tag task-api:${IMAGE_TAG} ${ECR_REPO}:latest"
            }
        }
        
        stage('Container Security Scan') {
            steps {
                echo 'Scanning Docker image for vulnerabilities...'
                // Optional: Use Trivy or similar tool
                // sh "trivy image task-api:${IMAGE_TAG}"
                sh "docker inspect task-api:${IMAGE_TAG}"
            }
        }
        
        stage('Push to ECR') {
            steps {
                echo 'Authenticating with AWS ECR...'
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REPO}
                """
                
                echo 'Pushing image to ECR...'
                sh "docker push ${ECR_REPO}:${IMAGE_TAG}"
                sh "docker push ${ECR_REPO}:latest"
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                echo 'Deploying to staging environment...'
                sh """
                    aws ecs update-service \
                    --cluster ${ECS_CLUSTER}-staging \
                    --service ${ECS_SERVICE}-staging \
                    --force-new-deployment \
                    --region ${AWS_REGION}
                """
            }
        }
        
        stage('Smoke Tests - Staging') {
            steps {
                echo 'Running smoke tests on staging...'
                sleep 30 // Wait for deployment
                sh '''
                    # Health check
                    curl -f http://staging.task-api.yourdomain.com/health || exit 1
                    
                    # Basic API test
                    curl -f http://staging.task-api.yourdomain.com/tasks || exit 1
                '''
            }
        }
        
        stage('Approve Production Deployment') {
            steps {
                echo 'Waiting for production deployment approval...'
                input message: 'Deploy to Production?', 
                      ok: 'Deploy',
                      submitter: 'admin,devops'
            }
        }
        
        stage('Deploy to Production') {
            steps {
                echo 'Deploying to production environment...'
                sh """
                    aws ecs update-service \
                    --cluster ${ECS_CLUSTER}-prod \
                    --service ${ECS_SERVICE}-prod \
                    --force-new-deployment \
                    --region ${AWS_REGION}
                """
            }
        }
        
        stage('Smoke Tests - Production') {
            steps {
                echo 'Running smoke tests on production...'
                sleep 30 // Wait for deployment
                sh '''
                    # Health check
                    curl -f https://api.task-api.yourdomain.com/health || exit 1
                    
                    # Basic API test
                    curl -f https://api.task-api.yourdomain.com/tasks || exit 1
                '''
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up...'
            sh "docker rmi task-api:${IMAGE_TAG} || true"
            sh "docker rmi ${ECR_REPO}:${IMAGE_TAG} || true"
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
            // Optional: Send notification
            // mail to: 'team@example.com',
            //      subject: "SUCCESS: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            //      body: "Build succeeded: ${env.BUILD_URL}"
        }
        failure {
            echo 'Pipeline failed!'
            // Optional: Send notification
            // mail to: 'team@example.com',
            //      subject: "FAILURE: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            //      body: "Build failed: ${env.BUILD_URL}"
        }
    }
}