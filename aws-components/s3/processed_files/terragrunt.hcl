include {
  path = find_in_parent_folders()
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  name        = "processed-files"
}

terraform {
  source = "../../..//modules/terraform-aws-s3-bucket"
}

inputs = {
  bucket        = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.name}"
  description   = "Bucket to store processed files"

  block_public_acls              = true
  block_public_policy            = true
  ignore_public_acls             = true
  restrict_public_buckets        = true

  versioning = {
    enabled    = true
    mfa_delete = false
  }

  lifecycle_rule = [{
    id      = "transition_to_glacier"
    enabled = true
    transition = [{
      days          = 15
      storage_class = "GLACIER"
    }]
  }]

  tags = local.common_vars.tags
}
