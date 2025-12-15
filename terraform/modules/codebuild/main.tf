variable "project_name" {}
variable "backend_repo_url" {}
variable "frontend_repo_url" {}
variable "region" {}

resource "aws_s3_bucket" "source" {
  bucket_prefix = "${var.project_name}-source-"
  force_destroy = true
}

resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = ["*"]
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
      }
    ]
  })
}

resource "aws_codebuild_project" "build" {
  name          = "${var.project_name}-build"
  description   = "Builds inventory app images"
  build_timeout = "15"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }
    environment_variable {
      name  = "BACKEND_REPO_URL"
      value = var.backend_repo_url
    }
    environment_variable {
      name  = "FRONTEND_REPO_URL"
      value = var.frontend_repo_url
    }
  }

  source {
    type     = "S3"
    location = "${aws_s3_bucket.source.id}/source.zip"
  }
}

output "project_name" { value = aws_codebuild_project.build.name }
output "bucket_name" { value = aws_s3_bucket.source.id }
