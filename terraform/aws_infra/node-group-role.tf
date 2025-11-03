# node-group-role.tf
# IAM Role for EKS Node Group, with all required policies including EC2 permissions for Launch Templates

resource "aws_iam_role" "eks_node_group" {
  name = "${local.cluster_name}-node-group-role"

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
}

# Attach standard EKS worker node policies
resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Custom inline policy for EC2 permissions required for Launch Template
resource "aws_iam_policy" "eks_node_group_ec2_permissions" {
  name        = "${local.cluster_name}-eks-node-group-ec2"
  description = "EC2 permissions required for EKS Node Group with Launch Template"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:CreateTags",
          "ec2:DescribeKeyPairs"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group_ec2_attach" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = aws_iam_policy.eks_node_group_ec2_permissions.arn
}

# Output the ARN so eks-cluster.tf can reference it
output "eks_node_group_arn" {
  value = aws_iam_role.eks_node_group.arn
}
