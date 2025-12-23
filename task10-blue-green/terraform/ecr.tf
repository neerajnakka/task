# ============================================================================
# ECR REPOSITORY - Elastic Container Registry
# ============================================================================
# This is where Docker images are stored
# GitHub Actions will push images here
# ECS will pull images from here

resource "aws_ecr_repository" "app_repo" {
  name                 = "${var.project_name}-ecs-repo"
  image_tag_mutability = "MUTABLE"  # Allow overwriting image tags
  
  # Enable image scanning for vulnerabilities
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "${var.project_name}-ecr-repo"
  }
}

# ============================================================================
# ECR REPOSITORY LIFECYCLE POLICY
# ============================================================================
# This policy automatically deletes old images to save storage costs
# Keeps only the last 10 images

resource "aws_ecr_lifecycle_policy" "app_repo_policy" {
  repository = aws_ecr_repository.app_repo.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}


