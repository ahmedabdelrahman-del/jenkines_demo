# AWS Setup Instructions for Task API Jenkins Pipeline

## Overview

This guide walks through setting up AWS infrastructure for your Jenkins pipeline to build, push, and deploy the Task API microservice.

## Prerequisites

- AWS Account
- AWS CLI installed and configured
- Access to your AWS account
- Docker installed (for manual image push)

## Quick Setup (Automated)

### 1. Run the Setup Script

```bash
chmod +x aws-setup.sh
./aws-setup.sh
```

This script automatically creates:
- ✅ ECR Repository
- ✅ CloudWatch Log Groups
- ✅ ECS Clusters (Staging & Production)
- ✅ Task Definitions
- ✅ ECS Services

### 2. Push Initial Docker Image

After the script completes, push your first image:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  6469-7752-661.dkr.ecr.us-east-1.amazonaws.com

# Build and tag image
docker build -t task-api .
docker tag task-api:latest \
  6469-7752-661.dkr.ecr.us-east-1.amazonaws.com/task-api:latest

# Push to ECR
docker push 6469-7752-661.dkr.ecr.us-east-1.amazonaws.com/task-api:latest
```

## Manual Setup (Step by Step)

### Step 1: Create ECR Repository

```bash
aws ecr create-repository \
  --repository-name task-api \
  --region us-east-1 \
  --description "Task API Docker images"
```

**Output:**
```json
{
  "repository": {
    "repositoryUri": "6469-7752-661.dkr.ecr.us-east-1.amazonaws.com/task-api"
  }
}
```

Save this URI - you'll need it later!

### Step 2: Create CloudWatch Log Groups

```bash
# Staging
aws logs create-log-group \
  --log-group-name /ecs/task-api-staging \
  --region us-east-1

# Production
aws logs create-log-group \
  --log-group-name /ecs/task-api-prod \
  --region us-east-1
```

### Step 3: Create ECS Clusters

```bash
# Staging
aws ecs create-cluster \
  --cluster-name task-api-cluster-staging \
  --region us-east-1 \
  --capacity-providers FARGATE

# Production
aws ecs create-cluster \
  --cluster-name task-api-cluster-prod \
  --region us-east-1 \
  --capacity-providers FARGATE
```

### Step 4: Register Task Definition

Create a file: `task-definition.json`

```json
{
  "family": "task-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "task-api",
      "image": "6469-7752-661.dkr.ecr.us-east-1.amazonaws.com/task-api:latest",
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
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "executionRoleArn": "arn:aws:iam::6469-7752-661:role/ecsTaskExecutionRole"
}
```

Register it:

```bash
aws ecs register-task-definition \
  --cli-input-json file://task-definition.json \
  --region us-east-1
```

### Step 5: Create ECS Service

Get your VPC and subnet info:

```bash
# Get default VPC
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --output text)

# Get first subnet
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[0].SubnetId' \
  --output text)

# Get default security group
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)
```

Create service:

```bash
aws ecs create-service \
  --cluster task-api-cluster-staging \
  --service-name task-api-service-staging \
  --task-definition task-api \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --region us-east-1
```

## Jenkins Configuration

### 1. Create IAM User for Jenkins

```bash
# Create user
aws iam create-user --user-name jenkins-ci

# Create access key
aws iam create-access-key --user-name jenkins-ci

# Attach policy
aws iam put-user-policy \
  --user-name jenkins-ci \
  --policy-name jenkins-ecs-policy \
  --policy-document file://jenkins-iam-policy.json
```

Save the Access Key ID and Secret Access Key!

### 2. Configure Jenkins Credentials

1. Go to **Jenkins Dashboard**
2. Click **Manage Jenkins** → **Manage Credentials**
3. Click **Global** under **Stores scoped to Jenkins**
4. Click **Add Credentials**
5. Add two credentials:

**Credential 1: AWS Account ID**
- Kind: **Secret text**
- Secret: `6469-7752-661`
- ID: `aws-account-id`
- Description: AWS Account ID

**Credential 2: AWS Access Keys**
- Kind: **AWS Credentials**
- Access Key ID: (from `aws iam create-access-key`)
- Secret Access Key: (from `aws iam create-access-key`)
- ID: `aws-credentials`
- Description: Jenkins CI AWS Credentials

### 3. Create Jenkins Job

1. Click **New Item**
2. Enter name: `task-api`
3. Select **Pipeline**
4. Under **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/ahmedabdelrahman-del/jenkines_demo`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
5. Click **Save**

### 4. Run Pipeline

Click **Build Now** and monitor the pipeline:

```
✓ Checkout
✓ Lint
✓ Unit Tests
✓ Security Scan
✓ Build Application
✓ Build Docker Image
✓ Push to ECR
✓ Deploy to Staging
✓ Smoke Tests - Staging
⏳ Approve Production Deployment (manual)
✓ Deploy to Production
✓ Smoke Tests - Production
```

## Verify Deployment

### Check ECS Service

```bash
# List tasks
aws ecs list-tasks \
  --cluster task-api-cluster-staging \
  --region us-east-1

# Get task details
aws ecs describe-tasks \
  --cluster task-api-cluster-staging \
  --tasks <task-arn> \
  --region us-east-1
```

### Check CloudWatch Logs

```bash
# View logs
aws logs tail /ecs/task-api-staging --follow --region us-east-1
```

### Test the API

```bash
# Get the task public IP
aws ecs describe-tasks \
  --cluster task-api-cluster-staging \
  --tasks <task-arn> \
  --query 'tasks[0].attachments[0].details' \
  --region us-east-1

# Test health check
curl http://<public-ip>:8080/health

# Create a task
curl -X POST http://<public-ip>:8080/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","description":"Testing","completed":false}'
```

## Cost Estimation

- **ECR**: ~$0.10/GB/month
- **ECS Fargate**: ~$0.04/hour per task
- **CloudWatch Logs**: ~$0.50/GB/month
- **Total**: ~$50-100/month for small setup

## Troubleshooting

### Pipeline fails at "Push to ECR"
- Ensure ECR repository exists: `aws ecr describe-repositories --repository-names task-api`
- Check Jenkins AWS credentials are configured

### ECS Service won't start
- Check task definition is registered: `aws ecs describe-task-definition --task-definition task-api`
- Verify CloudWatch log groups exist
- Check IAM execution role permissions

### Can't connect to container
- Verify security group allows port 8080
- Check task is running: `aws ecs list-tasks --cluster task-api-cluster-staging`
- Check logs: `aws logs tail /ecs/task-api-staging --follow`

## Next Steps

1. ✅ Set up AWS infrastructure (this guide)
2. ✅ Configure Jenkins
3. ✅ Run first pipeline
4. Monitor deployments
5. Set up monitoring/alerts
6. Configure auto-scaling
7. Add HTTPS/Load Balancer

## References

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Jenkins AWS Plugin](https://plugins.jenkins.io/aws-steps/)
- [Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
