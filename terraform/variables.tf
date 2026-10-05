variable "aws_region" {
  description = "AWS region for the MyProfile environment."
  type        = string
  default     = "ap-south-1"
}

variable "availability_zone" {
  description = "Availability Zone in the selected region."
  type        = string
  default     = "ap-south-1a"
}

variable "key_name" {
  description = "Existing EC2 Key Pair name used for SSH access."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to the instance. Example: 203.0.113.10/32."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance size for the K3s portfolio lab."
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 30
}
