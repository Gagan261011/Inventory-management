#!/bin/bash
set -e

# 1. Install Dependencies
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common jq unzip

# 2. Install Containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y containerd.io
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd

# 3. Install Kubernetes components
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 4. Install AWS CLI
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
fi

# 5. Poll SSM for Join Command
echo "Waiting for join command..."
while true; do
    JOIN_CMD=$(aws ssm get-parameter --name "/inventory-app/join-command" --with-decryption --query "Parameter.Value" --output text --region ${region} || echo "")
    if [ -n "$JOIN_CMD" ] && [ "$JOIN_CMD" != "None" ]; then
        echo "Join command found!"
        break
    fi
    sleep 10
done

# 6. Join Cluster
$JOIN_CMD

echo "Worker join complete" > /var/log/worker-join.done
