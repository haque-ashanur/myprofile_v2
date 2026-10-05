output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.myprofile.id
}

output "public_ip" {
  description = "Public IPv4 address of the MyProfile EC2 instance."
  value       = aws_instance.myprofile.public_ip
}

output "public_dns" {
  description = "Public DNS name of the MyProfile EC2 instance."
  value       = aws_instance.myprofile.public_dns
}

output "website_url" {
  description = "Initial HTTP URL after K3s/Traefik is configured."
  value       = "http://${aws_instance.myprofile.public_ip}"
}

output "ssh_command" {
  description = "Example SSH command for the Amazon Linux 2023 instance."
  value       = "ssh -i <PATH_TO_PRIVATE_KEY> ec2-user@${aws_instance.myprofile.public_ip}"
}
