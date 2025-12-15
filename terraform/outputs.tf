output "master_public_ip" {
  value = module.ec2_k8s.master_public_ip
}

output "worker_public_ips" {
  value = module.ec2_k8s.worker_public_ips
}

output "app_url" {
  value = "http://${module.ec2_k8s.master_public_ip}:30080"
}

output "argocd_url" {
  value = "https://${module.ec2_k8s.master_public_ip}:30443"
}

output "argocd_password_command" {
  value = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
}

output "kubeconfig_command" {
  value = "scp -i ${var.key_name}.pem ubuntu@${module.ec2_k8s.master_public_ip}:/home/ubuntu/.kube/config ./kubeconfig"
}
