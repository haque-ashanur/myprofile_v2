# MyProfile — Python DevOps Portfolio Platform

MyProfile is a Python/Flask portfolio application extended into a practical DevOps platform.

## Stack

Python • Flask • Gunicorn • Git • GitHub • GitHub Actions • Docker • Docker Hub • K3s/Kubernetes • Helm • Prometheus • Grafana • AWS EC2 • CloudWatch

## CI/CD

```text
Git → GitHub → GitHub Actions
                 ↓
          Python validation
                 ↓
             Docker build
                 ↓
          Container health test
                 ↓
          /metrics test
                 ↓
             Docker Hub
```

## Local run

```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

Open `http://127.0.0.1:5000`.

Health: `http://127.0.0.1:5000/health`
Metrics: `http://127.0.0.1:5000/metrics`

## Docker

```powershell
docker build -t myprofile:latest .
docker run --rm -p 5000:5000 myprofile:latest
```

## Kubernetes on EC2 using K3s

This project uses K3s for a lightweight Kubernetes cluster. K3s includes CoreDNS, Traefik, ServiceLB and other packaged components; Traefik is enabled by default in a standard K3s server install.

1. Create an EC2 instance and attach an IAM role with `CloudWatchAgentServerPolicy` for CloudWatch agent use.
2. Allow SSH (22) from your own IP and web traffic (80/443) as required by your deployment.
3. Install K3s with `scripts/install-k3s.sh` or the official K3s install command.
4. Replace `YOUR_DOCKERHUB_USERNAME` in `k8s/deployment.yaml`.
5. Apply the application manifests:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl get pods -n myprofile -o wide
kubectl get svc -n myprofile
```

For a DNS hostname, replace `myprofile.example.com` in `k8s/ingress.yaml` with your DNS name, then apply:

```bash
kubectl apply -f k8s/ingress.yaml
```

## Prometheus and Grafana

Install the community `kube-prometheus-stack` Helm chart:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring/values.yaml \
  --set grafana.adminPassword='CHANGE_ME'
```

Apply the application monitor and alert rule:

```bash
kubectl apply -f monitoring/servicemonitor.yaml
kubectl apply -f monitoring/prometheus-rule.yaml
```

For initial secure local access through an SSH session/port-forward:

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Open Grafana at `http://127.0.0.1:3000` and Prometheus at `http://127.0.0.1:9090`.

## CloudWatch

For Amazon Linux 2023, install the unified CloudWatch agent:

```bash
sudo yum install amazon-cloudwatch-agent -y
sudo cp cloudwatch/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
```

Check status:

```bash
sudo systemctl status amazon-cloudwatch-agent
```

The config collects EC2 CPU, memory, disk and selected system/container logs.

## Notes

- Do not commit Docker Hub tokens, AWS credentials or passwords.
- Prefer an EC2 IAM role for CloudWatch access instead of long-lived access keys.
- For a public production deployment, use HTTPS and a real DNS hostname; do not expose Grafana or Prometheus directly to the Internet unless you have secured them.

## Public URL on EC2

With the hostless Ingress above, K3s Traefik can route HTTP traffic received on the EC2 node to the MyProfile service. The initial lab URL is:

```text
http://<EC2_PUBLIC_IP>/
```

For production, use a DNS name and HTTPS instead of relying on an IP address. K3s installs Traefik by default and its LoadBalancer service uses ports 80 and 443.

## Suggested EC2 lab architecture

```text
Internet
   |
   | :80 / :443
   v
EC2 (Linux)
   |
   +-- K3s
   |    +-- Traefik
   |    +-- MyProfile Deployment (3 replicas)
   |    +-- MyProfile Service
   |
   +-- Prometheus
   +-- Grafana
   +-- CloudWatch Agent
```

Keep Prometheus and Grafana internal at first. Use SSH port-forwarding for administration instead of opening ports 3000 and 9090 to the Internet.

## AWS + Terraform + K3s lab deployment

The `terraform/` directory provisions the AWS foundation for the portfolio lab:

- VPC, public subnet, Internet Gateway and route table
- EC2 security group with SSH restricted to `allowed_ssh_cidr` and HTTP/HTTPS open
- EC2 instance using the latest Amazon Linux 2023 AMI resolved through AWS Systems Manager
- IAM instance role for Systems Manager and CloudWatch
- Encrypted gp3 root volume
- K3s bootstrap and Helm installation through EC2 user data
- CloudWatch unified agent configuration

The AWS provider is pinned to the 6.x major line; the official registry currently lists 6.62.0 as the latest provider release. AWS also publishes current Amazon Linux 2023 AMIs through Systems Manager public parameters. See the Terraform Registry and AWS documentation for the provider and AMI parameter mechanisms.

### Terraform commands

From the repository root:

```powershell
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your EC2 key pair name and your public IP /32.
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Terraform will output the EC2 public IP and initial website URL.

Destroy the lab when it is no longer needed:

```powershell
terraform destroy
```

Do not commit `terraform.tfvars` or Terraform state files. They are ignored by `.gitignore`.

### Configure K3s, MyProfile, Prometheus and Grafana

After SSHing to the EC2 instance, make the repository available on the server and run:

```bash
export DOCKERHUB_USERNAME=YOUR_DOCKERHUB_USERNAME
sudo -E ./scripts/deploy-platform.sh
```

The script installs/updates `kube-prometheus-stack`, deploys the MyProfile application, creates the ServiceMonitor and alert rule, and waits for the 3-replica Deployment rollout.

K3s provides a single-node, fully functional Kubernetes cluster, and the official installation method is the `https://get.k3s.io` script. The EC2 instance role includes `AmazonSSMManagedInstanceCore` and `CloudWatchAgentServerPolicy`, matching AWS guidance for Systems Manager and the CloudWatch agent.

