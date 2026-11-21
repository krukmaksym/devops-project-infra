# Project guardrails

DevOps portfolio infrastructure on DigitalOcean: Terragrunt + Terraform (DOKS, VPC, ArgoCD), GitOps via ArgoCD.

## Secrets
- No secrets in HCL, and no `default` values for sensitive variables.
- All secrets live in Doppler. Run Terragrunt through `scripts/doppler-tf.sh` (or `make`), never with plain `doppler run`. The wrapper explains why.
- GitHub Actions only stores `DOPPLER_TOKEN`.

## State & safety
- State lives in the DigitalOcean Spaces S3 backend, managed in `infra/terraform/live/root.hcl` (`use_lockfile = true`). Don't add other backends.
- Environments are intentionally torn down. Never run `apply`/`destroy` (locally or via workflows) unless explicitly asked.
- Deploys are manual-only (`workflow_dispatch`); `prod` requires environment approval. Don't add push-triggered applies.

## Terraform / Terragrunt
- Environment-specific config goes in `live/_env/*.hcl`; per-stack `terragrunt.hcl` files only wire dependencies.
- Commit `.terraform.lock.hcl` for every stack when providers change.
- Kubernetes version stays consistent across envs (currently `1.37.2-do.0`).
- Node pools: `monitoring` is tainted `service=monitoring:NoSchedule`; the app pool stays untainted (system pods); node pools use `create_before_destroy = true`.

## GitOps
- New workloads go in `gitops/` as ArgoCD `Application` manifests, not as Terraform `helm_release`.
- ArgoCD is reached via `kubectl port-forward` (ClusterIP); a LoadBalancer requires TLS + `lb_source_ranges`.

## CI
- Pin third-party GitHub Actions to full commit SHAs (Dependabot keeps them current).
- Pass untrusted values to scripts via `env:`, never `${{ }}` interpolation.
