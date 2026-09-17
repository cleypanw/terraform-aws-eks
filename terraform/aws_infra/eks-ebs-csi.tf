# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/
# IRSA role for the EBS CSI controller.
# `iam-assumable-role-with-oidc` was removed in terraform-aws-iam v6; the
# `iam-role-for-service-accounts` sub-module replaces it and ships the
# AmazonEBSCSIDriverPolicy behind `attach_ebs_csi_policy`.
module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.8.1"

  name = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# https://docs.aws.amazon.com/eks/latest/userguide/creating-an-add-on.html
# Resolve the add-on version matching the cluster's Kubernetes version instead
# of hardcoding it, so bumping local.kubernetes_version is enough.
data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = local.kubernetes_version
  most_recent        = true
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.ebs_csi.version
  service_account_role_arn = module.irsa-ebs-csi.arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
}
