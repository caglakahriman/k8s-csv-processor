include {
  path = find_in_parent_folders()
}

locals {
  common_vars                  = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  region                       = local.common_vars.region
  cluster_name                 = "eks"
  cluster_version              = local.common_vars.eks_version
  instance_types               = ["${local.common_vars.eks_instance_type}"]

  enable_bootstrap_user_data                 = true
  iam_role_attach_cni_policy                 = false
  cluster_endpoint_public_access             = false
  attach_cluster_primary_security_group      = true
  create_cluster_primary_security_group_tags = true
  create_cluster_security_group              = false
  create_kms_key                             = true
  attach_cluster_encryption_policy           = true
  desired_size_1_a                           = 2
  min_size_1_a                               = 1
  desired_size_1_b                           = 2
  min_size_1_b                               = 1
  max_size                                   = 4

  create_readonly_clusterrole = true
  manage_aws_auth_configmap   = true
}

terraform {
  source = "../..//modules/terraform-aws-eks-cluster"
}

inputs = {
  aws_profile       = "${local.common_vars.namespace}-${local.common_vars.environment}"
  cluster_name      = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.cluster_name}"
  cluster_version   = local.cluster_version
  vpc_id            = local.common_vars.vpc_id
  subnet_ids        = local.common_vars.subnet_ids

  eks_managed_node_groups = {
    node_group_1_a = {
      name           = "${local.common_vars.namespace}-${local.common_vars.environment}"
      subnet_ids     = [local.common_vars.subnet_ids[0]]
      instance_types = local.instance_types
      capacity_type  = "ON_DEMAND"
      desired_size   = local.desired_size_1_a
      min_size       = local.min_size_1_a
      max_size       = local.max_size
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            encrypted             = false
            delete_on_termination = true
          }
        }
      }
      attach_cluster_primary_security_group = local.attach_cluster_primary_security_group
      enable_bootstrap_user_data            = local.enable_bootstrap_user_data
      iam_role_additional_policies = {
        AmazonEKS_CNI_Policy         = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEFSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        AmazonS3FullAccess           = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
      }

      iam_role_name              = "${local.common_vars.namespace}-${local.common_vars.environment}"
      iam_role_attach_cni_policy = local.iam_role_attach_cni_policy
    }
    node_group_1_b = {
      name           = "${local.common_vars.namespace}-${local.common_vars.environment}"
      subnet_ids     = [local.common_vars.subnet_ids[1]]
      instance_types = local.instance_types
      capacity_type  = "SPOT"
      desired_size   = local.desired_size_1_b
      min_size       = local.min_size_1_b
      max_size       = local.max_size
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            encrypted             = false
            delete_on_termination = true
          }
        }
      }
      attach_cluster_primary_security_group = local.attach_cluster_primary_security_group
      enable_bootstrap_user_data            = local.enable_bootstrap_user_data
      iam_role_additional_policies = {
        AmazonEKS_CNI_Policy         = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEFSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        AmazonS3FullAccess           = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
      }

      iam_role_name              = "${local.common_vars.namespace}-${local.common_vars.environment}"
      iam_role_attach_cni_policy = local.iam_role_attach_cni_policy
    }
  }

  node_security_group_additional_rules = {
    ingress_cluster_15017 = {
      description                   = "Cluster API to node groups"
      protocol                      = "tcp"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  cluster_security_group_id                  = dependency.sg_eks.outputs.this_security_group_id
  create_cluster_primary_security_group_tags = local.create_cluster_primary_security_group_tags
  create_cluster_security_group              = local.create_cluster_security_group
  cluster_endpoint_public_access             = local.cluster_endpoint_public_access

  create_kms_key                   = local.create_kms_key
  attach_cluster_encryption_policy = local.attach_cluster_encryption_policy
  kms_key_owners                   = ["arn:aws:iam::${local.common_vars.account_id}:role/eks-admin"]
  cluster_encryption_config = {
    "resources" : ["secrets"]
  }
  kms_key_description           = "KMS Secrets encryption for EKS cluster"
  kms_key_enable_default_policy = true

  create_readonly_clusterrole = local.create_readonly_clusterrole
  manage_aws_auth_configmap   = local.manage_aws_auth_configmap
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${local.common_vars.account_id}:user/${local.common_vars.eks_iam_user}"
      username = "${local.common_vars.eks_iam_user_name}"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${local.common_vars.account_id}:role/eks-admin"
      username = "${local.common_vars.eks_admin_username}"
      groups = [
        "system:masters",
      ]
    }
  ]

  cluster_addons = {
    kube-proxy = {
      addon_version = local.common_vars.eks_addon_versions.kube_proxy
    }

    vpc-cni = {
      addon_version = local.common_vars.eks_addon_versions.vpc_cni
    }

    coredns = {
      addon_version = local.common_vars.eks_addon_versions.coredns
      configuration_values = jsonencode({
        corefile = <<-EOT
        .:53 {
            errors
            health {
                lameduck 5s
              }
            ready
            kubernetes cluster.local in-addr.arpa ip6.arpa {
              pods insecure
              fallthrough in-addr.arpa ip6.arpa
            }
            prometheus :9153
            forward . /etc/resolv.conf
            cache 30
            loop
            reload
            loadbalance
        }
    EOT
      })
    }

    aws-ebs-csi-driver = {
      addon_version = local.common_vars.eks_addon_versions.ebs_csi_driver
    }
  }

  node_security_group_tags = {
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "k8s.io/cluster-autoscaler/${local.common_vars.namespace}-${local.common_vars.environment}-${local.cluster_name}" = "owned"
  }

  tags = local.common_vars.tags
}

dependency "sg_eks" {
  config_path = "../sg/eks"
}