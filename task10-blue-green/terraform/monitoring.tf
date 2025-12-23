# ============================================================================
# CLOUDWATCH ALARMS - CPU UTILIZATION
# ============================================================================
# Alert if ECS tasks are using too much CPU

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 60
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when CPU utilization is above 80%"
  
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.strapi.name
  }
  
  tags = {
    Name = "${var.project_name}-cpu-alarm"
  }
}

# ============================================================================
# CLOUDWATCH ALARMS - MEMORY UTILIZATION
# ============================================================================
# Alert if ECS tasks are using too much memory

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.project_name}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 60
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when memory utilization is above 80%"
  
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.strapi.name
  }
  
  tags = {
    Name = "${var.project_name}-memory-alarm"
  }
}

# ============================================================================
# CLOUDWATCH DASHBOARD
# ============================================================================
# Visual dashboard showing service health

resource "aws_cloudwatch_dashboard" "strapi_dashboard" {
  dashboard_name = "${var.project_name}-health-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.strapi.name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Service CPU & Memory Utilization"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["ECS/ContainerInsights", "TaskCount", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.strapi.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Running Task Count"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["ECS/ContainerInsights", "NetworkRxBytes", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.strapi.name],
            [".", "NetworkTxBytes", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Network Traffic (Bytes)"
        }
      }
    ]
  })
}


