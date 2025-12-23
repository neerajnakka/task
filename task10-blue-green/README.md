# Task 10: Blue/Green Deployment with CodeDeploy

## 🎯 What You've Built

A **production-grade Blue/Green deployment infrastructure** for Strapi on AWS ECS Fargate with automatic traffic shifting and rollback capabilities.

---

## 📚 Documentation Files

1. **TASK10_GUIDE.md** - Complete guide with architecture, deployment process, and troubleshooting
2. **UNDERSTANDING_THE_CODE.md** - Deep dive into how each file works and why
3. **README.md** - This file (quick start)

---

## 🚀 Quick Start

### **1. Initialize Terraform**
```bash
cd terraform
terraform init
```

### **2. Create Variables File (Optional)**
```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your custom values (optional)
# If you don't create this file, defaults from variables.tf will be used
```

### **3. Plan the Deployment**
```bash
terraform plan
# Or with custom values:
# terraform plan -var="db_password=YourPassword"
```

### **4. Deploy Infrastructure**
```bash
terraform apply
# Or with custom values:
# terraform apply -var="db_password=YourPassword"
```

### **5. Access Application**
```
http://<ALB_DNS_NAME>/admin
```

---

## 📁 File Structure

```
task10-blue-green/
├── terraform/
│   ├── provider.tf              # AWS provider
│   ├── variables.tf             # Input variables
│   ├── networking.tf            # VPC, Subnets, Security Groups
│   ├── rds.tf                   # PostgreSQL database
│   ├── ecr.tf                   # Docker image registry
│   ├── alb.tf                   # Load balancer (MODIFIED)
│   ├── ecs.tf                   # ECS cluster & service (MODIFIED)
│   ├── iam.tf                   # IAM roles (NEW)
│   ├── codedeploy.tf            # CodeDeploy orchestration (NEW)
│   ├── monitoring.tf            # CloudWatch alarms & dashboard
│   └── outputs.tf               # Output values
├── TASK10_GUIDE.md              # Complete guide
├── UNDERSTANDING_THE_CODE.md    # Code deep dive
└── README.md                    # This file
```

---

## 🏗️ Architecture

```
User Request
    ↓
ALB (Port 80)
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

## 🔑 Key Features

✅ **Blue/Green Deployment** - Zero-downtime deployments  
✅ **Automatic Traffic Shifting** - Canary, Linear, or AllAtOnce strategies  
✅ **Automatic Rollback** - Instant rollback if new version fails  
✅ **Health Checks** - Continuous monitoring of task health  
✅ **Monitoring** - CloudWatch dashboards and alarms  
✅ **High Availability** - Multi-AZ deployment  
✅ **Serverless** - ECS Fargate (no EC2 management)  
✅ **Managed Database** - AWS RDS PostgreSQL  

---

## 📊 Deployment Strategies

### **Canary (Recommended)**
- 10% traffic for 5 minutes
- Then 100% if healthy
- Fast and safe

### **Linear**
- 10% every 10 minutes
- Takes ~90 minutes total
- Very safe for critical systems

### **AllAtOnce**
- 100% immediately
- Fastest but riskiest
- For non-critical systems

---

## 🔐 Security

- **ALB Security Group**: Allows HTTP (80) from anywhere
- **ECS Security Group**: Allows port 1337 ONLY from ALB
- **RDS Security Group**: Allows port 5432 ONLY from ECS
- **Private Subnets**: RDS in private subnets (no internet access)
- **IAM Roles**: Least privilege permissions

---

## 📈 Monitoring

- **CloudWatch Dashboard**: CPU, Memory, Task Count, Network Traffic
- **CloudWatch Alarms**: CPU > 80%, Memory > 80%
- **CloudWatch Logs**: Centralized logging in `/ecs/strapi-app`
- **Container Insights**: Detailed ECS metrics

---

## 🚀 Deployment Process

### **Initial Deployment**
1. `terraform apply` creates infrastructure
2. ECS service starts with Blue tasks
3. ALB routes 100% traffic to Blue
4. Application is live

### **New Version Deployment**
1. Push new Docker image to ECR
2. Create new ECS task definition
3. Trigger CodeDeploy deployment
4. CodeDeploy creates Green tasks
5. Traffic gradually shifts: Blue → Green
6. If healthy: Blue tasks terminated
7. If unhealthy: Automatic rollback to Blue

---

## 🔄 Rollback

**Automatic Rollback Triggers:**
- Green tasks fail health checks
- Deployment times out
- Error rate exceeds threshold

**Rollback Process:**
1. CodeDeploy detects failure
2. Updates ALB weights: Blue 100%, Green 0%
3. All traffic back to Blue
4. Green tasks terminated
5. Deployment marked as failed

---

## 📝 Configuration

### **Deployment Strategy**
```bash
terraform apply \
  -var="db_password=YourPassword" \
  -var="deployment_strategy=CodeDeployDefault.ECSCanary10Percent5Minutes"
```

### **Auto Rollback**
```bash
terraform apply \
  -var="db_password=YourPassword" \
  -var="enable_auto_rollback=true"
```

### **Termination Grace Period**
```bash
terraform apply \
  -var="db_password=YourPassword" \
  -var="termination_wait_time_minutes=5"
```

---

## 🛠️ Terraform Commands

```bash
# Initialize
terraform init

# Plan
terraform plan -var="db_password=YourPassword"

# Apply
terraform apply -var="db_password=YourPassword"

# Destroy
terraform destroy -var="db_password=YourPassword"

# Show outputs
terraform output

# Show specific output
terraform output alb_dns_name
```

---

## 📊 Outputs

After `terraform apply`, you'll get:

```
application_url = "http://strapi-alb-123.ap-south-1.elb.amazonaws.com"
admin_panel_url = "http://strapi-alb-123.ap-south-1.elb.amazonaws.com/admin"
alb_dns_name = "strapi-alb-123.ap-south-1.elb.amazonaws.com"
ecs_cluster_name = "strapi-ecs-cluster"
ecs_service_name = "strapi-service"
codedeploy_app_name = "strapi-app"
codedeploy_deployment_group_name = "strapi-deployment-group"
rds_endpoint = "strapi-db.c9akciq32.us-east-1.rds.amazonaws.com"
ecr_repository_url = "123456789.dkr.ecr.ap-south-1.amazonaws.com/strapi-ecs-repo"
```

---

## 🎓 Learning Outcomes

After completing Task 10, you'll understand:

✅ Blue/Green deployment strategy  
✅ CodeDeploy orchestration  
✅ Weighted traffic routing  
✅ Automatic rollback mechanisms  
✅ Canary deployments  
✅ Zero-downtime deployments  
✅ Production-grade deployment patterns  
✅ ECS with CodeDeploy integration  
✅ IAM roles and permissions  
✅ CloudWatch monitoring  

---

## 🔗 Related Tasks

- **Task 7**: ECS Fargate basics (foundation for Task 10)
- **Task 8**: CloudWatch monitoring (used in Task 10)
- **Task 9**: Fargate Spot (can be combined with Task 10)

---

## 📚 Additional Resources

- [AWS CodeDeploy Documentation](https://docs.aws.amazon.com/codedeploy/)
- [AWS ECS Blue/Green Deployments](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-bluegreen.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## ⚠️ Important Notes

1. **Secrets**: Currently using environment variables. Use AWS Secrets Manager in production.
2. **SSL/TLS**: Currently HTTP only. Add HTTPS with ACM certificate in production.
3. **Cost**: Blue/Green requires running two versions temporarily. Budget accordingly.
4. **Monitoring**: Set up SNS notifications for alarms in production.
5. **Backups**: Ensure RDS backup strategy is configured.

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

---

## ✅ Verification Checklist

- [ ] All 11 Terraform files created
- [ ] `terraform init` completed
- [ ] `terraform plan` reviewed
- [ ] `terraform apply` successful
- [ ] ALB DNS name obtained
- [ ] Application accessible
- [ ] CodeDeploy configured
- [ ] Monitoring dashboard created
- [ ] Ready for first deployment

---

## 📞 Quick Reference

**Terraform:**
```bash
terraform init
terraform plan -var="db_password=YourPassword"
terraform apply -var="db_password=YourPassword"
terraform destroy -var="db_password=YourPassword"
```

**AWS CLI:**
```bash
aws deploy create-deployment --application-name strapi-app ...
aws deploy get-deployment --deployment-id <ID>
aws ecs describe-services --cluster strapi-ecs-cluster --services strapi-service
aws logs tail /ecs/strapi-app --follow
```

---

## 🎯 Next Steps

1. Read **TASK10_GUIDE.md** for complete guide
2. Read **UNDERSTANDING_THE_CODE.md** for code deep dive
3. Deploy infrastructure with `terraform apply`
4. Test the application
5. Create a new Docker image
6. Trigger a CodeDeploy deployment
7. Monitor the Blue/Green traffic shift
8. Test automatic rollback (optional)

---

## 📝 Summary

Task 10 implements a **production-grade Blue/Green deployment system** that enables:
- Zero-downtime deployments
- Automatic traffic shifting
- Instant rollback on failure
- Continuous monitoring
- High availability

This is the foundation for modern DevOps practices and is used by major companies for production deployments.

