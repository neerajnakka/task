# Understanding the Task 10 Code - Deep Dive

This document explains HOW each file works and WHY it's structured that way.

---

## 🔄 Code Flow: From Request to Response

Let's trace what happens when a user makes a request:

### **1. User Makes Request**
```
User: GET http://strapi-alb-123.ap-south-1.elb.amazonaws.com/admin
```

### **2. ALB Receives Request**
```hcl
# alb.tf - ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = 100  # 100% to Blue
      }
      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = 0    # 0% to Green
      }
    }
  }
}
```

**What happens:**
- ALB receives request on port 80
- Looks at weights: Blue=100, Green=0
- Calculates: 100/(100+0) = 100% to Blue
- Sends request to Blue target group

### **3. Blue Target Group Routes to ECS Tasks**
```hcl
# alb.tf - Blue Target Group
resource "aws_lb_target_group" "blue" {
  name        = "strapi-blue-tg"
  port        = 1337
  protocol    = "HTTP"
  target_type = "ip"  # Fargate uses IP addresses
  vpc_id      = aws_vpc.main.id
  
  health_check {
    path    = "/"
    matcher = "200-304"
  }
}
```

**What happens:**
- Target group knows which ECS tasks are healthy
- Sends request to a healthy task on port 1337
- Health checks ensure only healthy tasks receive traffic

### **4. ECS Task Receives Request**
```hcl
# ecs.tf - Task Definition
container_definitions = jsonencode([
  {
    name      = "strapi-app"
    image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
    portMappings = [
      {
        containerPort = 1337
        hostPort      = 1337
        protocol      = "tcp"
      }
    ]
    environment = [
      { name = "DATABASE_HOST", value = aws_db_instance.default.address },
      # ... more env vars ...
    ]
  }
])
```

**What happens:**
- Docker container starts with image from ECR
- Listens on port 1337
- Has environment variables for database connection
- Strapi application receives request

### **5. Strapi Connects to Database**
```hcl
# ecs.tf - Environment Variables
{
  name  = "DATABASE_HOST"
  value = aws_db_instance.default.address  # RDS endpoint
},
{
  name  = "DATABASE_PORT"
  value = "5432"
},
{
  name  = "DATABASE_NAME"
  value = aws_db_instance.default.db_name
}
```

**What happens:**
- Strapi reads environment variables
- Connects to RDS PostgreSQL
- Queries database
- Returns response

### **6. Response Flows Back**
```
Strapi → ECS Task → Blue Target Group → ALB → User
```

---

## 🔐 Security Flow

### **How Traffic is Secured**

```
Internet (0.0.0.0/0)
    ↓
ALB Security Group (allows port 80)
    ↓
ALB (in public subnet)
    ↓
ECS Security Group (allows port 1337 ONLY from ALB)
    ↓
ECS Tasks (in public subnet)
    ↓
RDS Security Group (allows port 5432 ONLY from ECS)
    ↓
RDS Database (in private subnet)
```

**Key Security Points:**

1. **ALB Security Group** (`networking.tf`)
```hcl
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Open to internet
}
```
- Allows HTTP from anywhere
- This is the entry point

2. **ECS Security Group** (`networking.tf`)
```hcl
ingress {
  from_port       = 1337
  to_port         = 1337
  protocol        = "tcp"
  security_groups = [aws_security_group.alb_sg.id]  # Only from ALB
}
```
- Allows port 1337 ONLY from ALB
- Blocks direct internet access
- More secure

3. **RDS Security Group** (`networking.tf`)
```hcl
ingress {
  from_port       = 5432
  to_port         = 5432
  protocol        = "tcp"
  security_groups = [aws_security_group.ecs_sg.id]  # Only from ECS
}
```
- Allows port 5432 ONLY from ECS
- Database completely isolated
- Most secure

---

## 🚀 Deployment Flow

### **How Blue/Green Deployment Works**

#### **Initial State**
```
ECS Service
├─ Blue Target Group (100% traffic)
│  └─ Task 1 (Strapi v1)
│  └─ Task 2 (Strapi v1)
│
└─ Green Target Group (0% traffic)
   └─ (empty)
```

#### **Step 1: CodeDeploy Starts**
```hcl
# codedeploy.tf - Deployment Group
deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"
```

**What happens:**
- CodeDeploy reads the deployment strategy
- Canary: 10% for 5 minutes, then 100%

#### **Step 2: Create Green Tasks**
```hcl
# ecs.tf - Service with two load balancers
load_balancer {
  target_group_arn = aws_lb_target_group.blue.arn
  container_name   = "strapi-app"
  container_port   = 1337
}

load_balancer {
  target_group_arn = aws_lb_target_group.green.arn
  container_name   = "strapi-app"
  container_port   = 1337
}
```

**What happens:**
- CodeDeploy creates new task definition revision
- Launches new tasks with new image
- Registers them with Green target group

```
ECS Service
├─ Blue Target Group (100% traffic)
│  └─ Task 1 (Strapi v1)
│  └─ Task 2 (Strapi v1)
│
└─ Green Target Group (0% traffic)
   └─ Task 3 (Strapi v2) - NEW
   └─ Task 4 (Strapi v2) - NEW
```

#### **Step 3: Health Checks**
```hcl
# alb.tf - Health Check
health_check {
  healthy_threshold   = 2
  unhealthy_threshold = 3
  timeout             = 10
  interval            = 30
  path                = "/"
  matcher             = "200-304"
}
```

**What happens:**
- ALB checks Green tasks every 30 seconds
- Needs 2 successful checks to mark as healthy
- If Green tasks fail, CodeDeploy detects it

#### **Step 4: Canary Phase (10% for 5 minutes)**
```hcl
# codedeploy.tf - Traffic Routing
traffic_routing_config {
  type = "TimeBasedLinear"
  time_based_linear {
    linear_percentage = 10
    linear_interval   = 10
  }
}
```

**What happens:**
- CodeDeploy updates ALB listener weights
- Blue: 90%, Green: 10%
- 10% of users see new version
- CodeDeploy monitors: "Is Green handling traffic OK?"

```
ALB Listener
├─ Blue Target Group (90% traffic)
│  └─ Task 1 (Strapi v1)
│  └─ Task 2 (Strapi v1)
│
└─ Green Target Group (10% traffic)
   └─ Task 3 (Strapi v2)
   └─ Task 4 (Strapi v2)
```

#### **Step 5: Full Switch (100% to Green)**
```hcl
# codedeploy.tf - Automatic switch
# After 5 minutes, if Green is healthy:
# Blue: 0%, Green: 100%
```

**What happens:**
- CodeDeploy updates weights again
- Blue: 0%, Green: 100%
- All traffic now goes to new version

```
ALB Listener
├─ Blue Target Group (0% traffic)
│  └─ Task 1 (Strapi v1)
│  └─ Task 2 (Strapi v1)
│
└─ Green Target Group (100% traffic)
   └─ Task 3 (Strapi v2)
   └─ Task 4 (Strapi v2)
```

#### **Step 6: Cleanup**
```hcl
# codedeploy.tf - Terminate Blue
terminate_blue_instances_on_deployment_success {
  action                           = "TERMINATE"
  termination_wait_time_in_minutes = 5
}
```

**What happens:**
- Wait 5 minutes (grace period)
- If no issues detected, terminate Blue tasks
- Delete old version

```
ECS Service
├─ Blue Target Group (0% traffic)
│  └─ (empty - deleted)
│
└─ Green Target Group (100% traffic)
   └─ Task 3 (Strapi v2) - NOW CURRENT
   └─ Task 4 (Strapi v2) - NOW CURRENT
```

---

## 🔄 Rollback Flow

### **What Happens If Green Fails**

#### **Scenario: Green Tasks Crash During Canary**
```
Time: 2 minutes into Canary phase
Blue: 90% traffic
Green: 10% traffic
Green tasks start crashing
```

#### **Step 1: Health Check Detects Failure**
```hcl
# alb.tf - Health Check
unhealthy_threshold = 3  # 3 failed checks = unhealthy
interval            = 30  # Check every 30 seconds
```

**What happens:**
- ALB checks Green tasks
- 3 consecutive failures
- Marks Green as unhealthy

#### **Step 2: CodeDeploy Detects Failure**
```hcl
# codedeploy.tf - Auto Rollback
auto_rollback_configuration {
  enabled = true
  events  = ["DEPLOYMENT_FAILURE"]
}
```

**What happens:**
- CodeDeploy monitors Green health
- Detects unhealthy tasks
- Triggers automatic rollback

#### **Step 3: Automatic Rollback**
```hcl
# codedeploy.tf - Rollback Action
# CodeDeploy updates ALB weights:
# Blue: 100%, Green: 0%
```

**What happens:**
- CodeDeploy updates ALB listener
- Blue: 100%, Green: 0%
- All traffic back to old version
- Users don't see the error

```
ALB Listener
├─ Blue Target Group (100% traffic) - RESTORED
│  └─ Task 1 (Strapi v1)
│  └─ Task 2 (Strapi v1)
│
└─ Green Target Group (0% traffic)
   └─ Task 3 (Strapi v2) - FAILED
   └─ Task 4 (Strapi v2) - FAILED
```

#### **Step 4: Cleanup Failed Deployment**
```hcl
# codedeploy.tf - Terminate Green on failure
# Green tasks are terminated
# Blue tasks continue running
```

**What happens:**
- Green tasks are deleted
- Blue remains as current version
- Deployment marked as failed
- Team investigates the issue

---

## 📊 IAM Permission Flow

### **How Permissions Work**

#### **1. ECS Task Execution Role**
```hcl
# iam.tf - Execution Role
assume_role_policy = {
  Principal = { Service = "ecs-tasks.amazonaws.com" }
}
```

**What happens:**
- ECS service assumes this role
- Uses it to pull Docker images
- Uses it to write logs

**Flow:**
```
ECS Service
  ↓
Assumes ECS Execution Role
  ↓
Gets permissions to:
  - Pull from ECR
  - Write to CloudWatch
  - Pull from Secrets Manager
  ↓
Starts Docker container
```

#### **2. ECS Task Role**
```hcl
# iam.tf - Task Role
assume_role_policy = {
  Principal = { Service = "ecs-tasks.amazonaws.com" }
}
```

**What happens:**
- Container assumes this role
- Uses it to access AWS services

**Flow:**
```
Docker Container (Strapi)
  ↓
Assumes ECS Task Role
  ↓
Gets permissions to:
  - Read/Write S3
  - Read Secrets Manager
  - Send CloudWatch metrics
  ↓
Application can access AWS services
```

#### **3. CodeDeploy Service Role**
```hcl
# iam.tf - CodeDeploy Role
assume_role_policy = {
  Principal = { Service = "codedeploy.amazonaws.com" }
}
```

**What happens:**
- CodeDeploy service assumes this role
- Uses it to manage ECS

**Flow:**
```
CodeDeploy Service
  ↓
Assumes CodeDeploy Role
  ↓
Gets permissions to:
  - Update ECS Service
  - Describe ECS Tasks
  - Manage Task Definitions
  - Pass roles to ECS
  ↓
Can orchestrate Blue/Green deployment
```

---

## 🎯 Key Terraform Concepts Used

### **1. Resource References**
```hcl
# Using output from one resource in another
load_balancer {
  target_group_arn = aws_lb_target_group.blue.arn  # Reference
}
```

### **2. Count for Multiple Resources**
```hcl
resource "aws_subnet" "public" {
  count = 2  # Create 2 subnets
  cidr_block = "10.0.${count.index}.0/24"  # 10.0.0.0/24 and 10.0.1.0/24
}
```

### **3. Splat Syntax**
```hcl
subnets = aws_subnet.public[*].id  # Get all subnet IDs
```

### **4. Data Sources**
```hcl
data "aws_availability_zones" "available" {
  state = "available"  # Get available AZs
}
```

### **5. JSON Encoding**
```hcl
container_definitions = jsonencode([...])  # Convert to JSON
policy = jsonencode({...})  # Convert to JSON
```

### **6. Outputs**
```hcl
output "alb_dns_name" {
  value = aws_lb.main.dns_name  # Export value
}
```

---

## 🔍 Debugging Tips

### **If Deployment Fails**

1. **Check CodeDeploy Logs**
```bash
aws deploy get-deployment --deployment-id <ID>
```

2. **Check ECS Task Logs**
```bash
aws logs tail /ecs/strapi-app --follow
```

3. **Check ALB Target Health**
```bash
aws elbv2 describe-target-health --target-group-arn <ARN>
```

4. **Check Security Groups**
```bash
aws ec2 describe-security-groups --group-ids <ID>
```

5. **Check IAM Permissions**
```bash
aws iam get-role-policy --role-name <ROLE> --policy-name <POLICY>
```

---

## ✅ Verification Checklist

After deployment, verify:

- [ ] ALB is accessible
- [ ] Blue target group has healthy tasks
- [ ] Green target group is empty (initially)
- [ ] CloudWatch logs are being written
- [ ] Alarms are configured
- [ ] CodeDeploy application exists
- [ ] CodeDeploy deployment group exists
- [ ] IAM roles have correct permissions
- [ ] Security groups allow correct traffic
- [ ] RDS database is accessible from ECS

