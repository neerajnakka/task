# ============================================================================
# CONSOLIDATED OUTPUTS
# ============================================================================
# This file consolidates all important output values from other files
# These values are displayed after terraform apply

# ============================================================================
# APPLICATION ACCESS
# ============================================================================

output "application_url" {
  description = "URL to access the Strapi application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "admin_panel_url" {
  description = "URL to access the Strapi admin panel"
  value       = "http://${aws_lb.main.dns_name}/admin"
}

# ============================================================================
# LOAD BALANCER
# ============================================================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

# ============================================================================
# TARGET GROUPS
# ============================================================================

output "blue_target_group_arn" {
  description = "ARN of Blue target group"
  value       = aws_lb_target_group.blue.arn
}

output "blue_target_group_name" {
  description = "Name of Blue target group"
  value       = aws_lb_target_group.blue.name
}

output "green_target_group_arn" {
  description = "ARN of Green target group"
  value       = aws_lb_target_group.green.arn
}

output "green_target_group_name" {
  description = "Name of Green target group"
  value       = aws_lb_target_group.green.name
}

# ============================================================================
# ECS CLUSTER & SERVICE
# ============================================================================

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.strapi.name
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.main.name}/${aws_ecs_service.strapi.name}"
}

output "ecs_task_definition_family" {
  description = "Family name of the ECS task definition"
  value       = aws_ecs_task_definition.strapi.family
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.strapi.arn
}

# ============================================================================
# DATABASE
# ============================================================================

output "rds_endpoint" {
  description = "RDS database endpoint (hostname)"
  value       = aws_db_instance.default.address
}

output "rds_port" {
  description = "RDS database port"
  value       = aws_db_instance.default.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.default.db_name
}

output "rds_username" {
  description = "RDS database username"
  value       = aws_db_instance.default.username
}

# ============================================================================
# ECR REPOSITORY
# ============================================================================

output "ecr_repository_url" {
  description = "ECR repository URL for pushing Docker images"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.app_repo.name
}

# ============================================================================
# CODEDEPLOY
# ============================================================================

output "codedeploy_app_name" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.strapi.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.strapi.deployment_group_name
}

output "codedeploy_deployment_strategy" {
  description = "CodeDeploy deployment strategy (Canary, Linear, or AllAtOnce)"
  value       = aws_codedeploy_deployment_group.strapi.deployment_config_name
}

# ============================================================================
# IAM ROLES
# ============================================================================

output "ecs_execution_role_arn" {
  description = "ARN of ECS task execution role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "codedeploy_role_arn" {
  description = "ARN of CodeDeploy service role"
  value       = aws_iam_role.codedeploy_role.arn
}

# ============================================================================
# MONITORING
# ============================================================================

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for ECS logs"
  value       = aws_cloudwatch_log_group.strapi_logs.name
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.strapi_dashboard.dashboard_name}"
}

# ============================================================================
# DEPLOYMENT INSTRUCTIONS
# ============================================================================

output "deployment_instructions" {
  description = "Instructions for deploying with CodeDeploy"
  value       = <<-EOT
    
    ========================================
    BLUE/GREEN DEPLOYMENT SETUP COMPLETE
    ========================================
    
    Application URL: http://${aws_lb.main.dns_name}
    Admin Panel: http://${aws_lb.main.dns_name}/admin
    
    CodeDeploy Configuration:
    - Application: ${aws_codedeploy_app.strapi.name}
    - Deployment Group: ${aws_codedeploy_deployment_group.strapi.deployment_group_name}
    - Strategy: ${aws_codedeploy_deployment_group.strapi.deployment_config_name}
    
    To Deploy a New Version:
    1. Push new Docker image to ECR: ${aws_ecr_repository.app_repo.repository_url}:latest
    2. Create a new ECS task definition revision
    3. Create a CodeDeploy deployment:
       aws deploy create-deployment \
         --application-name ${aws_codedeploy_app.strapi.name} \
         --deployment-group-name ${aws_codedeploy_deployment_group.strapi.deployment_group_name} \
         --revision '{"revisionType":"AppSpecContent","appSpecContent":{"content":"{...}"}}'
    
    Monitoring:
    - CloudWatch Dashboard: ${aws_cloudwatch_dashboard.strapi_dashboard.dashboard_name}
    - Log Group: ${aws_cloudwatch_log_group.strapi_logs.name}
    - CPU Alarm: ${aws_cloudwatch_metric_alarm.cpu_high.alarm_name}
    - Memory Alarm: ${aws_cloudwatch_metric_alarm.memory_high.alarm_name}
    
    ========================================
  EOT
}
