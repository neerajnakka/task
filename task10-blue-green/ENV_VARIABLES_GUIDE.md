# Environment Variables Guide

This guide explains how to manage environment variables for Task 10.

---

## 📋 Overview

All environment variables are now defined in `terraform/variables.tf` with sensible defaults. You have three options to customize them:

1. **Use defaults** (easiest for development)
2. **Create terraform.tfvars file** (recommended for production)
3. **Pass via command line** (for CI/CD)

---

## 🔧 Option 1: Use Defaults (Easiest)

All variables have default values in `variables.tf`. Simply run:

```bash
cd terraform
terraform init
terraform apply
```

**Default Values:**
- `db_password` = `StrapiSecurePass2025!`
- `app_keys` = `key1,key2`
- `api_token_salt` = `somerandomsalt123`
- `admin_jwt_secret` = `supersecretadminjwt`
- `jwt_secret` = `supersecretjwt`
- `node_env` = `production`
- `deployment_strategy` = `CodeDeployDefault.ECSCanary10Percent5Minutes`
- `enable_auto_rollback` = `true`
- `termination_wait_time_minutes` = `5`

---

## 📝 Option 2: Create terraform.tfvars File (Recommended)

### **Step 1: Copy the Example File**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### **Step 2: Edit terraform.tfvars**
```hcl
# terraform.tfvars

aws_region   = "ap-south-1"
project_name = "strapi"

# Database
db_password = "YourStrongPassword123!"

# Deployment
deployment_strategy = "CodeDeployDefault.ECSCanary10Percent5Minutes"
enable_auto_rollback = true
termination_wait_time_minutes = 5

# ECS
ecs_task_cpu    = 1024
ecs_task_memory = 2048
ecs_desired_count = 1

# Strapi Secrets
app_keys           = "key1,key2"
api_token_salt     = "somerandomsalt123"
admin_jwt_secret   = "supersecretadminjwt"
jwt_secret         = "supersecretjwt"
node_env           = "production"

# Networking
vpc_cidr        = "10.0.0.0/16"
container_port  = 1337
alb_port        = 80
```

### **Step 3: Run Terraform**
```bash
terraform plan
terraform apply
```

**Note:** `terraform.tfvars` is in `.gitignore` and won't be committed to git.

---

## 🔐 Option 3: Pass via Command Line (For CI/CD)

```bash
terraform apply \
  -var="db_password=YourPassword" \
  -var="app_keys=key1,key2" \
  -var="deployment_strategy=CodeDeployDefault.ECSCanary10Percent5Minutes"
```

---

## 📂 File Structure

```
task10-blue-green/terraform/
├── variables.tf                 # All variables with defaults
├── terraform.tfvars.example     # Example file (template)
├── terraform.tfvars             # Your custom values (NOT in git)
├── .gitignore                   # Prevents committing secrets
└── *.tf                         # Other Terraform files
```

---

## 🔒 Security Best Practices

### **1. Never Commit Secrets**
```bash
# ✅ GOOD: terraform.tfvars is in .gitignore
# ✗ BAD: Committing terraform.tfvars with passwords

# Check what will be committed
git status
```

### **2. Use Strong Passwords**
```bash
# Generate strong password
openssl rand -base64 32

# Example output:
# aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890+/==
```

### **3. Generate Strong Secrets**
```bash
# Generate JWT secret
openssl rand -base64 32

# Generate API token salt
openssl rand -base64 32

# Generate app keys
openssl rand -base64 16,openssl rand -base64 16
```

### **4. For Production: Use AWS Secrets Manager**
```hcl
# Instead of storing in variables.tf, use Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
}

variable "db_password" {
  default = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

---

## 📊 Variable Reference

### **Basic Configuration**
| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `ap-south-1` | AWS region |
| `project_name` | `strapi` | Project name for resources |

### **Database**
| Variable | Default | Description |
|----------|---------|-------------|
| `db_password` | `StrapiSecurePass2025!` | RDS password |

### **Deployment**
| Variable | Default | Description |
|----------|---------|-------------|
| `deployment_strategy` | `CodeDeployDefault.ECSCanary10Percent5Minutes` | Deployment strategy |
| `enable_auto_rollback` | `true` | Auto rollback on failure |
| `termination_wait_time_minutes` | `5` | Grace period before deleting Blue |

### **ECS**
| Variable | Default | Description |
|----------|---------|-------------|
| `ecs_task_cpu` | `1024` | CPU units |
| `ecs_task_memory` | `2048` | Memory in MB |
| `ecs_desired_count` | `1` | Number of tasks |

### **Strapi Secrets**
| Variable | Default | Description |
|----------|---------|-------------|
| `app_keys` | `key1,key2` | Strapi APP_KEYS |
| `api_token_salt` | `somerandomsalt123` | API token salt |
| `admin_jwt_secret` | `supersecretadminjwt` | Admin JWT secret |
| `jwt_secret` | `supersecretjwt` | JWT secret |
| `node_env` | `production` | Node environment |

### **Networking**
| Variable | Default | Description |
|----------|---------|-------------|
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `container_port` | `1337` | Container port |
| `alb_port` | `80` | ALB port |

---

## 🔄 Workflow Examples

### **Development (Use Defaults)**
```bash
cd terraform
terraform init
terraform apply
# Uses all defaults from variables.tf
```

### **Staging (Custom Values)**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with staging values
terraform apply
```

### **Production (Strong Secrets)**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars

# Generate strong values
DB_PASS=$(openssl rand -base64 32)
APP_KEY=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 32)

# Update terraform.tfvars
sed -i "s/db_password = .*/db_password = \"$DB_PASS\"/" terraform.tfvars
sed -i "s/app_keys = .*/app_keys = \"$APP_KEY\"/" terraform.tfvars
sed -i "s/jwt_secret = .*/jwt_secret = \"$JWT_SECRET\"/" terraform.tfvars

terraform apply
```

### **CI/CD Pipeline**
```bash
# In GitHub Actions or similar
terraform apply \
  -var="db_password=${{ secrets.DB_PASSWORD }}" \
  -var="app_keys=${{ secrets.APP_KEYS }}" \
  -var="jwt_secret=${{ secrets.JWT_SECRET }}"
```

---

## ✅ Verification Checklist

- [ ] `terraform.tfvars` is in `.gitignore`
- [ ] `terraform.tfvars.example` is committed to git
- [ ] Sensitive values are NOT in `variables.tf` defaults (for production)
- [ ] Strong passwords are used (for production)
- [ ] Secrets are rotated regularly (for production)
- [ ] AWS Secrets Manager is used (for production)

---

## 🚨 Common Mistakes

### ❌ Mistake 1: Committing terraform.tfvars
```bash
# DON'T DO THIS
git add terraform.tfvars
git commit -m "Add variables"
git push
```

**Solution:** Check `.gitignore` includes `terraform.tfvars`

### ❌ Mistake 2: Using Weak Passwords
```hcl
# DON'T DO THIS
db_password = "password123"
```

**Solution:** Use strong passwords (16+ characters, mixed case, numbers, symbols)

### ❌ Mistake 3: Hardcoding Secrets in Code
```hcl
# DON'T DO THIS
jwt_secret = "mysecret"  # In variables.tf
```

**Solution:** Use defaults only for development, use Secrets Manager for production

### ❌ Mistake 4: Forgetting to Copy Example File
```bash
# DON'T DO THIS
terraform apply  # Without creating terraform.tfvars
```

**Solution:** Either use defaults or create terraform.tfvars from example

---

## 📚 Additional Resources

- [Terraform Variables Documentation](https://www.terraform.io/language/values/variables)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [Terraform Sensitive Data](https://www.terraform.io/language/values/variables#sensitive)

---

## 🎯 Summary

**For Development:**
- Use defaults from `variables.tf`
- Run `terraform apply` without any variables

**For Production:**
- Create `terraform.tfvars` from example
- Use strong, randomly generated passwords
- Use AWS Secrets Manager for sensitive data
- Never commit `terraform.tfvars` to git

