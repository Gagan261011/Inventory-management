variable "project_name" {}

resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

output "backend_repo_url" { value = aws_ecr_repository.backend.repository_url }
output "frontend_repo_url" { value = aws_ecr_repository.frontend.repository_url }
