include {
  path = find_in_parent_folders()
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  name        = "processed-files-s3-policy"

}

terraform {
  source = "../../../..//modules/terraform-aws-iam/modules/iam-policy"
}

inputs = {
  name = "${local.common_vars.namespace}-${local.common_vars.environment}-${local.name}"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "${dependency.s3.outputs.s3_bucket_arn}",
          "${dependency.s3.outputs.s3_bucket_arn}/*"
        ]
      }
    ]
  })
  tags = local.common_vars.tags
}

dependency "s3" {
  config_path = "../../../s3/processed_files"
}