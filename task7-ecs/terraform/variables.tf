variable "aws_region" {
  description = "AWS Region"
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project Name for Tagging"
  default     = "strapi-ecs-task"
}

# --- Database ---
variable "db_username" {
  description = "Database Master Username"
  default     = "strapi"
}

variable "db_password" {
  description = "Database Master Password"
  sensitive   = true
  default     = "StrapiSecurePass2025!" # Use a strong password!
}

variable "db_name" {
  description = "Database Name"
  default     = "strapidb"
}

# --- Strapi Secrets (Passed as ENV Variables in Fargate) ---
# ideally use Secrets Manager, but for this task we pass as ENV for simplicity
variable "app_keys" { default = "key1,key2" }
variable "api_token_salt" { default = "somerandomsalt123" }
variable "admin_jwt_secret" { default = "supersecretadminjwt" }
variable "jwt_secret" { default = "supersecretjwt" }
