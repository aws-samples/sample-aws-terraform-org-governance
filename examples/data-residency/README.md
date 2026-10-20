# Data Residency Example

Region-locked workloads for data sovereignty requirements.

## When to Use

- GDPR or country-specific data sovereignty rules
- Workloads must not cross Region boundaries under any circumstance
- You want separate OUs per Region to make the intent explicit

## What Gets Created

```
Root
├── EU-Workloads   ← intended for eu-west-1 / eu-central-1
└── US-Workloads   ← intended for us-east-1 / us-west-2
```

Plus:

- **SCP** `scp-foundation-guardrails` on both
- **RCP** `rcp-require-ssl` on both — enforces in-transit encryption across accounts
- **AI opt-out** at the root — prevents sovereign data being processed for AI/ML training
- **AWS Control Tower controls** focused on data residency:
  - Cross-Region networking blocked
  - VPC internet access blocked
  - VPN connections blocked
  - S3 cross-Region replication restricted
  - Public IPs prohibited (RDS, EC2, Lambda, OpenSearch, SageMaker)
  - IGW routes unrestricted blocked
- **Tag policy** mandatory

## Key Customizations

- Add a Region restriction SCP targeting each regional OU — this example uses AWS Control Tower controls for the data plane but you should also add SCPs like `aws:RequestedRegion` denials for control plane operations. Create your own SCP file in `policies/scp/` and add it to `scp_policies`.
- Adjust OU keys if you operate in more Regions (for example, `apac-workloads`, `latam-workloads`)

## Important Notes

- **This example covers data-plane residency** (no cross-Region networking, no public access). For full residency you should also:
  - Add a Region restriction SCP with `aws:RequestedRegion` conditions
  - Use the AWS Control Tower Region deny control at the OU level
  - Set `ct_baseline_version` matching the version that includes Region governance
- Some services are global (IAM, CloudFront, Route53) and cannot be Region-locked via IAM conditions alone

## Apply

```bash
terraform plan -var-file=examples/data-residency/terraform.tfvars
terraform apply -var-file=examples/data-residency/terraform.tfvars
```
