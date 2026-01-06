#!/bin/bash

# AWS Setup Script for Task API Jenkins Pipeline
# This script automates the AWS infrastructure setup for ECS deployment

set -e

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="6469-7752-661"
ECR_REPO="task-api"
ECS_CLUSTER_STAGING="task-api-cluster-staging"
ECS_CLUSTER_PROD="task-api-cluster-prod"
ECS_SERVICE_STAGING="task-api-service-staging"
ECS_SERVICE_PROD="task-api-service-prod"
TASK_FAMILY="task-api"

echo "=========================================="
echo "AWS Setup for Task API Pipeline"
echo "=========================================="
echo "Region: $AWS_REGION"
echo "Account ID: $AWS_ACCOUNT_ID"
echo ""

# Step 1: Create ECR Repository
echo "[1/5] Creating ECR Repository..."
aws ecr create-repository \
  --repository-name $ECR_REPO \
  --region $AWS_REGION \
  --description "Task API Docker images" || echo "Repository already exists"

ECR_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO"
echo "✓ ECR Repository created: $ECR_URL"
echo ""

# Step 2: Create CloudWatch Log Groups
echo "[2/5] Creating CloudWatch Log Groups..."
aws logs create-log-group \
  --log-group-name /ecs/task-api-staging \
  --region $AWS_REGION 2>/dev/null || echo "Log group already exists (staging)"

aws logs create-log-group \
  --log-group-name /ecs/task-api-prod \
  --region $AWS_REGION 2>/dev/null || echo "Log group already exists (prod)"

echo "✓ CloudWatch log groups created"
echo ""

# Step 3: Create ECS Clusters
echo "[3/5] Creating ECS Clusters..."
aws ecs create-cluster \
  --cluster-name $ECS_CLUSTER_STAGING \
  --region $AWS_REGION \
  --capacity-providers FARGATE || echo "Cluster already exists (staging)"

aws ecs create-cluster \
  --cluster-name $ECS_CLUSTER_PROD \
  --region $AWS_REGION \
  --capacity-providers FARGATE || echo "Cluster already exists (prod)"

echo "✓ ECS Clusters created"
echo ""

# Step 4: Register Task Definition (Staging)
echo "[4/5] Registering Task Definitions..."

# Create task definition JSON
cat > /tmp/task-definition-staging.json << EOF
{
  "family": "$TASK_FAMILY",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "$TASK_FAMILY",
      "image": "$ECR_URL:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/task-api-staging",
          "awslogs-region": "$AWS_REGION",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "environment": [
        {
          "name": "ENV",
          "value": "staging"
        }
      ]
    }
  ],
  "executionRoleArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/ecsTaskExecutionRole",
  "tags": [
    {
      "key": "Environment",
      "value": "staging"
    }
  ]
}
EOF

aws ecs register-task-definition \
  --cli-input-json file:///tmp/task-definition-staging.json \
  --region $AWS_REGION > /dev/null

echo "✓ Task Definition registered"
echo ""

# Step 5: Create ECS Services
echo "[5/5] Creating ECS Services..."
echo ""
echo "⚠️  Note: Before creating services, ensure you have:"
echo "   - VPC with public subnets"
echo "   - Security group allowing port 8080"
echo "   - Execute this command to create services:"
echo ""

# Get VPC info
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --region $AWS_REGION \
  --output text)

SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[0].SubnetId' \
  --region $AWS_REGION \
  --output text)

SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' \
  --region $AWS_REGION \
  --output text)

echo "Found resources:"
echo "  VPC: $VPC_ID"
echo "  Subnet: $SUBNET_ID"
echo "  Security Group: $SG_ID"
echo ""

# Create services
echo "Creating ECS Service (Staging)..."
aws ecs create-service \
  --cluster $ECS_CLUSTER_STAGING \
  --service-name $ECS_SERVICE_STAGING \
  --task-definition $TASK_FAMILY \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --region $AWS_REGION 2>/dev/null || echo "Service already exists (staging)"

echo "Creating ECS Service (Production)..."
aws ecs create-service \
  --cluster $ECS_CLUSTER_PROD \
  --service-name $ECS_SERVICE_PROD \
  --task-definition $TASK_FAMILY \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --region $AWS_REGION 2>/dev/null || echo "Service already exists (prod)"

echo "✓ ECS Services created"
echo ""

# Step 6: Print Setup Instructions
echo "=========================================="
echo "✓ AWS Setup Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo ""
echo "1. Push initial Docker image:"
echo "   aws ecr get-login-password --region $AWS_REGION | \\"
echo "   docker login --username AWS --password-stdin $ECR_URL"
echo "   docker build -t $TASK_FAMILY ."
echo "   docker tag $TASK_FAMILY:latest $ECR_URL:latest"
echo "   docker push $ECR_URL:latest"
echo ""
echo "2. Configure Jenkins credentials:"
echo "   - Go to Jenkins > Manage Credentials"
echo "   - Add Secret text: 'aws-account-id' = '$AWS_ACCOUNT_ID'"
echo "   - Add AWS Credentials (if needed): access key & secret key"
echo ""
echo "3. Create Jenkins job:"
echo "   - New Pipeline job"
echo "   - Point to: https://github.com/ahmedabdelrahman-del/jenkines_demo"
echo "   - Jenkinsfile path: Jenkinsfile"
echo ""
echo "4. Verify deployment:"
echo "   aws ecs list-tasks --cluster $ECS_CLUSTER_STAGING --region $AWS_REGION"
echo "   aws ecs describe-tasks --cluster $ECS_CLUSTER_STAGING --tasks <task-arn> --region $AWS_REGION"
echo ""

# Save configuration to file
cat > aws-config.txt << EOF
AWS Setup Configuration
======================
Region: $AWS_REGION
Account ID: $AWS_ACCOUNT_ID
ECR Repository: $ECR_URL

Staging:
  Cluster: $ECS_CLUSTER_STAGING
  Service: $ECS_SERVICE_STAGING
  Log Group: /ecs/task-api-staging

Production:
  Cluster: $ECS_CLUSTER_PROD
  Service: $ECS_SERVICE_PROD
  Log Group: /ecs/task-api-prod

VPC Resources:
  VPC ID: $VPC_ID
  Subnet ID: $SUBNET_ID
  Security Group: $SG_ID

Task Definition: $TASK_FAMILY
EOF

echo "Configuration saved to: aws-config.txt"
echo ""
echo "=========================================="
