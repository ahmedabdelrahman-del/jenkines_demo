#!/bin/bash

# Create IAM Roles for ECS Task Definitions
# Run this first before creating task definitions

set -e

echo "=========================================="
echo "Creating ECS IAM Roles"
echo "=========================================="
echo ""

# Create ECS Task Execution Role
echo "[1/2] Creating ecsTaskExecutionRole..."
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  }' 2>/dev/null && echo "✓ Role created" || echo "✓ Role already exists"

# Attach AWS managed policy for ECS Task Execution
echo "  Attaching AmazonECSTaskExecutionRolePolicy..."
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
  2>/dev/null && echo "  ✓ Policy attached" || echo "  ✓ Policy already attached"

echo ""

# Create ECS Task Role (for container to access AWS services)
echo "[2/2] Creating ecsTaskRole..."
aws iam create-role \
  --role-name ecsTaskRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  }' 2>/dev/null && echo "✓ Role created" || echo "✓ Role already exists"

echo ""
echo "=========================================="
echo "✓ IAM Roles Setup Complete!"
echo "=========================================="
echo ""
echo "Roles created:"
echo "  - ecsTaskExecutionRole (for ECS to pull images & write logs)"
echo "  - ecsTaskRole (for container to access AWS services)"
echo ""
echo "You can now proceed with creating task definitions."
echo ""
