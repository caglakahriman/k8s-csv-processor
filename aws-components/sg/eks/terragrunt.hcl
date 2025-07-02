# Check this

include {
  path = find_in_parent_folders()
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  name        = "eks"
}

terraform {
  source = "../../..//modules/terraform-aws-security-group"
}

inputs = {
  name            = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.name}"
  description     = "Security group for EKS"
  vpc_id          = local.common_vars.vpc_id
  use_name_prefix = false
  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "TCP"
      description = "EKS Cluster Access from cluster 1a subnet"
      cidr_blocks = local.common_vars.subnet_cidr_blocks[0]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "TCP"
      description = "EKS Cluster Access from cluster 1b subnet"
      cidr_blocks = local.common_vars.subnet_cidr_blocks[1]
    },
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "TCP"
      description = "Kubelet API"
      cidr_blocks = [local.common_vars.vpc_cidr_block] # entire VPC
    },
    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "TCP"
      description = "NodePort Services"
      cidr_blocks = [local.common_vars.vpc_cidr_block]
    },
    {
      from_port                     = 15017
      to_port                       = 15017
      protocol                      = "TCP"
      description                   = "Cluster Autoscaler"
      source_cluster_security_group = true
    },
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "TCP"
      description = "NFS for EFS"
      cidr_blocks = [local.common_vars.vpc_cidr_block]
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound connections"
    }
  ]
  tags = local.common_vars.tags
}
