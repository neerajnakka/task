# --- Load Balancer ---
resource "aws_lb" "main" {
  name               = "strapi-ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "strapi-ecs-alb"
  }
}

# --- Target Group ---
resource "aws_lb_target_group" "app_tg" {
  name        = "strapi-target-group"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Required for Fargate

  health_check {
    enabled = true
    path    = "/" # Strapi root usually redirects or shows text
    # path    = "/_health" # Ideally use a health endpoint
    port    = "traffic-port" # 1337
    matcher = "200-304" # 200 OK
    interval = 30
    timeout = 10 
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

# --- Listener ---
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}
