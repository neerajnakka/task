# ============================================================================
# CODEDEPLOY APPLICATION
# ============================================================================
# A CodeDeploy application is a container for deployment configurations
# It defines WHAT we're deploying (ECS service)

resource "aws_codedeploy_app" "strapi" {
  name             = "${var.project_name}-app"
  compute_platform = "ECS"  # We're deploying to ECS (not EC2 or on-premises)
  
  tags = {
    Name = "${var.project_name}-codedeploy-app"
  }
}

# ============================================================================
# CODEDEPLOY DEPLOYMENT GROUP
# ============================================================================
# A deployment group defines HOW we're deploying
# It specifies:
# - Deployment strategy (Canary, Linear, AllAtOnce)
# - Automatic rollback settings
# - Blue/Green configuration
# - Traffic shifting

resource "aws_codedeploy_deployment_group" "strapi" {
  app_name               = aws_codedeploy_app.strapi.name
  deployment_group_name  = "${var.project_name}-deployment-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = var.deployment_strategy
  
  # ========================================================================
  # AUTOMATIC ROLLBACK CONFIGURATION
  # ========================================================================
  
  auto_rollback_configuration {
    enabled = var.enable_auto_rollback
    events  = [
      "DEPLOYMENT_FAILURE",
      "DEPLOYMENT_STOP_ON_TIMEOUT"
    ]
  }
  
  # ========================================================================
  # DEPLOYMENT STYLE FOR ECS BLUE/GREEN
  # ========================================================================
  
  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }
  
  tags = {
    Name = "${var.project_name}-deployment-group"
  }
}


