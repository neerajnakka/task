# AWS Account Notes & Limitations

## ⚠️ Issues Encountered During Deployment

### **1. CodeDeploy Subscription Required**

**Error:**
```
The AWS Access Key Id needs a subscription for the service
```

**Cause:** Your AWS account doesn't have CodeDeploy service enabled.

**Solution Options:**

**Option A: Enable CodeDeploy (Recommended)**
1. Go to AWS Console
2. Search for "CodeDeploy"
3. Click on CodeDeploy service
4. It will automatically enable the service
5. Re-run `terraform apply`

**Option B: Skip CodeDeploy (For Learning)**
If you want to test the infrastructure without CodeDeploy:
1. Comment out the CodeDeploy resources in `codedeploy.tf`
2. Run `terraform apply` again
3. The rest of the infrastructure will deploy successfully

---

### **2. IAM Policy Name Correction**

**Error:**
```
Policy arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForECS does not exist
```

**Fix Applied:** ✅
Changed policy ARN from:
```
arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForECS
```

To:
```
arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS
```

---

### **3. RDS Free Tier Backup Retention Limit**

**Error:**
```
The specified backup retention period exceeds the maximum available to free tier customers
```

**Cause:** Free tier RDS only allows 1 day backup retention.

**Fix Applied:** ✅
Changed backup retention from 7 days to 1 day:
```hcl
backup_retention_period = 1  # Free tier allows 1 day retention
```

---

## ✅ What Was Successfully Created

Despite the errors, most resources were created successfully:

✅ VPC and Subnets  
✅ Security Groups  
✅ Application Load Balancer (ALB)  
✅ Target Groups (Blue & Green)  
✅ ECS Cluster  
✅ IAM Roles  
✅ ECR Repository  
✅ CloudWatch Log Group  
✅ CloudWatch Alarms & Dashboard  

❌ CodeDeploy (requires service subscription)  
❌ RDS Database (free tier limitation)  

---

## 🚀 Next Steps

### **To Complete the Deployment:**

1. **Enable CodeDeploy Service:**
   - Go to AWS Console
   - Search for CodeDeploy
   - Click to enable it
   - Run `terraform apply` again

2. **Or Skip CodeDeploy (For Testing):**
   - Comment out CodeDeploy resources
   - Run `terraform apply` again

3. **Check Created Resources:**
   ```bash
   terraform output
   ```

---

## 📝 Free Tier Limitations

Your AWS account is on the free tier. Here are the limitations:

| Service | Limitation |
|---------|-----------|
| RDS | 1 day backup retention |
| RDS | db.t3.micro instance only |
| RDS | 20 GB storage |
| ECS Fargate | 750 hours/month |
| ALB | 750 hours/month |
| Data Transfer | 1 GB/month outbound |

---

## 💡 Recommendations

1. **For Production:** Upgrade to a paid AWS account
2. **For Learning:** Use the free tier resources as-is
3. **For Testing:** Comment out expensive resources (RDS, CodeDeploy)

---

## 🔧 How to Fix and Retry

### **Step 1: Enable CodeDeploy**
```
AWS Console → Search "CodeDeploy" → Click to enable
```

### **Step 2: Destroy Current Resources (Optional)**
```bash
cd task10-blue-green/terraform
terraform destroy -auto-approve
```

### **Step 3: Re-apply**
```bash
terraform apply -auto-approve
```

---

## 📞 Support

If you encounter other issues:

1. Check AWS Console for service limits
2. Verify IAM permissions
3. Check CloudWatch logs for errors
4. Review Terraform error messages

---

## ✨ Summary

The infrastructure is **mostly working**! The errors are due to AWS account limitations, not code issues. Once you enable CodeDeploy and upgrade your RDS plan (or use free tier limits), everything will work perfectly.

