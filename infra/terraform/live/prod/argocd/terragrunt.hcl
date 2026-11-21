include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path = "${get_terragrunt_dir()}/../../_env/argocd.hcl"
}

terraform {
  source = "../../../modules/argocd"
}

dependency "kubernetes" {
  config_path = "../kubernetes"

  # Skip fetching real outputs - the prod kubernetes cluster doesn't exist yet.
  # This forces Terragrunt to use mock_outputs for all commands.
  # TODO: Remove this once the prod kubernetes cluster is deployed.
  skip_outputs = true

  mock_outputs = {
    cluster_id             = "mock-id"
    endpoint               = "https://mock-endpoint"
    cluster_token          = "mock-token"
    # base64 PEM of a throwaway self-signed cert: kubernetes provider v3 rejects non-PEM values
    cluster_ca_certificate = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJpakNDQVRHZ0F3SUJBZ0lVQWRLREpBSm1OUlFPckFwZFpTMEdDNEdOa2pnd0NnWUlLb1pJemowRUF3SXcKR2pFWU1CWUdBMVVFQXd3UGJXOWpheTFqYkhWemRHVnlMV05oTUNBWERUSTJNVEV5TURFNU16TTBNbG9ZRHpJeApNall4TURJM01Ua3pNelF5V2pBYU1SZ3dGZ1lEVlFRRERBOXRiMk5yTFdOc2RYTjBaWEl0WTJFd1dUQVRCZ2NxCmhrak9QUUlCQmdncWhrak9QUU1CQndOQ0FBU25wSktURzQvQzBaTmJlNXZGUG95Tkc2Z09lMnV4OWtFZW1YU1UKTzFYRjc1MXlSUUgvT1ZyOUV6YnMrME8yZ0JxOGZOUFdIUnRLOUM1TVJCdThBZVp5bzFNd1VUQWRCZ05WSFE0RQpGZ1FVUlh5MExkbHArZlV4UmdIaExxRzVVTXdWamw0d0h3WURWUjBqQkJnd0ZvQVVSWHkwTGRscCtmVXhSZ0hoCkxxRzVVTXdWamw0d0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBS0JnZ3Foa2pPUFFRREFnTkhBREJFQWlBMGV6QTkKK1BZbXVQc1lrQllkdFYyRUtKS1hvaDFuS1U4anFTY1V5dTJwOXdJZ2M3YzNlZjN3blJ3RWNqWHB1Y1BCNUVkZgpoUDRPRnJ0by9vc3hHNVpEcFhjPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

generate "provider_k8s" {
  path      = "provider_k8s.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "kubernetes" {
  host                   = "${dependency.kubernetes.outputs.endpoint}"
  token                  = "${dependency.kubernetes.outputs.cluster_token}"
  cluster_ca_certificate = base64decode("${dependency.kubernetes.outputs.cluster_ca_certificate}")
}

provider "helm" {
  kubernetes = {
    host                   = "${dependency.kubernetes.outputs.endpoint}"
    token                  = "${dependency.kubernetes.outputs.cluster_token}"
    cluster_ca_certificate = base64decode("${dependency.kubernetes.outputs.cluster_ca_certificate}")
  }
}
EOF
}
