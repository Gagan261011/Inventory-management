# Architecture Decisions

## 1. Self-Managed Kubernetes (kubeadm)
**Decision**: Use `kubeadm` on EC2 instances instead of EKS.
**Reasoning**: 
*   Demonstrates deep understanding of Kubernetes internals.
*   Lower cost for a demo (no EKS control plane fee).
*   Full control over the control plane components.

## 2. SSM Parameter Store for Join Automation
**Decision**: Use AWS SSM Parameter Store to exchange the `kubeadm join` command.
**Reasoning**:
*   **Security**: Avoids hardcoding tokens in user data or passing them via insecure channels.
*   **Automation**: Allows worker nodes to "wait" for the master to be ready without complex orchestration tools like Ansible.
*   **Simplicity**: Native AWS integration without extra infrastructure.

## 3. NodePort for Exposure
**Decision**: Use NodePort for exposing the application and Argo CD.
**Reasoning**:
*   **Simplicity**: Avoids the complexity and cost of an AWS Load Balancer (ALB/NLB) for a simple demo.
*   **Direct Access**: Allows direct access to the nodes via their public IPs (controlled via Security Groups).

## 4. AWS CodeBuild for CI/CD
**Decision**: Use AWS CodeBuild instead of local Docker or GitHub Actions.
**Reasoning**:
*   **Client-Grade**: Represents a real-world enterprise CI/CD pattern.
*   **Self-Contained**: Does not rely on external services (like Docker Hub) or local machine configuration (Docker Desktop).
*   **IAM Integration**: Seamlessly pushes to ECR using IAM roles.

## 5. Argo CD for GitOps
**Decision**: Use Argo CD for application deployment.
**Reasoning**:
*   **Industry Standard**: Argo CD is the de-facto standard for GitOps on Kubernetes.
*   **Visibility**: Provides a nice UI to visualize the application state.
*   **Drift Detection**: Ensures the cluster state matches the desired state in Git.
