provider "aws" {
  region = var.region
}

module "vpc" {
  source       = "./modules/vpc"
  region       = var.region
  project_name = var.project_name
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "codebuild" {
  source            = "./modules/codebuild"
  project_name      = var.project_name
  region            = var.region
  backend_repo_url  = module.ecr.backend_repo_url
  frontend_repo_url = module.ecr.frontend_repo_url
}

# Create Key Pair
resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

module "ec2_k8s" {
  source                = "./modules/ec2-k8s"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids
  key_name              = aws_key_pair.auth.key_name
  allowed_ssh_cidr      = var.allowed_ssh_cidr
  instance_profile_name = module.iam.instance_profile_name
  
  master_userdata = templatefile("${path.module}/userdata/master-cloudinit.sh", {
    region = var.region
  })
  
  worker_userdata = templatefile("${path.module}/userdata/worker-cloudinit.sh", {
    region = var.region
  })
}

# Zip the apps directory for CodeBuild
resource "null_resource" "zip_source" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "powershell -Command \"Compress-Archive -Path '../apps/*' -DestinationPath 'source.zip' -Force\""
    working_dir = path.module
  }
}

# Upload source to S3
resource "aws_s3_object" "source_code" {
  bucket = module.codebuild.bucket_name
  key    = "source.zip"
  source = "${path.module}/source.zip"
  etag   = filemd5("${path.module}/source.zip")
  depends_on = [null_resource.zip_source]
}

# Trigger CodeBuild
resource "null_resource" "trigger_build" {
  triggers = {
    source_version = aws_s3_object.source_code.version_id
  }
  provisioner "local-exec" {
    command = "aws codebuild start-build --project-name ${module.codebuild.project_name} --region ${var.region}"
  }
  depends_on = [aws_s3_object.source_code]
}

# Wait for K8s and Install ArgoCD + App
resource "null_resource" "k8s_bootstrap" {
  triggers = {
    master_ip = module.ec2_k8s.master_public_ip
  }

  # 1. Wait for Master to be ready (SSH check)
  provisioner "local-exec" {
    command = "powershell -File ./scripts/wait_for_k8s.ps1 -MasterIP ${module.ec2_k8s.master_public_ip} -KeyPath '${replace(var.public_key_path, ".pub", "")}'"
    working_dir = path.module
  }

  # 2. Fetch Kubeconfig
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i '${replace(var.public_key_path, ".pub", "")}' ubuntu@${module.ec2_k8s.master_public_ip}:/home/ubuntu/.kube/config ./kubeconfig"
    working_dir = path.module
  }

  # 3. Install ArgoCD
  provisioner "local-exec" {
    command = "powershell -File ./scripts/install_argocd.ps1 -Kubeconfig ./kubeconfig"
    working_dir = path.module
  }

  # 4. Deploy App (Direct Helm Install for immediate demo)
  provisioner "local-exec" {
    command = "powershell -File ./scripts/deploy_app.ps1 -Kubeconfig ./kubeconfig -BackendRepo ${module.ecr.backend_repo_url} -FrontendRepo ${module.ecr.frontend_repo_url} -MasterIP ${module.ec2_k8s.master_public_ip}"
    working_dir = path.module
  }
}
