param (
    [string]$MasterIP,
    [string]$KeyPath
)

$maxRetries = 60
$retryCount = 0
$sshCommand = "ssh -o StrictHostKeyChecking=no -i '$KeyPath' ubuntu@$MasterIP 'kubectl get nodes'"

Write-Host "Waiting for Kubernetes API on $MasterIP..."

while ($retryCount -lt $maxRetries) {
    try {
        Invoke-Expression $sshCommand
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Kubernetes is ready!"
            exit 0
        }
    }
    catch {
        Write-Host "Waiting..."
    }
    Start-Sleep -Seconds 10
    $retryCount++
}

Write-Error "Timeout waiting for Kubernetes"
exit 1
