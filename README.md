# AWS Secure Architecture — Terraform

Infrastructure-as-Code lab for a multi-VPC AWS network architecture in `eu-west-3` (Paris). The current configuration establishes networking foundations and TGW forwarding; it **does not yet deploy AWS Network Firewall, NAT Gateways, or traffic inspection**.

## High-level architecture

```text
Application VPC (10.0.0.0/16)
  Public ALB subnets (two AZs) -> IGW via public route table
  Private web / app / database subnets -> TGW default route
  Dedicated TGW subnets (two AZs)
               |
               v
        Central Transit Gateway
        Application TGW RT: 0.0.0.0/0 -> Inspection attachment
        Inspection TGW RT: 10.0.0.0/16 -> Application attachment
               |
               v
Inspection VPC (10.1.0.0/16)
  TGW, firewall-reserved, and NAT-reserved subnets in two AZs
  (firewall, NAT, endpoint routes, and egress path NOT YET created)
```

**Routing caveat:** TGW routing alone cannot force traffic through a firewall. The Inspection VPC subnet route tables, firewall endpoints, symmetric return routing, and egress components must still be built. At this stage internet egress from private workloads may not work.

## Directory guide

| Path | Purpose |
|---|---|
| `main.tf` | Compose VPCs, subnets, TGW attachments, TGW route tables and routes |
| `provider.tf` | AWS provider, region, CLI profile, caller identity |
| `outputs.tf` | Export the two VPC IDs and CIDRs |
| `modules/vpc/` | Create a VPC with DNS features |
| `modules/subnets/` | Create named subnets in specified AZs |
| `modules/internet_gateway/` | Attach an IGW |
| `modules/route_tables/` | Public route table and associations |
| `modules/private_route_tables/` | One private route table per workload subnet |
| `modules/transit_gateway/` | Central TGW resource |
| `modules/tgw_attachment/` | VPC attachment with optional appliance mode |

Each module uses `main.tf` for resources, `variables.tf` for inputs (when needed), and `outputs.tf` for outputs.

## Prerequisites

- Terraform CLI, AWS CLI and appropriate AWS permissions.
- AWS credentials configured locally with a named profile `terraform-admin`, or adjust `provider.tf` for your environment. **Do not commit credentials.**
- AWS region: `eu-west-3`. Existing region resources and AWS service-linked roles can affect applies.
- Be aware of the ongoing hourly cost of Transit Gateway attachments and any future firewall/NAT resources.

## Read-only verification

```powershell
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

`terraform init` and `plan` may contact AWS/provider registries. Review every plan carefully before deploying. Do not run `apply` simultaneously from two machines.

## Deployment (only with team agreement)

```powershell
terraform plan -out=lab.tfplan
terraform apply lab.tfplan
```

This repo currently uses local Terraform state unless an external backend is configured. **Local state is not collaboration-safe**: never share state in Git. For shared deployments, agree on and configure a remote backend (such as S3 with locking supported by your chosen Terraform version), migrate existing state carefully, and restrict access. Do not blindly run `terraform apply` from a fresh clone against resources that already exist.

## Current status and next steps

**Implemented:** two VPC definitions, subnet topology, Application IGW/public routing, private route tables, TGW, VPC attachments, TGW route table associations, Application-to-Inspection default forwarding, Inspection-to-Application return route, private subnet default routes to TGW.

**Not implemented:** AWS Network Firewall, firewall rule groups/policies, firewall VPC endpoints/routes, NAT egress, VPC Flow Logs, firewall logs, ALB/compute workloads and high-availability inspection path validation.

Suggested next work: implement inspection VPC route tables and firewall endpoints, test forward/return symmetry per AZ, then add firewall policy/rule groups and logs.

## Secrets and Git hygiene

`.gitignore` excludes `.terraform/`, all Terraform state, plan files, `*.tfvars`, credential-like files and local overrides. `.terraform.lock.hcl` is intentionally versioned. Check `git status` and `git diff --cached` before each commit. If a sensitive file was previously committed, `.gitignore` alone does not remove it from Git history.

For team workflow and reviews, read [CONTRIBUTING.md](CONTRIBUTING.md).
