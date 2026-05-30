# Task Manager — Infrastructure

Production-grade Kubernetes infrastructure on AWS EKS for a FastAPI + React task management application. Two isolated environments (prod/dev) with full CI/CD, TLS, autoscaling, logging, and code quality gates.

---

## Architecture

```
                          ┌─────────────────────────────────────────┐
                          │              GitHub Actions               │
                          │  ┌──────────┐  ┌────────┐  ┌─────────┐  │
                          │  │ hadolint │  │ Trivy  │  │Sonarube │  │
                          │  └──────────┘  └────────┘  └─────────┘  │
                          └────────────────────┬────────────────────┘
                                               │ push image
                                               ▼
                                    ┌──────────────────┐
                                    │   Amazon ECR      │
                                    │ task-manager-*    │
                                    └────────┬─────────┘
                                             │ helm deploy
                          ┌──────────────────▼──────────────────────┐
                          │            AWS EKS Cluster               │
                          │                                          │
                          │  ┌─────────────────────────────────┐    │
                          │  │         kube-system              │    │
                          │  │  AWS LBC · external-dns          │    │
                          │  │  Cluster Autoscaler · Fluent Bit │    │
                          │  └─────────────────────────────────┘    │
                          │                                          │
                          │  ┌──────────────┐  ┌────────────────┐   │
                          │  │ prod (EC2)   │  │  dev (Fargate) │   │
                          │  │ 2× frontend  │  │  1× frontend   │   │
                          │  │ 2× backend   │  │  1× backend    │   │
                          │  └──────┬───────┘  └───────┬────────┘   │
                          └─────────┼──────────────────┼────────────┘
                                    │                  │
                          ┌─────────▼──────────────────▼────────────┐
                          │         Application Load Balancer        │
                          │     HTTP → HTTPS redirect (ACM cert)     │
                          └─────────────────┬────────────────────────┘
                                            │
                          ┌─────────────────▼────────────────────────┐
                          │               Route 53                    │
                          │  prod.oybek.xyz · dev.oybek.xyz           │
                          └──────────────────────────────────────────┘

  ┌─────────────────────┐    ┌──────────────────────┐
  │   RDS PostgreSQL     │    │  CloudWatch Logs      │
  │  taskmanager (prod)  │    │  /aws/eks/task-manager│
  │  taskmanager_dev     │    │  /app                 │
  └─────────────────────┘    └──────────────────────┘

  ┌──────────────────────────────────────────────────┐
  │  SonarQube EC2 (t3.large, separate Terraform)    │
  │  http://54.221.157.143:9000                      │
  │  Credentials auto-stored in SSM Parameter Store  │
  └──────────────────────────────────────────────────┘
```

---

## Stack

| Layer | Technology |
|-------|-----------|
| Cloud | AWS (EKS, RDS, ECR, ALB, ACM, Route53, CloudWatch) |
| Container orchestration | Kubernetes (EKS) |
| Infrastructure as Code | Terraform 1.10 |
| Package manager | Helm |
| CI/CD | GitHub Actions |
| Code quality | SonarQube, hadolint, Trivy |
| DNS | Route53 + external-dns |
| TLS | ACM wildcard certificate (`*.oybek.xyz`) |
| Logging | Fluent Bit DaemonSet → CloudWatch Logs |
| Autoscaling | Cluster Autoscaler (prod EC2 nodes) |

---

## Repository Structure

```
task-manager-infra/
├── terraform/                  # Main infrastructure
│   ├── vpc.tf                  # VPC, subnets, NAT gateway
│   ├── eks.tf                  # EKS cluster, node groups, Fargate
│   ├── rds.tf                  # RDS PostgreSQL
│   ├── ecr.tf                  # ECR repositories
│   ├── acm.tf                  # ACM certificate + DNS validation
│   ├── alb.tf                  # LBC IRSA role (EKS OIDC)
│   ├── ca.tf                   # Cluster Autoscaler IRSA role
│   ├── cloudwatch.tf           # CloudWatch log group + node IAM
│   ├── github-oidc.tf          # GitHub Actions OIDC federation
│   └── lbc-policy.json         # AWS Load Balancer Controller policy
├── terraform-sonarqube/        # SonarQube EC2 (separate state)
│   ├── main.tf                 # VPC + AMI data sources
│   ├── sonarqube.tf            # EC2, IAM, EIP, auto-setup script
│   └── backend.tf              # S3 state: sonarqube/terraform.tfstate
├── helm/task-manager/          # Helm chart (shared by frontend & backend)
│   ├── templates/
│   │   ├── frontend.yaml       # Deployment + ClusterIP Service
│   │   ├── backend.yaml        # Deployment + ClusterIP Service
│   │   ├── ingress.yaml        # ALB Ingress (when frontend.enabled)
│   │   └── db-init-job.yaml    # Creates DB on first Helm install
│   ├── values.yaml             # Defaults
│   ├── values-prod.yaml        # Prod overrides (2 replicas, EC2 nodes)
│   └── values-dev.yaml         # Dev overrides (1 replica, Fargate)
└── .github/workflows/
    ├── ci.yml                  # Lint → Plan → Apply → Helm installs
    ├── destroy.yml             # Manual tear-down
    └── sonarqube.yml           # SonarQube EC2 deploy (separate)
```

---

## Environments

| | prod | dev |
|-|------|-----|
| URL | `https://prod.oybek.xyz` | `https://dev.oybek.xyz` |
| Branch | `main` | `dev` |
| Compute | EC2 `t3.medium` (autoscaled 1–3) | AWS Fargate |
| Replicas | 2 | 1 |
| Database | `taskmanager` | `taskmanager_dev` |
| Node selector | `environment: prod` | — |

---

## CI/CD Pipeline

### Infra pipeline (`ci.yml`)

```
push to main
    └── lint (terraform fmt + tflint)
         └── apply
              ├── Bootstrap ACM certificate (-target)
              ├── Import existing GitHub OIDC resources
              ├── terraform apply (full)
              ├── Configure kubectl
              ├── Install: external-dns
              ├── Install: Cluster Autoscaler
              ├── Install: Fluent Bit
              ├── Install: AWS Load Balancer Controller
              ├── Wait for LBC ready
              └── Create namespaces + db-secrets
```

### App pipeline (frontend / backend)

```
push to main or dev
    ├── hadolint       — Dockerfile linting
    ├── SonarQube      — code quality scan (reads from SSM)
    ├── Trivy          — container vulnerability scan
    └── push to ECR
         ├── main → helm deploy to prod namespace
         └── dev  → helm deploy to dev namespace
```

---

## Terraform State

| State | S3 Key | Contains |
|-------|--------|----------|
| Main infra | `terraform.tfstate` | EKS, RDS, VPC, ACM, IAM |
| SonarQube | `sonarqube/terraform.tfstate` | EC2, EIP, VPC |

Both stored in S3 bucket: `task-manager-tfstate-infra`

---

## Deployment

### Prerequisites
- AWS CLI configured
- Terraform 1.10+
- kubectl + Helm

### First-time deploy
```bash
# Deploy main infrastructure
cd terraform
terraform init
terraform apply -target=aws_acm_certificate.main -auto-approve
terraform apply -auto-approve

# Deploy SonarQube (separate state, never destroyed with main infra)
cd ../terraform-sonarqube
terraform init
terraform apply -auto-approve
```

### Destroy
Trigger the **Terraform Destroy** workflow manually in GitHub Actions.
SonarQube is protected with `prevent_destroy = true` and will not be affected.

---

## Monitoring

- **Logs**: AWS CloudWatch → Log groups → `/aws/eks/task-manager/app`
- **Code quality**: SonarQube at `http://54.221.157.143:9000`
- **Autoscaling**: EKS → task-manager-eks → Compute → task-manager-prod-nodes
