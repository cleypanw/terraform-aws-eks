module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.32"

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  # Add ec2-bastion security group to allow connecting to the cluster control plane
  cluster_additional_security_group_ids = [aws_security_group.ec2-bastion.id]

  enable_cluster_creator_admin_permissions = true

  # Default configuration for Managed Node Groups
  eks_managed_node_group_defaults = {
    ami_type = "AL2023_x86_64"  # <-- Updated to AL2023
  }

  # Managed Node Groups
  eks_managed_node_groups = {
    one = {
      name           = "eks-node-group-1"
      instance_types = [var.worker_nodes_type]
      min_size       = 1
      max_size       = 5
      desired_size   = var.worker_nodes_desired_size

      metadata_options = {
        http_endpoint          = "enabled"
        http_tokens            = "required"
        instance_metadata_tags = "enabled"
      }

      # Use gp3 for EBS root volume
      launch_template = {
        # Create an inline launch template
        block_device_mappings = [
          {
            device_name = "/dev/xvda"
            ebs = {
              volume_size = 20
              volume_type = "gp3"   # <-- gp3 root volume
              encrypted   = true
            }
          }
        ]
      }
    }
  }
}