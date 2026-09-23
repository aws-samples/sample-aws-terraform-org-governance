# Standard Example

Typical setup for a growing company — OU hierarchy, foundation SCP, and tag governance. No service delegation or CT controls yet.

## When to Use

- You're past first-time setup and want baseline guardrails.
- You haven't yet designated dedicated Security/Network/Automation accounts.
- You want tag enforcement to start building cost-allocation hygiene.

## What Gets Created

```
Root
├── Security        (CT-managed — not in this config)
├── Sandbox         (CT-managed — not in this config)
├── Infrastructure  ← created
└── Workloads       ← created
    ├── Production
    └── Non-Production
        ├── Development
        └── Staging
```

Plus:

- **SCP** `scp-foundation-guardrails` on `infrastructure` and `workloads` — denies org leave, requires IMDSv2, enforces EBS/RDS encryption, blocks external RAM sharing
- **RCP** `rcp-require-ssl` on `workloads` — forces SSL on S3/SQS/Secrets Manager, even for cross-account access
- **Tag policies** mandatory + recommended on `workloads` and `infrastructure`
- **Backup policy** daily 35-day retention on `workloads` — activated by tagging resources `Backup=true`

## Key Customizations

- Change the `breakglass_role` in `scp_policies.scp-foundation-guardrails.vars` to match your break-glass IAM role name
- Adjust OU names/keys to your conventions

## Next Steps

- Add CT controls for encryption, S3 public access, and IAM MFA (see `enterprise`)
- Delegate GuardDuty / SecurityHub / Config to a dedicated Security Tooling account (see `enterprise`)

## Apply

```bash
terraform plan -var-file=examples/standard/terraform.tfvars
terraform apply -var-file=examples/standard/terraform.tfvars
```
