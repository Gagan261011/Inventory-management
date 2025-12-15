param (
    [string]$Kubeconfig
)

$env:KUBECONFIG = $Kubeconfig

Write-Host "Installing Argo CD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host "Waiting for Argo CD server..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Patch to NodePort for access
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "nodePort": 30080}, {"port": 443, "nodePort": 30443}]}}'

Write-Host "Argo CD Installed."
