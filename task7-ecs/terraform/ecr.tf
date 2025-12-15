resource "aws_ecr_repository" "app_repo" {
  name                 = "neeraj-strapi-ecs-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
