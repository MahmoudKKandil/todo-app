# Modified by: William Paul Liggett of junktext LLC

# Original Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region
}

# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  #cluster_name = "education-eks-${random_string.suffix.result}"
  cluster_name = "todo-app-eks-${random_string.suffix.result}"
  desired_size = 1 # How many EKS managed nodes are desired.
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  #name = "education-vpc"
  name = "todo-app-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name = local.cluster_name
  #cluster_version = "1.27"
  cluster_version = "1.29"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    # junktext: As of 2024-01-29, the newer Amazon Linux 2023 (AL2023 which deprecates AL2) is NOT yet available for an EKS managed node instance. 
    # See: https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      # Prices updated as of 2024-03-18. Only included next, cheapest type by hardware capability.
      # +-----------------------------+
      # | CPU Architecture: x86-based |
      # +-----------------------------+
      # EC2 Type:  Max Pods | vCPU |  RAM   | On-Demand Hourly
      # ---------------------------------------------------------------------------------------------------
      # t2.micro          4 |    1 |  1 GiB | $0.0116 [Do NOT use! EKS needs 7 pods by itself.]
      # t3a.medium       17 |    2 |  4 GiB | $0.0376 [Same notes, but more expensive than: t4g.medium]
      # t3.medium        17 |    2 |  4 GiB | $0.0416 [Same notes, but more expensive than: t3a.medium]
      # t3a.large        35 |    2 |  8 GiB | $0.0752 [Exactly twice as costly as: t3a.medium]
      #
      # +-----------------------+
      # | CPU Architecture: ARM |
      # +-----------------------+
      # EC2 Type:  Max Pods | vCPU |  RAM   | On-Demand Hourly
      # ---------------------------------------------------------------------------------------------------
      # t4g.small        11 |    2 |  2 GiB | $0.0168 [Can't use with Flux, else no pods left.]
      # t4g.medium       17 |    2 |  4 GiB | $0.0336 [With Metrics, Flux, & Gitlab: Only 1-2 pods left.]
      # t4g.large        35 |    2 |  8 GiB | $0.0672 [Exactly twice as costly as: t4g.medium]
      # c6g.large        29 |    2 |  4 GiB | $0.068  [More expensive with less # of pods than: t4g.large]
      instance_types = ["t3a.large"]

      min_size = 1
      max_size = 3
      #desired_size = 2
      desired_size = local.desired_size
    }

    /*
    # Example of how to create another EKS node group with a different size.
    two = {
      name = "node-group-2"

      instance_types = ["t3.large"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
    */
  }
}

# Allows us to use TF to modify the `desired_size` of the EKS managed node group later.
# Normally, we can't do this because of how EKS managed node groups are typically scaled in/out which
# uses non-TF ways of doing so.
# https://github.com/bryantbiggs/eks-desired-size-hack
# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1879
resource "null_resource" "update_desired_size" {
  triggers = {
    desired_size = local.desired_size
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    # Note: this requires the awscli to be installed locally where Terraform is executed
    command = <<-EOT
      aws eks update-nodegroup-config \
        --cluster-name ${module.eks.cluster_name} \
        --nodegroup-name ${element(split(":", module.eks.eks_managed_node_groups["one"].node_group_id), 1)} \
        --scaling-config desiredSize=${local.desired_size}
    EOT
  }
}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.7.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.20.0-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
}
