provider "aws" {
  region = var.aws_region
}

# =========================================================
# IAM ROLE
# =========================================================

resource "aws_iam_role" "ec2" {
  name = "myprofile-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "myprofile-ec2-role"
    Project = "myprofile"
  }
}

# =========================================================
# CLOUDWATCH POLICY
# =========================================================

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# =========================================================
# SYSTEMS MANAGER POLICY
# =========================================================

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# =========================================================
# INSTANCE PROFILE
# =========================================================

resource "aws_iam_instance_profile" "ec2" {
  name = "myprofile-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name    = "myprofile-ec2-profile"
    Project = "myprofile"
  }
}

# =========================================================
# EC2 INSTANCE
# =========================================================

resource "aws_instance" "myprofile" {

  # Ubuntu 24.04 LTS AMI
  ami = "ami-06259b63260eddc13"

  # Free Tier eligible for eligible accounts
  instance_type = var.instance_type

  # Existing AWS networking
  subnet_id = "subnet-09b6afa60fed2cfcb"

  # Existing dedicated security group
  vpc_security_group_ids = [
    "sg-0d398bfbb74d93d4b"
  ]

  # Existing EC2 key pair
  key_name = var.key_name

  # Public IP
  associate_public_ip_address = true

  # IAM role
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  # =======================================================
  # ROOT DISK
  # =======================================================

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # =======================================================
  # T3 STANDARD CPU CREDITS
  # =======================================================

  credit_specification {
    cpu_credits = "standard"
  }

  # =======================================================
  # UBUNTU BOOTSTRAP
  # =======================================================

  user_data = <<-EOF
    #!/bin/bash

    set -euxo pipefail

    exec > >(tee -a /var/log/myprofile-bootstrap.log | logger -t myprofile-bootstrap -s 2>/dev/console) 2>&1

    echo "=============================================="
    echo "MyProfile Ubuntu bootstrap started"
    echo "=============================================="

    export DEBIAN_FRONTEND=noninteractive

    # Update Ubuntu
    apt-get update -y
    apt-get upgrade -y

    # Basic packages
    apt-get install -y \
      curl \
      wget \
      git \
      unzip \
      jq \
      ca-certificates \
      gnupg \
      apt-transport-https \
      software-properties-common

    # =====================================================
    # DOCKER
    # =====================================================

    install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc

    chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      > /etc/apt/sources.list.d/docker.list

    apt-get update -y

    apt-get install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    # =====================================================
    # K3S
    # =====================================================

    curl -sfL https://get.k3s.io | sh -

    systemctl enable k3s
    systemctl start k3s

    # Configure kubectl for Ubuntu user
    mkdir -p /home/ubuntu/.kube

    cp /etc/rancher/k3s/k3s.yaml \
      /home/ubuntu/.kube/config

    chown -R ubuntu:ubuntu /home/ubuntu/.kube

    chmod 600 /home/ubuntu/.kube/config

    # =====================================================
    # HELM
    # =====================================================

    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # =====================================================
    # VERIFICATION
    # =====================================================

    docker --version || true

    kubectl version --client || true

    helm version || true

    systemctl status k3s --no-pager || true

    echo "MyProfile EC2 bootstrap completed" \
      | tee /var/log/myprofile-ready

    echo "=============================================="
    echo "MyProfile Ubuntu EC2 bootstrap finished"
    echo "=============================================="

  EOF

  tags = {
    Name        = "myprofile-ec2"
    Project     = "myprofile"
    Environment = "dev"
    OS          = "Ubuntu"
  }
}