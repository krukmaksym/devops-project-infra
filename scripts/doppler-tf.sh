#!/usr/bin/env bash
# Run a command (usually terragrunt) with secrets from Doppler.
#
#   scripts/doppler-tf.sh terragrunt plan
#
# Why this wrapper exists:
# - Doppler secret names are always UPPERCASE (DO_TOKEN), but Terraform reads an
#   input variable `do_token` only from TF_VAR_do_token (exact, lowercase name).
#   `--name-transformer tf-var` does that rename for every secret.
# - The rename also turns the Spaces state-backend keys into TF_VAR_aws_*, while
#   the S3 backend only reads AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY.
#   So those two are mapped back below.
set -euo pipefail

exec doppler run --name-transformer tf-var -- sh -c '
  export AWS_ACCESS_KEY_ID="${TF_VAR_aws_access_key_id:-}"
  export AWS_SECRET_ACCESS_KEY="${TF_VAR_aws_secret_access_key:-}"
  exec "$@"
' doppler-tf "$@"
