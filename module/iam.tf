locals {
  cluster_name = var.cluster-name
}

resource "random_integer" "random_suffix" {
  min = 1000
  max = 9999
}

# This role is used by the EKS control plane to create and manage AWS resources by assuming the specified role.
resource "aws_iam_role" "eks-cluster-role" {
  count = var.is_eks_role_enabled ? 1 : 0

  name = "${local.cluster_name}-role-${random_integer.random_suffix.result}"
  # Vuit in json encder terraform function to convert the policy to a JSON string.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  count = var.is_eks_role_enabled ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

  role = aws_iam_role.eks-cluster-role[count.index].name
}

# This role is used by the EKS worker node group to interact with AWS services by assuming the specified role.
resource "aws_iam_role" "eks-nodegroup-role" {
  count = var.is_eks_nodegroup_role_enabled ? 1 : 0
  name  = "nodegroup-role-${random_integer.random_suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks-AmazonWorkerNodePolicy" {
  count = var.is_eks_nodegroup_role_enabled ? 1 : 0

  #   Attach the **AmazonEKSWorkerNodePolicy** to your worker nodes.

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-nodegroup-role[count.index].name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  count = var.is_eks_nodegroup_role_enabled ? 1 : 0

  #   Attach the **AmazonEKS_CNI_Policy** to your worker nodes

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-nodegroup-role[count.index].name
}


resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  count = var.is_eks_nodegroup_role_enabled ? 1 : 0

  # Attach the AmazonEC2ContainerRegistryReadOnly policy to worker nodes.

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-nodegroup-role[count.index].name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEBSCSIDriverPolicy" {
  count = var.is_eks_nodegroup_role_enabled ? 1 : 0

  # Attach the AmazonEBSCSIDriverPolicy policy to worker nodes.

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks-nodegroup-role[count.index].name
}

# OIDC
resource "aws_iam_role" "eks_oidc" {
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role_policy.json
  name               = "eks-oidc"
}

# The pod that you create using the service account will have the permissions defined in the attached policy to list s3 buckets.
resource "aws_iam_policy" "eks-oidc-policy" {
  name = "test-policy"

  policy = jsonencode({
    Statement = [{
      Action = [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation",
        "*"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

# S3 policy to the OIDC role.

resource "aws_iam_role_policy_attachment" "eks-oidc-policy-attach" {
  role       = aws_iam_role.eks_oidc.name
  policy_arn = aws_iam_policy.eks-oidc-policy.arn
}
