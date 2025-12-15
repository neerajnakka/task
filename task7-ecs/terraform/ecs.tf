# --- ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name = "strapi-ecs-cluster"
  
  tags = {
    Name = "strapi-ecs-cluster"
  }
}

# --- KMS Key for CloudWatch Logs Encryption (Optional but good practice) ---
# skipping for simplicity, using default AWS key for logs if needed or just standard log group

# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "strapi_logs" {
  name              = "/ecs/strapi-app"
  retention_in_days = 7
}

# --- IAM Roles ---

# 1. Execution Role (Agent: Pull images, push logs)
resource "aws_iam_role" "ecs_execution_role" {
  name = "strapi-ecs-execution-role"

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
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. Task Role (App: Talk to other AWS services like S3 or SES if needed)
resource "aws_iam_role" "ecs_task_role" {
  name = "strapi-ecs-task-role"

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
}

# --- Task Definition ---
resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task"
  network_mode             = "awsvpc" # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024" # 1 vCPU
  memory                   = "2048" # 2 GB
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "strapi-app"
      image     = "${aws_ecr_repository.app_repo.repository_url}:latest" # Initial image
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.strapi_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "DATABASE_CLIENT", value = "postgres" },
        { name = "DATABASE_HOST", value = aws_db_instance.default.address },
        { name = "DATABASE_PORT", value = tostring(aws_db_instance.default.port) },
        { name = "DATABASE_NAME", value = var.db_name },
        { name = "DATABASE_USERNAME", value = var.db_username },
        { name = "DATABASE_PASSWORD", value = var.db_password },
        { name = "NODE_ENV", value = "production" },
        { name = "APP_KEYS", value = var.app_keys },
        { name = "API_TOKEN_SALT", value = var.api_token_salt },
        { name = "ADMIN_JWT_SECRET", value = var.admin_jwt_secret },
        { name = "JWT_SECRET", value = var.jwt_secret },
        { name = "DATABASE_SSL", value = "true" }, 
        { name = "DATABASE_SSL_REJECT_UNAUTHORIZED", value = "false" }, # Fix: Correct usage per config/database.ts
      ]
    }
  ])
}

# --- ECS Service ---
resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id # Using Public Subnets to save NAT Cost
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true # Required since we are in public subnet pulling form ECR
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "strapi-app"
    container_port   = 1337
  }

  # Allow 3 minutes for Strapi to start before ALB checks kill it
  health_check_grace_period_seconds = 180

  depends_on = [aws_lb_listener.http]
}
