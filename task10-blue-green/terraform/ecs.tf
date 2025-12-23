# ============================================================================
# ECS CLUSTER
# ============================================================================
# A cluster is a logical grouping of ECS resources
# All our tasks will run in this cluster

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"
  
  # Enable Container Insights for monitoring
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Name = "${var.project_name}-ecs-cluster"
  }
}

# ============================================================================
# ECS CLUSTER CAPACITY PROVIDERS
# ============================================================================
# Capacity providers define how tasks are launched
# We use Fargate (serverless)

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name
  
  capacity_providers = ["FARGATE"]
  
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ============================================================================
# ECS TASK DEFINITION
# ============================================================================
# A task definition is a blueprint for running Docker containers
# It specifies: image, CPU, memory, environment variables, logging, etc.

resource "aws_ecs_task_definition" "strapi" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"  # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu  # 1024
  memory                   = var.ecs_task_memory  # 2048
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  # Container Definition
  container_definitions = jsonencode([
    {
      name      = "strapi-app"
      image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
      essential = true
      
      # Port Mapping
      portMappings = [
        {
          containerPort = var.container_port  # 1337
          hostPort      = var.container_port  # 1337
          protocol      = "tcp"
        }
      ]
      
      # Environment Variables
      environment = [
        {
          name  = "DATABASE_CLIENT"
          value = "postgres"
        },
        {
          name  = "DATABASE_HOST"
          value = aws_db_instance.default.address
        },
        {
          name  = "DATABASE_PORT"
          value = "5432"
        },
        {
          name  = "DATABASE_NAME"
          value = aws_db_instance.default.db_name
        },
        {
          name  = "DATABASE_USERNAME"
          value = aws_db_instance.default.username
        },
        {
          name  = "DATABASE_PASSWORD"
          value = var.db_password
        },
        {
          name  = "NODE_ENV"
          value = var.node_env
        },
        {
          name  = "APP_KEYS"
          value = var.app_keys
        },
        {
          name  = "API_TOKEN_SALT"
          value = var.api_token_salt
        },
        {
          name  = "ADMIN_JWT_SECRET"
          value = var.admin_jwt_secret
        },
        {
          name  = "JWT_SECRET"
          value = var.jwt_secret
        }
      ]
      
      # Logging Configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.strapi_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  
  tags = {
    Name = "${var.project_name}-task-definition"
  }
}

# ============================================================================
# CLOUDWATCH LOG GROUP
# ============================================================================
# Centralized logging for all ECS tasks

resource "aws_cloudwatch_log_group" "strapi_logs" {
  name              = "/ecs/${var.project_name}-app"
  retention_in_days = 7
  
  tags = {
    Name = "${var.project_name}-log-group"
  }
}

# ============================================================================
# ECS SERVICE
# ============================================================================
# A service manages running and maintaining tasks
# For Blue/Green, the service can run tasks from different task definitions

resource "aws_ecs_service" "strapi" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = var.ecs_desired_count  # 1
  launch_type     = "FARGATE"
  
  # ========================================================================
  # CRITICAL FOR BLUE/GREEN: Deployment Controller
  # ========================================================================
  # This tells ECS that CodeDeploy will manage deployments
  # Without this, ECS would manage deployments directly
  # With this, CodeDeploy controls traffic shifting between Blue and Green
  
  deployment_controller {
    type = "CODE_DEPLOY"  # Changed from default "ECS"
  }
  
  # ========================================================================
  # LOAD BALANCER CONFIGURATION - BLUE TARGET GROUP
  # ========================================================================
  # Register tasks with Blue target group
  
  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "strapi-app"
    container_port   = var.container_port  # 1337
  }
  
  # ========================================================================
  # LOAD BALANCER CONFIGURATION - GREEN TARGET GROUP
  # ========================================================================
  # Register tasks with Green target group
  # Initially no tasks here, but CodeDeploy will add them during deployment
  
  load_balancer {
    target_group_arn = aws_lb_target_group.green.arn
    container_name   = "strapi-app"
    container_port   = var.container_port  # 1337
  }
  
  # ========================================================================
  # NETWORK CONFIGURATION
  # ========================================================================
  
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
  
  # Ensure service is created before load balancer
  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_execution_policy
  ]
  
  tags = {
    Name = "${var.project_name}-service"
  }
}


