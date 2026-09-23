# Enterprise Example

All features enabled — suitable for large organizations with mature security practices and dedicated-purpose accounts.

## When to Use

- You have dedicated accounts for Security Tooling, Network, Identity, Automation, and Infrastructure
- You want every CT control, every delegation, and full tag governance
- You're ready to manage 10+ accounts across multiple environments

## What Gets Created

```
Root
├── Infrastructure
│   ├── Network
│   └── Shared Services
├── Workloads
│   ├── Production
│   └── Non-Production
│       ├── Development
│       ├── Staging
│       └── QA
├── Deployments
│   └── CI/CD
└── Data
    ├── Analytics
    └── Data Lake
```

Plus:

- **SCP** `scp-foundation-guardrails` on all custom OUs
- **RCP** `rcp-require-ssl` + `rcp-confused-deputy-protection` on `workloads` and `data`
- **Backup policy** `backup-critical-daily-weekly` on `workloads` and `data` (daily + weekly + DR copy)
- **AI opt-out** attached at the root — opts the whole org out of AI service content use
- **Chatbot policy** at the root — only approved Slack workspaces and Teams allowed
- **Tag policies** mandatory + recommended on all custom OUs
- **CT controls** for encryption, network, S3, logging, and IAM across Workloads
- **All 15 service delegations** pointing to purpose-specific member accounts
- **RAM sharing** enabled organization-wide
- **Identity Center baseline** configured

## Key Customizations (Required)

Replace these placeholders with your actual account IDs:

| Placeholder    | Typical Account          |
| -------------- | ------------------------ |
| `111111111111` | Security Tooling account |
| `222222222222` | Infrastructure account   |
| `333333333333` | Network account          |
| `444444444444` | Automation account       |
| `555555555555` | Identity account         |

Also:

- Set `ct_identity_center_baseline_arn` to your actual baseline ARN (get it via `aws controltower list-enabled-baselines`)
- Change `breakglass_role` to match your break-glass IAM role name

## Apply

```bash
terraform plan -var-file=examples/enterprise/terraform.tfvars
terraform apply -var-file=examples/enterprise/terraform.tfvars
```
