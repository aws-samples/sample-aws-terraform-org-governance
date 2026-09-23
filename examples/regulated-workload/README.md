# Regulated Workload Example

Strict controls suitable for financial services, healthcare, or other regulated workloads.

## When to Use

- You have compliance obligations (PCI-DSS, HIPAA, SOC 2, ISO 27001)
- You need comprehensive encryption, MFA, and audit trail integrity enforcement
- You have a dedicated Security Tooling account for central security service delegation

## What Gets Created

```
Root
├── Regulated
│   ├── Production
│   └── UAT
└── Non-Regulated
    └── Development
```

Plus:

- **SCP** foundation guardrails across both regulated and non-regulated
- **RCP** `rcp-require-ssl` + `rcp-confused-deputy-protection` on `regulated`
- **Backup policy** daily + weekly with cross-region DR copy on `regulated` (tag-driven by `BackupTier=critical`)
- **AI opt-out** at the root — prevents AWS from using regulated content for AI/ML training
- **Tag policy** mandatory enforcing Environment/Team/CostCenter/ManagedBy
- **CT controls** — comprehensive set covering:
  - Encryption (EBS, RDS, S3 audit bucket)
  - Network isolation (no public IPs, restricted ports, VPC public access blocked)
  - Data protection (S3 public prohibited, versioning, snapshot public blocked)
  - Identity (root user restricted, MFA required everywhere)
  - Audit trail (CloudTrail enabled + validated + logs intact, Config enabled)
- **Delegation** — all security services delegated to one Security Tooling account

## Key Customizations (Required)

- Replace `111111111111` with your Security Tooling account ID (used by all security service delegations)
- Change `breakglass_role` to match your break-glass IAM role name
- Review the CT controls list — your compliance framework may require additional controls not listed here

## What's Intentionally Excluded

- **No RAM sharing** — regulated workloads typically shouldn't share resources freely
- **No non-security delegations** — keeps Backup/SSM/IPAM isolated from security tooling
- **Non-Regulated OU doesn't get strict CT controls** — keep dev productive, only enforce on Regulated

## Apply

```bash
terraform plan -var-file=examples/regulated-workload/terraform.tfvars
terraform apply -var-file=examples/regulated-workload/terraform.tfvars
```
