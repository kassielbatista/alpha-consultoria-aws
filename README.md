# alpha_k_infra

Reusable, modular Terraform for a highly-available **Amazon EKS** platform on AWS.
This repository provisions the **infrastructure only** — networking, the Kubernetes
cluster, a container registry, monitoring, and CI/CD authentication. Applications are
deployed on top of it separately (each app brings its own namespace and manifests).

## What it provisions

| Module | Resources |
|--------|-----------|
| `vpc` | VPC, public/private subnets across 2 AZs, Internet Gateway, NAT Gateway, route tables, EKS subnet tags |
| `eks` | EKS cluster + managed node group, IAM roles, OIDC/IRSA provider, AWS Load Balancer Controller IAM role, core addons (vpc-cni, coredns, kube-proxy) |
| `ecr` | Private container registry with image scanning and a lifecycle policy |
| `monitoring` | CloudWatch log group, SNS alerts topic, CPU/memory/pod-restart alarms, dashboard |
| `github-oidc` | GitHub Actions OIDC provider + IAM role for keyless CI/CD |
| `bootstrap` | S3 bucket for remote Terraform state (native S3 locking) |

All resources are prefixed with the `project_name` variable, which defaults to **`alpha-k`**
(e.g. `alpha-k-eks`, `alpha-k-vpc`, `alpha-k-app`, `alpha-k-tfstate`).

## Architecture

```
                              ┌────────────────────── AWS Cloud ──────────────────────┐
                              │  VPC (10.0.0.0/16)                                     │
   ┌────────┐                 │   ┌──────────────── Application Load Balancer ─────┐   │
   │ Users  │─────────────────┼──▶│           (provisioned by LB Controller)       │   │
   └────────┘                 │   └────────────────────────┬───────────────────────┘   │
                              │           ┌────────────────┴────────────────┐          │
                              │     ┌──────┴──────┐                   ┌──────┴──────┐   │
                              │     │   AZ-a       │                   │   AZ-b      │   │
                              │     │ public/priv  │                   │ public/priv │   │
                              │     │  EKS node    │                   │  EKS node   │   │
                              │     └──────────────┘                   └─────────────┘   │
                              │   ┌──────┐ ┌──────┐ ┌──────────┐ ┌──────┐                │
                              │   │ EKS  │ │ ECR  │ │CloudWatch│ │ SNS  │                │
                              │   └──────┘ └──────┘ └──────────┘ └──────┘                │
                              └────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.10 (required for native S3 state locking)
- `kubectl` and `helm` (for the Load Balancer Controller)

## Project structure

```
├── terraform/
│   ├── backend.tf                # S3 backend configuration
│   ├── main.tf                   # Root module orchestration
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   ├── providers.tf              # Provider configuration
│   ├── terraform.tfvars.example  # Example variable values
│   ├── bootstrap/                # State backend bootstrap (S3 bucket)
│   └── modules/
│       ├── vpc/
│       ├── ecr/
│       ├── eks/
│       ├── monitoring/
│       └── github-oidc/
├── kubernetes/
│   └── aws-load-balancer-controller/  # LB Controller service account template
├── Makefile                      # Automation commands
└── .github/workflows/
    ├── terraform-apply.yaml      # Infrastructure deploy/destroy
    └── install-lb-controller.yaml # AWS Load Balancer Controller setup
```

## Deploy

```bash
# 1. Bootstrap the S3 state backend (one-time)
make bootstrap

# 2. Deploy the infrastructure
make apply

# 3. Install the AWS Load Balancer Controller
make install-lb-controller

# Or do steps 2-3 together:
make setup
```

After `make apply`, wire up GitHub Actions by adding the role ARN as a repo secret:

```bash
cd terraform && terraform output -raw github_actions_role_arn
# Add the value as the AWS_ROLE_ARN secret under Settings → Secrets and variables → Actions
```

## Deploy an application

This repo intentionally does not ship application manifests. To run a workload:

1. Push your image to the ECR repository (`terraform output -raw ecr_repository_url`).
2. Create a dedicated namespace for the app.
3. Apply your Deployment/Service/Ingress/HPA manifests referencing that namespace.

The ALB Ingress class is `alb` (provided by the AWS Load Balancer Controller).

## Destroy

```bash
make destroy      # Destroy infrastructure (keeps the state bucket)
make destroy-all  # Destroy everything including the state bucket
```

## Configuration

Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and adjust as
needed. Key variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `project_name` | `alpha-k` | Prefix applied to all resources |
| `region` | `us-east-1` | AWS region |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `az_count` | `2` | Number of AZs |
| `single_nat_gateway` | `true` | Single NAT gateway (cost) vs one per AZ (HA) |
| `cluster_version` | `1.29` | EKS Kubernetes version |
| `node_instance_types` | `["t3.small"]` | Node group instance types |
| `ecr_repository_name` | `alpha-k-app` | ECR repository name |
| `github_org` / `github_repo` | `""` | Set to enable GitHub Actions OIDC |

## Make targets

| Command | Description |
|---------|-------------|
| `make bootstrap` | Create the S3 bucket for Terraform state |
| `make plan` | Preview infrastructure changes |
| `make apply` | Deploy infrastructure |
| `make setup` | Deploy infrastructure + install LB controller |
| `make install-lb-controller` | Install the AWS Load Balancer Controller |
| `make configure-kubectl` | Point kubectl at the EKS cluster |
| `make outputs` | Show Terraform outputs |
| `make destroy` | Destroy infrastructure |
| `make destroy-all` | Destroy infrastructure and the state bucket |
| `make clean` | Remove local Terraform working files |
