# Retrieve the latest Amazon Linux 2023 EKS-optimized AMI for EKS 1.32
data "aws_ssm_parameter" "eks_al2023_ami" {
  # The SSM parameter path points to the official AWS EKS-optimized AL2023 image
  name = "/aws/service/eks/optimized-ami/1.32/amazon-linux-2023/x86_64/standard/image_id"
}

resource "aws_launch_template" "eks_nodes" {
  # Prefix for the Launch Template name
  name_prefix   = "${local.cluster_name}-lt-"

  # Use the AL2023 EKS-optimized AMI retrieved via SSM
  image_id      = data.aws_ssm_parameter.eks_al2023_ami.value

  # EC2 instance type for worker nodes
  instance_type = var.worker_nodes_type

  # SSH key for accessing EC2 instances (optional)
  key_name      = local.sshkey_name

  # Configure the root volume
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20        # Root volume size in GB
      volume_type = "gp3"     # Use GP3 for better performance and cost efficiency
      encrypted   = true      # Enable encryption for security
    }
  }

  # Network configuration for the EC2 instances
  network_interfaces {
    associate_public_ip_address = false                 # Do not assign public IPs
    security_groups             = [aws_security_group.ec2-bastion.id] # Attach security group
  }

  # Tags applied to EC2 instances launched from this template
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.cluster_name}-node"
    }
  }
}
