# ============================================================================
# IAM ROLE 1: ECS TASK EXECUTION ROLE
# ============================================================================
# This role allows ECS to:
# - Pull Docker images from ECR
# - Write logs to CloudWatch
# - Pull secrets from Secrets Manager (if used)

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.project_name}-ecs-execution-role"
  }
}

# ============================================================================
# ATTACH AWS MANAGED POLICY TO EXECUTION ROLE
# ============================================================================
# AWS provides a pre-built policy for ECS task execution

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ============================================================================
# IAM ROLE 2: ECS TASK ROLE
# ============================================================================
# This role allows containers to access AWS services
# For Strapi, we might need:
# - S3 (for file uploads)
# - Secrets Manager (for sensitive data)
# - CloudWatch (for custom metrics)

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# ============================================================================
# CUSTOM POLICY FOR ECS TASK ROLE
# ============================================================================
# Allows containers to access S3 and Secrets Manager

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.project_name}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::*"  # TODO: Restrict to specific bucket in production
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:*"  # TODO: Restrict to specific secrets
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# IAM ROLE 3: CODEDEPLOY SERVICE ROLE
# ============================================================================
# This role allows CodeDeploy to:
# - Update ECS services
# - Describe ECS tasks and services
# - Manage task definitions
# - Assume other roles (for Blue/Green)

resource "aws_iam_role" "codedeploy_role" {
  name = "${var.project_name}-codedeploy-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.project_name}-codedeploy-role"
  }
}

# ============================================================================
# ATTACH AWS MANAGED POLICY TO CODEDEPLOY ROLE
# ============================================================================
# AWS provides a pre-built policy for CodeDeploy with ECS

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# ============================================================================
# CUSTOM POLICY FOR CODEDEPLOY ROLE
# ============================================================================
# Additional permissions for Blue/Green deployment

resource "aws_iam_role_policy" "codedeploy_custom_policy" {
  name = "${var.project_name}-codedeploy-custom-policy"
  role = aws_iam_role.codedeploy_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_execution_role.arn,
          aws_iam_role.ecs_task_role.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks"
        ]
        Resource = "*"
      }
    ]
  })
}


