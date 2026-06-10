# task-manager-infra

AWS infrastructure and Helm charts for the Task Manager application. Manages an EKS cluster, RDS PostgreSQL, VPC, ACM certificate, Route53 DNS, ECR repos, and cluster add-ons.

## What's inside

```
terraform/           Main infrastructure (EKS, RDS, VPC, ECR, IAM, S3, Route53, ACM)
terraform/bootstrap  GitHub OIDC provider + GitHub Actions IAM role
terraform-sonarqube/ Standalone SonarQube on EC2 (separate state, never destroyed with main infra)
helm/task-manager/   Helm chart shared by backend and frontend deployments
```

## Environments

| | prod | dev |
|---|---|---|
| URL | https://prod.oybek.xyz | https://dev.oybek.xyz |
| Branch | `main` | `dev` |
| Replicas | 2 (HPA: 2–6) | 1 |
| Database | `taskmanager` | `taskmanager_dev` |

Both environments share one RDS instance and one EKS cluster, separated by Kubernetes namespaces.

## CI/CD

- **Push to `main`** — `terraform apply` + installs cluster add-ons + creates K8s db-secrets
- **Pull request** — `terraform plan` only, no changes applied
- **Destroy** — trigger manually via `workflow_dispatch` → select `destroy`. Helm releases are deleted first so the ALB is gone before Terraform removes the VPC.

## Cluster add-ons

| Add-on | Purpose |
|---|---|
| AWS Load Balancer Controller | Creates ALB from Ingress resources |
| external-dns | Keeps Route53 records in sync with Ingress hostnames |
| Cluster Autoscaler | Scales EC2 nodes 1–3 × t3.medium |
| Fluent Bit | Ships pod logs to CloudWatch (`/aws/eks/task-manager/app`) |
| Velero | Cluster backups to S3 (`task-manager-velero-backups`) |

## Prerequisites

- AWS CLI configured
- `terraform`, `kubectl`, `helm` installed
- S3 bucket `task-manager-tfstate-infra` already exists (created once manually)

## Manual deploy

```bash
# First time only — creates GitHub Actions IAM role
cd terraform/bootstrap
terraform init && terraform apply

# Main infra
cd terraform
terraform init
terraform apply -var-file=terraform.tfvars
```

## SonarQube

Runs on a separate EC2 (t3.large) managed by `terraform-sonarqube/`. Has `prevent_destroy = true` and is never touched by the main infra workflow.

```bash
cd terraform-sonarqube
terraform init && terraform apply
```

Credentials are stored automatically in SSM: `/task-manager/sonarqube-token`, `/task-manager/sonarqube-url`.

## Monitoring

- **Logs** — CloudWatch → `/aws/eks/task-manager/app`
- **Nodes** — EKS console → task-manager-eks → Compute
- **SonarQube URL** — SSM → `/task-manager/sonarqube-url`
