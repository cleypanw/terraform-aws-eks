# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.26.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.32"

  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  # Security group for EC2 bastion
  cluster_additional_security_group_ids = [
    aws_security_group.ec2-bastion.id
  ]

  enable_cluster_creator_admin_permissions = true
}

# Launch Template for Node Group to enforce gp3 root volumes
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${local.cluster_name}-lt-"
  image_id      = data.aws_ami.eks.id   # EKS optimized AMI
  instance_type = var.worker_nodes_type

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.eks_node_group.name
  }
}

# Managed Node Group using Launch Template
module "eks_node_groups" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.26.0"

  cluster_name = local.cluster_name
  cluster_version = "1.32"

  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnets

  eks_managed_node_groups = {
    one = {
      name = "eks-node-group-1"

      # Attach Launch Template with gp3 root volume
      launch_template {
        id      = aws_launch_template.eks_nodes.id
        version = "$Latest"
      }

      min_size     = 1
      max_size     = 5
      desired_size = var.worker_nodes_desired_size

      # IAM Role for the Node Group
      node_role_arn = aws_iam_role.eks_node_group.arn

      metadata_options = {
        http_endpoint          = "enabled"
        http_tokens            = "required"
        instance_metadata_tags = "enabled"
      }
    }
  }
}
