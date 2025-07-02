include {
  path = find_in_parent_folders()
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  name        = "processed-files-s3-role"
}

terraform {
  source = "../../../..//modules/terraform-aws-iam/modules/iam-assumable-role-with-oidc"
}

inputs = {
  role_name         = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.name}"
  role_requires_mfa = false
  create_role       = true
  provider_url      = dependency.eks.outputs.cluster_oidc_issuer_url
  provider_urls     = [dependency.eks.outputs.cluster_oidc_issuer_url]
  role_policy_arns  = [dependency.policy.outputs.arn]

  oidc_fully_qualified_subjects  = ["system:serviceaccount:default:csv-processor-sa"]
  oidc_fully_qualified_audiences = ["sts.amazonaws.com"]

  tags = local.common_vars.tags
}

dependency "policy" {
  config_path = "../../policies/processed-files-s3"
}

dependency "eks" {
  config_path = "../../../eks"
}