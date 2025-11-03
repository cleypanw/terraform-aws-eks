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

  eks_managed_node_group_defaults = {
    ami_type  = "AL2023_x86_64"
    disk_size = 20
    disk_type = "gp3"
    encrypted = true
  }

  eks_managed_node_groups = {
    one = {
      name           = "eks-node-group-1"
      min_size       = 1
      max_size       = 5
      desired_size   = var.worker_nodes_desired_size
      instance_types = [var.worker_nodes_type]

      # Attach Launch Template
      launch_template = {
        id      = aws_launch_template.eks_nodes.id
        version = "$Latest"
      }

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
