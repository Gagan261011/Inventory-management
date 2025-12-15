param (
    [string]$Kubeconfig,
    [string]$BackendRepo,
    [string]$FrontendRepo,
    [string]$MasterIP
)

$env:KUBECONFIG = $Kubeconfig

Write-Host "Deploying Inventory App via Helm..."

# Update values.yaml with actual repo URLs (simple string replace for demo)
# Note: In a real pipeline, we'd pass these as --set flags
$helmPath = "../k8s/helm/inventory-app"

helm upgrade --install inventory-app $helmPath `
    --set backend.image.repository=$BackendRepo `
    --set frontend.image.repository=$FrontendRepo `
    --set frontend.env.apiUrl="http://$MasterIP:30080/api" `
    --wait

Write-Host "App Deployed!"
