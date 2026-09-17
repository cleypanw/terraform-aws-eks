locals {
  # Kubernetes version of the control plane and of the managed node groups.
  # Also used to resolve the matching EKS add-on versions (see eks-ebs-csi.tf).
  kubernetes_version = "1.36"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.25.0"

  name               = local.cluster_name
  kubernetes_version = local.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_private_access = true
  endpoint_public_access  = false

  # Add ec2-bastion security group to allow connecting to the cluster control plane
  additional_security_group_ids = [aws_security_group.ec2-bastion.id]

  enable_cluster_creator_admin_permissions = true

  # Managed Node Groups
  # `eks_managed_node_group_defaults` was removed in v21; settings go directly
  # on each node group (ami_type already defaults to AL2023_x86_64_STANDARD).
  eks_managed_node_groups = {
    one = {
      name           = "eks-node-group-1"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.worker_nodes_type]
      min_size       = 1
      max_size       = 5
      desired_size   = var.worker_nodes_desired_size

      metadata_options = {
        http_endpoint          = "enabled"
        http_tokens            = "required"
        instance_metadata_tags = "enabled"
        # v21 defaults this to 1, which prevents pods on the pod network from
        # reaching IMDS. Kept at 2 to preserve the behaviour of the v20 lab.
        http_put_response_hop_limit = 2
      }

      # Root volume of the worker nodes. This must sit directly on the node
      # group and be a map (a list is rejected). Do NOT wrap it in a
      # `launch_template = { ... }` block: that key does not exist, and because
      # Terraform drops unknown attributes when converting to an object type,
      # `terraform validate` stays green while the nodes silently fall back to
      # the AMI's default root volume. That was the case here until now.
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3" # <-- gp3 root volume
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
    }
  }
}
