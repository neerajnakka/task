# Environment Variables - Updated Configuration

## ✅ What Changed

All environment variables are now **defined in `variables.tf` with sensible defaults**. You no longer need to pass them via the terminal every time!

---

## 📋 New Files Created

1. **`terraform.tfvars.example`** - Template file for custom values
2. **`.gitignore`** - Prevents committing sensitive files
3. **`ENV_VARIABLES_GUIDE.md`** - Complete guide for managing variables

---

## 🚀 How to Deploy Now

### **Option 1: Use Defaults (Easiest)**
```bash
cd task10-blue-green/terraform
terraform init
terraform apply
# Done! Uses all defaults from variables.tf
```

### **Option 2: Create Custom terraform.tfvars**
```bash
cd task10-blue-green/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your custom values
terraform apply
```

### **Option 3: Pass via Command Line (CI/CD)**
```bash
terraform apply -var="db_password=YourPassword"
```

---

## 📊 Default Environment Variables

All these variables now have defaults in `variables.tf`:

### **Database**
```hcl
db_password = "StrapiSecurePass2025!"
```

### **Strapi Secrets**
```hcl
app_keys           = "key1,key2"
api_token_salt     = "somerandomsalt123"
admin_jwt_secret   = "supersecretadminjwt"
jwt_secret         = "supersecretjwt"
node_env           = "production"
```

### **Deployment**
```hcl
deployment_strategy          = "CodeDeployDefault.ECSCanary10Percent5Minutes"
enable_auto_rollback         = true
termination_wait_time_minutes = 5
```

### **ECS**
```hcl
ecs_task_cpu    = 1024
ecs_task_memory = 2048
ecs_desired_count = 1
```

### **Networking**
```hcl
vpc_cidr       = "10.0.0.0/16"
container_port = 1337
alb_port       = 80
```

---

## 🔐 Security Notes

### **For Development**
- Use defaults as-is
- No need to create terraform.tfvars
- Suitable for learning and testing

### **For Production**
- Create `terraform.tfvars` with strong passwords
- Use AWS Secrets Manager for sensitive data
- Never commit `terraform.tfvars` to git
- Rotate secrets regularly

---

## 📝 Updated Files

### **variables.tf**
- Added defaults to all variables
- Added Strapi environment variables
- Added deployment configuration variables

### **ecs.tf**
- Updated to use variables instead of hardcoded values
- Now references: `var.db_password`, `var.app_keys`, `var.jwt_secret`, etc.

### **README.md**
- Updated quick start guide
- Removed need to pass variables via terminal

### **TASK10_GUIDE.md**
- Updated deployment instructions
- Simplified the process

### **COMPLETION_SUMMARY.md**
- Updated deployment steps

---

## 🔄 Workflow

### **Development Workflow**
```bash
cd task10-blue-green/terraform
terraform init
terraform apply
# Uses all defaults, no variables needed
```

### **Production Workflow**
```bash
cd task10-blue-green/terraform
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with production values
# Generate strong passwords:
# openssl rand -base64 32

terraform plan
terraform apply
```

### **CI/CD Workflow**
```bash
# In GitHub Actions or similar
terraform apply \
  -var="db_password=${{ secrets.DB_PASSWORD }}" \
  -var="app_keys=${{ secrets.APP_KEYS }}"
```

---

## ✅ Verification

Check that everything is set up correctly:

```bash
cd task10-blue-green/terraform

# 1. Verify variables.tf has defaults
grep "default =" variables.tf

# 2. Verify .gitignore exists
cat .gitignore

# 3. Verify terraform.tfvars.example exists
ls -la terraform.tfvars.example

# 4. Initialize Terraform
terraform init

# 5. Plan without any variables
terraform plan
```

---

## 📚 Documentation

For detailed information about managing environment variables, see:
- **`ENV_VARIABLES_GUIDE.md`** - Complete guide with examples
- **`terraform.tfvars.example`** - Template with all available options

---

## 🎯 Summary

**Before:** Had to pass variables via terminal every time
```bash
terraform apply -var="db_password=..." -var="app_keys=..." ...
```

**After:** Variables have defaults, just run:
```bash
terraform apply
```

**Or customize with terraform.tfvars:**
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform apply
```

---

## 🚀 Next Steps

1. Read `ENV_VARIABLES_GUIDE.md` for detailed information
2. Run `terraform init` in the terraform directory
3. Run `terraform apply` to deploy with defaults
4. Or create `terraform.tfvars` for custom values

**That's it! No more terminal variables needed!** ✨

