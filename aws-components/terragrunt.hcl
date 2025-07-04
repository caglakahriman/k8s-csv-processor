generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "us-east-1"
  profile = "playground-test"
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket  = "playground-test-terragrunt-state"
    key     = "test/${path_relative_to_include()}/terraform.tfstate"
    region  = "us-east-1"
    profile = "playground-test"
  }
}
