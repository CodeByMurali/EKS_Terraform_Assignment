resource "aws_eks_cluster" "eks" {

  # conditionally creates the resource based on whether var.is-eks-cluster-enabled is true. If true, one instance is created; otherwise, none.
  count    = var.is-eks-cluster-enabled == true ? 1 : 0
  name     = var.cluster-name
  role_arn = aws_iam_role.eks-cluster-role[count.index].arn
  version  = var.cluster-version

  vpc_config {

    # The EKS resources will be deployed within these private subnets
    subnet_ids = [
      aws_subnet.private-subnet[0].id,
      aws_subnet.private-subnet[1].id,
      aws_subnet.private-subnet[2].id
    ]

    endpoint_private_access = var.endpoint-private-access
    endpoint_public_access  = var.endpoint-public-access
    security_group_ids      = [aws_security_group.eks-cluster-sg.id]
  }

  # authentication_mode: Specifies the mode of authentication. 
  #   - "CONFIG_MAP": Uses a Kubernetes ConfigMap for authentication.
  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Needed to explicity define the depends_on argument to ensure that the EKS cluster is created 
  # after the IAM role policy attachment for the EKS cluster policy is created.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
  ]

  tags = {
    Name = var.cluster-name
    Env  = var.env
  }
}

# TLS certificates ensure that the communication between the Kubernetes control plane and the worker nodes is secure.
resource "aws_iam_openid_connect_provider" "eks-oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks-certificate.certificates[0].sha1_fingerprint]

  url = data.tls_certificate.eks-certificate.url
}

# AddOns for EKS Cluster
resource "aws_eks_addon" "eks-addons" {
  for_each      = { for idx, addon in var.addons : idx => addon }
  cluster_name  = aws_eks_cluster.eks[0].name
  addon_name    = each.value.name
  addon_version = each.value.version

  depends_on = [
    aws_eks_node_group.ondemand-node,
    aws_eks_node_group.spot-node
  ]
}

# NodeGroups

resource "aws_eks_node_group" "ondemand-node" {
  cluster_name    = aws_eks_cluster.eks[0].name
  node_group_name = "${var.cluster-name}-on-demand-nodes"

  node_role_arn = aws_iam_role.eks-nodegroup-role[0].arn

  scaling_config {
    desired_size = var.desired_capacity_on_demand
    min_size     = var.min_capacity_on_demand
    max_size     = var.max_capacity_on_demand
  }

  # The worker nodes will be deployed in the private subnets
  # The public subnets are used for the bastion host, NAT gateway and the load balancer.
  subnet_ids = [
    aws_subnet.private-subnet[0].id,
    aws_subnet.private-subnet[1].id,
    aws_subnet.private-subnet[2].id
  ]

  # default is set to t3a.medium
  instance_types = var.ondemand_instance_types
  capacity_type  = "ON_DEMAND"
  labels = {
    type = "ondemand"
  }
  update_config {
    max_unavailable = 1
  }

  tags = {
    "Name" = "${var.cluster-name}-ondemand-nodes"
  }

  depends_on = [aws_eks_cluster.eks]
}

resource "aws_eks_node_group" "spot-node" {
  cluster_name    = aws_eks_cluster.eks[0].name
  node_group_name = "${var.cluster-name}-spot-nodes"

  node_role_arn = aws_iam_role.eks-nodegroup-role[0].arn

  # EKS will make use of this config to create ASG for the worker nodes.
  scaling_config {
    desired_size = var.desired_capacity_spot
    min_size     = var.min_capacity_spot
    max_size     = var.max_capacity_spot
  }


  subnet_ids = [
    aws_subnet.private-subnet[0].id,
    aws_subnet.private-subnet[1].id,
    aws_subnet.private-subnet[2].id
  ]

  instance_types = var.spot_instance_types
  capacity_type  = "SPOT"

  update_config {
    max_unavailable = 1
  }
  tags = {
    "Name" = "${var.cluster-name}-spot-nodes"
  }
  labels = {
    type      = "spot"
    lifecycle = "spot"
  }
  disk_size = 50

  depends_on = [
    aws_eks_cluster.eks,
    # otherwise EKS will not be able to properly delete EKS managed EC2 infrastructure and ENI.
    aws_iam_role_policy_attachment.eks-AmazonWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly
  ]
}
