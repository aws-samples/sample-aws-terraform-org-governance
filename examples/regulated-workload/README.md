# Regulated Workload Example

Strict controls suitable for financial services, healthcare, or other regulated workloads.

## When to Use

- You have compliance obligations (PCI-DSS, HIPAA, SOC 2, ISO 27001)
- You need encryption, MFA and audit-trail compliance reported across a regulated OU, with preventive SCPs layered on top
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

- **SCP** `scp-foundation-guardrails` across both regulated and non-regulated
- **RCP** `rcp-require-ssl` + `rcp-confused-deputy-protection` on `regulated`
- **Backup policy** daily + weekly with cross-Region DR copy on `regulated` (tag-driven by `BackupTier=critical`)
- **AI opt-out** at the root — prevents AWS from using regulated content for AI/ML training
- **Tag policy** mandatory enforcing Environment/Team/CostCenter/ManagedBy
- **AWS Control Tower controls** — comprehensive set covering:
  - Preventive: root user actions and root access key creation are denied, and changes to Amazon S3 bucket encryption are denied
  - Detective: encryption is reported for Amazon EBS volumes and Amazon RDS storage
  - Detective: public IP addresses, unrestricted SSH and unrestricted common ports are reported
  - Detective: public Amazon S3 buckets, missing bucket versioning, and public Amazon RDS and Amazon EBS snapshots are reported
  - Detective: MFA is reported for the root user and for IAM users
  - Detective: member accounts without AWS CloudTrail enabled are reported

  Three of these controls are preventive. The other 16 are detective: they evaluate resources with AWS Config rules and report violations on the AWS Control Tower dashboard. Pair them with the SCPs in `policies/scp/` if you need an action blocked rather than reported.
- **Delegation** — all security services delegated to one Security Tooling account

## Key Customizations (Required)

- Replace `111111111111` with your Security Tooling account ID (used by all security service delegations)
- Change `breakglass_role` to match your break-glass IAM role name
- Review the AWS Control Tower controls list — your compliance framework may require additional controls not listed here

## What's Intentionally Excluded

- **No RAM sharing** — regulated workloads typically should not share resources freely
- **No mandatory AWS Control Tower controls** — AWS Control Tower already applies the mandatory controls that protect its AWS CloudTrail, AWS Config and log archive resources, and the control APIs cannot enable them on an OU
- **No non-security delegations** — keeps AWS Backup, AWS Systems Manager, and Amazon VPC IPAM isolated from security tooling
- **Non-Regulated OU does not get strict AWS Control Tower controls** — keep dev productive, only enforce on Regulated

## Apply

```bash
terraform plan -var-file=examples/regulated-workload/terraform.tfvars
terraform apply -var-file=examples/regulated-workload/terraform.tfvars
```
