# ============================================================================
# BASIC CONFIGURATION VARIABLES
# ============================================================================

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "strapi"
}

# ============================================================================
# DATABASE VARIABLES
# ============================================================================

variable "db_password" {
  description = "Password for RDS PostgreSQL database"
  type        = string
  sensitive   = true
  default     = "StrapiSecurePass2025!"
  # Note: In production, use AWS Secrets Manager instead
  # TODO: Change this to a strong password for production
}

# ============================================================================
# BLUE/GREEN DEPLOYMENT VARIABLES (NEW FOR TASK 10)
# ============================================================================

variable "deployment_strategy" {
  description = "CodeDeploy deployment strategy for Blue/Green"
  type        = string
  default     = "CodeDeployDefault.ECSCanary10Percent5Minutes"
  
  # Explanation of options:
  # - CodeDeployDefault.ECSCanary10Percent5Minutes
  #   Sends 10% traffic to Green for 5 minutes, then 100% if healthy
  #   RECOMMENDED: Good balance of safety and speed
  #
  # - CodeDeployDefault.ECSLinear10Percent10Minutes
  #   Gradually increases traffic by 10% every 10 minutes
  #   SAFEST: Takes ~90 minutes but very safe for critical systems
  #
  # - CodeDeployDefault.ECSAllAtOnce
  #   Switches 100% traffic immediately
  #   FASTEST: But risky if new version has bugs
  
  validation {
    condition = contains([
      "CodeDeployDefault.ECSCanary10Percent5Minutes",
      "CodeDeployDefault.ECSLinear10Percent10Minutes",
      "CodeDeployDefault.ECSAllAtOnce"
    ], var.deployment_strategy)
    error_message = "deployment_strategy must be one of the three CodeDeploy strategies."
  }
}

variable "enable_auto_rollback" {
  description = "Enable automatic rollback on deployment failure"
  type        = bool
  default     = true
  
  # Explanation:
  # - true: If Green tasks fail health checks, automatically rollback to Blue
  # - false: Manual rollback required (not recommended)
}

variable "termination_wait_time_minutes" {
  description = "Minutes to wait before terminating Blue tasks after successful deployment"
  type        = number
  default     = 5
  
  # Explanation:
  # - This is the grace period before Blue is deleted
  # - If a delayed bug appears in Green, we have 5 minutes to rollback
  # - After 5 minutes, Blue is terminated to save costs
}

# ============================================================================
# ECS CONFIGURATION VARIABLES
# ============================================================================

variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 1024
}

variable "ecs_task_memory" {
  description = "Memory in MB for ECS task (512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192)"
  type        = number
  default     = 2048
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks to run"
  type        = number
  default     = 1
}

# ============================================================================
# STRAPI APPLICATION ENVIRONMENT VARIABLES
# ============================================================================

variable "app_keys" {
  description = "Strapi APP_KEYS (comma-separated)"
  type        = string
  sensitive   = true
  default     = "key1,key2"
  # TODO: Generate strong random keys for production
}

variable "api_token_salt" {
  description = "Strapi API_TOKEN_SALT"
  type        = string
  sensitive   = true
  default     = "somerandomsalt123"
  # TODO: Generate strong random salt for production
}

variable "admin_jwt_secret" {
  description = "Strapi ADMIN_JWT_SECRET"
  type        = string
  sensitive   = true
  default     = "supersecretadminjwt"
  # TODO: Generate strong random secret for production
}

variable "jwt_secret" {
  description = "Strapi JWT_SECRET"
  type        = string
  sensitive   = true
  default     = "supersecretjwt"
  # TODO: Generate strong random secret for production
}

variable "node_env" {
  description = "Node environment (development, production, staging)"
  type        = string
  default     = "production"
}

# ============================================================================
# NETWORKING VARIABLES
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_port" {
  description = "Port where Strapi container listens"
  type        = number
  default     = 1337
}

variable "alb_port" {
  description = "Port where ALB listens"
  type        = number
  default     = 80
}
