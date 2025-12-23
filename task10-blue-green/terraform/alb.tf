# ============================================================================
# APPLICATION LOAD BALANCER (ALB)
# ============================================================================
# The ALB receives traffic from users and routes it to ECS tasks
# For Blue/Green, it can route to either Blue or Green target groups

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false  # Accessible from internet
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id  # Use both public subnets
  
  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ============================================================================
# TARGET GROUP - BLUE
# ============================================================================
# This target group represents the CURRENT/OLD version
# Initially receives 100% of traffic

resource "aws_lb_target_group" "blue" {
  name        = "${var.project_name}-blue-tg"
  port        = var.container_port  # 1337
  protocol    = "HTTP"
  target_type = "ip"  # Important: "ip" for Fargate (not "instance")
  vpc_id      = aws_vpc.main.id
  
  # Health Check Configuration
  # ALB checks if tasks are healthy before sending traffic
  health_check {
    healthy_threshold   = 2      # Need 2 successful checks to mark as healthy
    unhealthy_threshold = 3      # Need 3 failed checks to mark as unhealthy
    timeout             = 10     # Wait 10 seconds for response
    interval            = 30     # Check every 30 seconds
    path                = "/"    # Check the root path
    matcher             = "200-304"  # Accept 2xx and 3xx responses
  }
  
  tags = {
    Name = "${var.project_name}-blue-tg"
  }
}

# ============================================================================
# TARGET GROUP - GREEN
# ============================================================================
# This target group represents the NEW version
# Initially receives 0% of traffic
# During deployment, traffic gradually shifts from Blue to Green

resource "aws_lb_target_group" "green" {
  name        = "${var.project_name}-green-tg"
  port        = var.container_port  # 1337
  protocol    = "HTTP"
  target_type = "ip"  # Important: "ip" for Fargate (not "instance")
  vpc_id      = aws_vpc.main.id
  
  # Health Check Configuration (same as Blue)
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    path                = "/"
    matcher             = "200-304"
  }
  
  tags = {
    Name = "${var.project_name}-green-tg"
  }
}

# ============================================================================
# ALB LISTENER - HTTP (Port 80)
# ============================================================================
# The listener receives traffic on port 80 and routes it to target groups
# This is where WEIGHTED ROUTING happens

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.alb_port  # 80
  protocol          = "HTTP"
  
  # Default action: Forward traffic to Blue and Green with weights
  default_action {
    type = "forward"
    
    # WEIGHTED ROUTING CONFIGURATION
    # This is the key to Blue/Green deployment
    forward {
      # BLUE TARGET GROUP - Initially 100%
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = 100  # 100% of traffic goes to Blue initially
      }
      
      # GREEN TARGET GROUP - Initially 0%
      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = 0    # 0% of traffic goes to Green initially
      }
      
      # Stickiness (optional)
      # stickiness {
      #   enabled  = true
      #   duration = 86400  # 1 day
      # }
    }
  }
}


