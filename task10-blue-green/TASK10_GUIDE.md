# Task 10: Blue/Green Deployment - Complete Guide

## 📚 Overview

This guide explains the Blue/Green deployment infrastructure for Strapi on AWS ECS Fargate with CodeDeploy orchestration.

---

## 🏗️ Architecture Overview

```
User Request (Port 80)
    ↓
ALB (Application Load Balancer)
    ↓
    ├─ Blue Target Group (100% initially)
    │   └─ ECS Tasks (Current Version)
    │
    └─ Green Target Group (0% initially)
        └─ ECS Tasks (New Version - during deployment)

CodeDeploy orchestrates traffic shifting:
    Blue: 100% → 90% → 50% → 0%
    Green: 0% → 10% → 50% → 100%
```

---

## 📁 File Structure

### **11 Terraform Files**

| File | Purpose | Status |
|------|---------|--------|
| `provider.tf` | AWS provider configuration | Same as Task 7 |
| `variables.tf` | Input variables (with Blue/Green options) | Enhanced |
| `networking.tf` | VPC, Subnets, Security Groups | Same as Task 7 |
| `rds.tf` | RDS PostgreSQL database | Same as Task 7 |
| `ecr.tf` | ECR Docker image repository | Same as Task 7 |
| `alb.tf` | ALB with Blue & Green target groups | **MODIFIED** |
| `ecs.tf` | ECS Cluster, Service, Task Definition | **MODIFIED** |
| `iam.tf` | IAM roles for ECS & CodeDeploy | **NEW** |
| `codedeploy.tf` | CodeDeploy application & deployment group | **NEW** |
| `monitoring.tf` | CloudWatch alarms & dashboard | Same as Task 7 |
| `outputs.tf` | Consolidated output values | **NEW** |

---

## 🔑 Key Concepts

### **1. Target Groups (Blue & Green)**

**Blue Target Group:**
- Represents the CURRENT/OLD version
- Initially receives 100% of traffic
- Contains running ECS tasks

**Green Target Group:**
- Represents the NEW version
- Initially receives 0% of traffic
- Created during deployment with new tasks

### **2. Weighted Routing**

ALB distributes traffic based on weights:
```
Blue weight = 100, Green weight = 0
→ 100% traffic to Blue

Blue weight = 90, Green weight = 10
→ 90% traffic to Blue, 10% to Green

Blue weight = 0, Green weight = 100
→ 100% traffic to Green
```

### **3. Deployment Controller**

```hcl
deployment_controller {
  type = "CODE_DEPLOY"
}
```

This tells ECS that CodeDeploy will manage deployments, not ECS itself.

### **4. CodeDeploy Orchestration**

CodeDeploy manages the entire deployment:
1. Creates new Green tasks
2. Performs health checks
3. Gradually shifts traffic (Canary: 10% for 5 min, then 100%)
4. Monitors Green health
5. If healthy: Terminates Blue tasks
6. If unhealthy: Automatic rollback to Blue

### **5. Deployment Strategies**

**Canary (Recommended):**
- 10% traffic for 5 minutes
- Then 100% if healthy
- Fast and safe

**Linear:**
- 10% every 10 minutes
- Takes ~90 minutes total
- Very safe for critical systems

**AllAtOnce:**
- 100% immediately
- Fastest but riskiest
- For non-critical systems

---

## 🚀 Deployment Flow

### **Initial State**
```
Blue: 100% traffic (running)
Green: 0% traffic (doesn't exist)
```

### **Step 1: Deployment Starts**
```
CodeDeploy creates new Green tasks with new image
Blue: 100% traffic (running)
Green: 0% traffic (starting up)
```

### **Step 2: Health Checks**
```
Green tasks pass health checks
Blue: 100% traffic (running)
Green: 0% traffic (healthy, ready)
```

### **Step 3: Canary Phase (5 minutes)**
```
CodeDeploy shifts 10% traffic to Green
Blue: 90% traffic
Green: 10% traffic
CodeDeploy monitors: "Is Green handling traffic OK?"
```

### **Step 4: Full Switch**
```
If Green is healthy, shift 100% traffic
Blue: 0% traffic
Green: 100% traffic
```

### **Step 5: Cleanup**
```
Wait 5 minutes (grace period)
If no issues, terminate Blue tasks
Blue: Deleted
Green: 100% traffic (now the current version)
```

### **Rollback (If Green Fails)**
```
At any point, if Green fails:
CodeDeploy automatically switches back
Blue: 100% traffic
Green: Deleted
```

---

## 🔐 IAM Roles

### **1. ECS Task Execution Role**
- Allows ECS to pull Docker images from ECR
- Allows ECS to write logs to CloudWatch
- Allows ECS to pull secrets from Secrets Manager

### **2. ECS Task Role**
- Allows containers to access S3 (for file uploads)
- Allows containers to access Secrets Manager
- Allows containers to send metrics to CloudWatch

### **3. CodeDeploy Service Role**
- Allows CodeDeploy to update ECS services
- Allows CodeDeploy to describe ECS tasks
- Allows CodeDeploy to manage task definitions
- Allows CodeDeploy to pass roles to ECS

---

## 📊 Configuration Variables

### **Deployment Strategy**
```hcl
variable "deployment_strategy" {
  default = "CodeDeployDefault.ECSCanary10Percent5Minutes"
  # Options:
  # - CodeDeployDefault.ECSCanary10Percent5Minutes
  # - CodeDeployDefault.ECSLinear10Percent10Minutes
  # - CodeDeployDefault.ECSAllAtOnce
}
```

### **Auto Rollback**
```hcl
variable "enable_auto_rollback" {
  default = true
  # If true: Automatic rollback on deployment failure
  # If false: Manual rollback required
}
```

### **Termination Grace Period**
```hcl
variable "termination_wait_time_minutes" {
  default = 5
  # Wait 5 minutes before deleting Blue tasks
  # Allows time to detect delayed bugs
}
```

---

## 🛠️ How to Deploy

### **Step 1: Initialize Terraform**
```bash
cd task10-blue-green/terraform
terraform init
```

### **Step 2: Create Variables File (Optional)**
```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your custom values if needed
# If you skip this, defaults from variables.tf will be used
```

### **Step 3: Plan the Deployment**
```bash
terraform plan
```

### **Step 4: Apply the Infrastructure**
```bash
terraform apply
```

**Output:**
- ALB DNS name (e.g., `strapi-alb-123.ap-south-1.elb.amazonaws.com`)
- CodeDeploy application name
- CodeDeploy deployment group name
- RDS endpoint
- ECR repository URL

### **Step 5: Access the Application**
```
http://<ALB_DNS_NAME>/admin
```

---

## 📝 Deployment Process (After Infrastructure is Ready)

### **To Deploy a New Version:**

1. **Build and Push Docker Image**
```bash
docker build -t <ECR_URL>:latest .
docker push <ECR_URL>:latest
```

2. **Create New Task Definition Revision**
```bash
aws ecs register-task-definition \
  --family strapi-task \
  --container-definitions file://task-definition.json
```

3. **Create CodeDeploy Deployment**
```bash
aws deploy create-deployment \
  --application-name strapi-app \
  --deployment-group-name strapi-deployment-group \
  --revision '{"revisionType":"AppSpecContent","appSpecContent":{"content":"{...}"}}'
```

4. **Monitor Deployment**
```bash
aws deploy get-deployment --deployment-id <DEPLOYMENT_ID>
```

---

## 🔍 Monitoring

### **CloudWatch Dashboard**
- CPU utilization
- Memory utilization
- Task count
- Network traffic

### **CloudWatch Alarms**
- CPU > 80% for 2 minutes
- Memory > 80% for 2 minutes

### **CloudWatch Logs**
- All container logs in `/ecs/strapi-app`
- Searchable and filterable

---

## 🎯 Key Differences from Task 7

| Aspect | Task 7 | Task 10 |
|--------|--------|---------|
| **Target Groups** | 1 | 2 (Blue & Green) |
| **Deployment Controller** | ECS | CODE_DEPLOY |
| **Load Balancer** | Simple forward | Weighted routing |
| **Deployment Strategy** | ECS rolling update | CodeDeploy Blue/Green |
| **Rollback** | Manual | Automatic |
| **Traffic Shifting** | Immediate | Gradual (Canary/Linear) |
| **IAM Roles** | 2 | 3 (added CodeDeploy) |
| **CodeDeploy** | Not used | Core orchestrator |

---

## ⚠️ Important Notes

1. **Secrets Management**: Currently using environment variables. For production, use AWS Secrets Manager.

2. **SSL/TLS**: Currently HTTP only. For production, add HTTPS with ACM certificate.

3. **Database**: Using RDS in private subnets (secure). Ensure proper backup strategy.

4. **Cost**: Blue/Green requires running two versions temporarily. Budget accordingly.

5. **Monitoring**: Set up SNS notifications for alarms in production.

---

## 🚨 Troubleshooting

### **Deployment Fails**
- Check CodeDeploy logs in AWS Console
- Verify task definition is valid
- Check ECS task logs in CloudWatch

### **Green Tasks Not Starting**
- Check security group rules
- Verify ECR image exists
- Check IAM role permissions

### **Traffic Not Shifting**
- Verify ALB listener rules
- Check target group health checks
- Verify security groups allow traffic

### **Rollback Not Working**
- Check CodeDeploy role permissions
- Verify Blue tasks still exist
- Check ALB listener configuration

---

## 📚 Next Steps

1. Deploy the infrastructure
2. Test the application
3. Create a new Docker image
4. Trigger a CodeDeploy deployment
5. Monitor the Blue/Green traffic shift
6. Verify automatic rollback (optional test)

---

## 🎓 Learning Outcomes

After completing Task 10, you'll understand:
- Blue/Green deployment strategy
- CodeDeploy orchestration
- Weighted traffic routing
- Automatic rollback mechanisms
- Canary deployments
- Zero-downtime deployments
- Production-grade deployment patterns

---

## 📞 Quick Reference

**Terraform Commands:**
```bash
terraform init          # Initialize
terraform plan          # Preview changes
terraform apply         # Deploy
terraform destroy       # Cleanup
terraform output        # Show outputs
```

**AWS CLI Commands:**
```bash
aws deploy create-deployment          # Start deployment
aws deploy get-deployment             # Check status
aws ecs describe-services             # Check service
aws ecs describe-tasks                # Check tasks
aws logs tail /ecs/strapi-app         # View logs
```

---

## ✅ Checklist

- [ ] All 11 Terraform files created
- [ ] Variables configured correctly
- [ ] `terraform init` completed
- [ ] `terraform plan` reviewed
- [ ] `terraform apply` successful
- [ ] ALB DNS name obtained
- [ ] Application accessible
- [ ] CodeDeploy configured
- [ ] Monitoring dashboard created
- [ ] Ready for first deployment

