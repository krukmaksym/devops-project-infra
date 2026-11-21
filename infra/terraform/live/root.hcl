locals {
  # Terraform state lives in a DigitalOcean Spaces bucket (S3-compatible API).
  # The bucket is created once by hand (with versioning enabled) and is not
  # managed by Terraform. Credentials come from Doppler as AWS_ACCESS_KEY_ID /
  # AWS_SECRET_ACCESS_KEY (a Spaces access key scoped to this bucket only).
  state_bucket = "devops-project-infra-tf-state"
  state_region = "fra1"
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket = "${local.state_bucket}"
    key    = "${path_relative_to_include()}/terraform.tfstate"

    # Spaces is S3-compatible but not AWS: point at the Spaces endpoint and
    # skip AWS-only checks. "region" is required by the backend but unused.
    endpoints                   = { s3 = "https://${local.state_region}.digitaloceanspaces.com" }
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true

    # Native S3 state locking (lock object next to the state file).
    use_lockfile = true
  }
}
EOF
}
