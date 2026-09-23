# Examples

Each folder contains a `terraform.tfvars` tuned for a specific use case. Customize the one closest to your needs in place and pass it with `-var-file`.

| Example                                    | Best For                                                                                                        |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| [minimal](./minimal)                       | First-time setup. OU hierarchy only, no policies or delegations.                                                |
| [standard](./standard)                     | Growing company. SCP + RCP + tag policies + daily backup plan.                                                  |
| [enterprise](./enterprise)                 | Large org. All policy types (SCP, RCP, Backup, AI opt-out, Chatbot), 15 service delegations, broad CT controls. |
| [regulated-workload](./regulated-workload) | Finance/healthcare. Strict encryption, MFA, audit integrity + RCP, critical-tier backup, AI opt-out.            |
| [data-residency](./data-residency)         | GDPR / data sovereignty. Region-locked OUs, SSL-required RCP, AI opt-out for privacy.                           |

## How to Use

Customize an example's `terraform.tfvars` in place, then run Terraform against it:

```bash
terraform init
terraform plan  -var-file=examples/standard/terraform.tfvars
terraform apply -var-file=examples/standard/terraform.tfvars
```

## Customizing

Each example is a starting point. Typical edits:

- Swap placeholder account IDs (`111111111111`, etc.) for your real account IDs
- Set `ct_identity_center_baseline_arn` if you use Identity Center (run `aws controltower list-enabled-baselines` to get it)
- Rename OU keys to match your naming convention
- Add/remove `ct_controls` entries based on your compliance needs
- Adjust the `breakglass_role` name in `scp_policies` vars to match your break-glass IAM role
