# Policies Reference Library

Catalog of reusable organization-level policy files. Attach them via the matching input variable in your tfvars.

| Policy type             | Input variable        | Files live in          |
| ----------------------- | --------------------- | ---------------------- |
| Service Control Policy  | `scp_policies`        | `policies/scp/`        |
| Resource Control Policy | `rcp_policies`        | `policies/rcp/`        |
| Tag Policy              | `tagging_policies`    | `policies/tag-policy/` |
| Backup Policy           | `backup_policies`     | `policies/backup/`     |
| AI Services Opt-Out     | `ai_opt_out_policies` | `policies/ai-opt-out/` |
| Chatbot Policy          | `chatbot_policies`    | `policies/chatbot/`    |

## Service Control Policies (SCPs)

Restrict what IAM principals in your org's member accounts can do. Deny-only.

| File                                         | Purpose                                                                            | Template Vars                        |
| -------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------ |
| `scp/scp-foundation-guardrails.json.tpl`     | Deny org leave, IMDSv2 required, EBS/RDS encryption, block external RAM sharing    | `breakglass_role`                    |
| `scp/scp-deny-root-user.json.tpl`            | Deny all root user actions; deny creating root access keys                         | —                                    |
| `scp/scp-deny-iam-user-creation.json.tpl`    | Force SSO; block creating IAM users, passwords, access keys                        | `breakglass_role`                    |
| `scp/scp-require-imdsv2.json.tpl`            | Deny launching EC2 without IMDSv2, enforce hop limit ≤ 2                           | `breakglass_role`                    |
| `scp/scp-s3-encryption-ssl.json`             | Require SSE on PUT, require SSL, block disabling account-level public access block | —                                    |
| `scp/scp-require-tags-on-create.json.tpl`    | Require Environment/Team/CostCenter tags on EC2, RDS, S3, EBS                      | —                                    |
| `scp/scp-region-restriction.json.tpl`        | Deny API calls outside allowed regions (global services whitelisted)               | `allowed_regions`, `breakglass_role` |
| `scp/scp-protect-security-services.json.tpl` | Prevent disabling CloudTrail, GuardDuty, Config, SecurityHub                       | `breakglass_role`                    |
| `scp/scp-deny-expensive-services.json`       | Block expensive services (Redshift, EMR, SageMaker) and large instance families    | —                                    |

## Resource Control Policies (RCPs)

Restrict what can be done _to resources in your accounts_, even by external principals and AWS services. Complements SCPs.

| File                                                  | Purpose                                                                                       | Template Vars |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------- | ------------- |
| `rcp/rcp-require-ssl.json`                            | Deny non-SSL access to S3, SQS, Secrets Manager — applies even for cross-account access       | —             |
| `rcp/rcp-enforce-confused-deputy-protection.json.tpl` | Block access from outside your org ID; require `aws:SourceAccount` when services assume roles | —             |

> **Note:** RCPs require `RESOURCE_CONTROL_POLICY` to be enabled on your org root. The module does not yet manage this — run:
>
> ```bash
> aws organizations enable-policy-type --root-id r-xxxx --policy-type RESOURCE_CONTROL_POLICY
> ```

## Tag Policies

Enforce tag key casing and allowed values. Tag policies do not block actions — pair with `scp-require-tags-on-create` to enforce presence.

| File                                             | Purpose                                                             |
| ------------------------------------------------ | ------------------------------------------------------------------- |
| `tag-policy/tag-policy-mandatory.json`           | Enforce allowed values for Environment, Team, CostCenter, ManagedBy |
| `tag-policy/tag-policy-recommended.json`         | Enforce key casing for Name, Owner, Description                     |
| `tag-policy/tag-policy-data-classification.json` | Enforce DataClassification on S3/RDS/DynamoDB/Secrets               |
| `tag-policy/tag-policy-cost-allocation.json`     | Project, Application, Environment, BusinessUnit for cost reporting  |

## Backup Policies

Org-wide AWS Backup plans attached to OUs. Every account in the target OU inherits the plan.

| File                                                  | Purpose                                                                                      | Template Vars                                                |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `backup/backup-policy-daily-35day.json.tpl`           | Daily backups, 35-day retention, triggered by `Backup=true` tag                              | `primary_region`, `vault_name`                               |
| `backup/backup-policy-critical-daily-weekly.json.tpl` | Daily + weekly backups with cross-region copy for DR, triggered by `BackupTier=critical` tag | `primary_region`, `dr_region`, `vault_name`, `dr_vault_name` |

> **Note:** Backup policies reference `$$account` literally — this is the AWS-recognized token that gets substituted per account. Do not change.
>
> Requires `BACKUP_POLICY` to be enabled on your org root:
>
> ```bash
> aws organizations enable-policy-type --root-id r-xxxx --policy-type BACKUP_POLICY
> ```

## AI Services Opt-Out Policies

Control whether AWS can use your content (images, audio, text) to improve AI/ML services. Essential for GDPR, HIPAA, and privacy-sensitive orgs.

| File                                   | Purpose                                                                                     |
| -------------------------------------- | ------------------------------------------------------------------------------------------- |
| `ai-opt-out/ai-opt-out-all.json`       | Opt out of ALL AWS AI services globally                                                     |
| `ai-opt-out/ai-opt-out-selective.json` | Opt out of specific services (Rekognition, Comprehend, Transcribe, etc.), opt into the rest |

> Requires `AISERVICES_OPT_OUT_POLICY` to be enabled on your org root:
>
> ```bash
> aws organizations enable-policy-type --root-id r-xxxx --policy-type AISERVICES_OPT_OUT_POLICY
> ```

## Chatbot Policies

Restrict which Slack workspaces and MS Teams channels can interact with AWS through AWS Chatbot. Prevents unauthorized ChatOps.

| File                                                       | Purpose                                                    | Template Vars                           |
| ---------------------------------------------------------- | ---------------------------------------------------------- | --------------------------------------- |
| `chatbot/chatbot-restrict-to-approved-workspaces.json.tpl` | Only allow specific Slack workspace IDs and Teams team IDs | `slack_workspace_ids`, `teams_team_ids` |

> Requires `CHATBOT_POLICY` to be enabled on your org root:
>
> ```bash
> aws organizations enable-policy-type --root-id r-xxxx --policy-type CHATBOT_POLICY
> ```

## Using a templated policy (`.tpl`)

Pass template variables via `vars`:

```hcl
scp_policies = {
  "scp-region-restriction" = {
    description = "Limit to approved regions"
    path        = "policies/scp/scp-region-restriction.json.tpl"
    vars = {
      allowed_regions = "\"us-east-1\",\"us-west-2\",\"eu-west-1\""
      breakglass_role = "BreakGlass-Admin"
    }
    targets = ["workloads"]
  }
}
```

## Using a plain JSON policy

No `vars` needed:

```hcl
rcp_policies = {
  "rcp-require-ssl" = {
    description = "Require SSL for S3, SQS, Secrets Manager"
    path        = "policies/rcp/rcp-require-ssl.json"
    vars        = {}
    targets     = ["workloads"]
  }
}
```

## Break-Glass Role Pattern

Most templated policies exclude a `breakglass_role` so you can recover if the policy locks you out.

- Create the role in every account via CloudFormation StackSet from the management account
- Protect the role name with an IAM policy so it can't be renamed or deleted by workloads
- Restrict assumption to the management account + MFA required
- Monitor all assumptions via CloudTrail alerts

## Authoring Tips

- **Stay under 5120 bytes** for SCPs and RCPs after rendering. The module enforces this.
- **Always test in a sandbox OU first.** Policies apply immediately to all accounts.
- **Use `NotAction` sparingly** — over-denying is the #1 cause of lockout.
- **Use IAM Access Analyzer policy validation** on rendered JSON before committing.
- **Attach `breakglass_role` exclusions** on any deny policy you might need to disable in an emergency.
- **Version policies via git** — the effective policy is the rendered one, not the template. Commit both to make drift detection possible.

## References

- [SCP examples](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html)
- [RCP examples](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps_examples.html)
- [Tag policy syntax](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies-syntax.html)
- [Backup policy syntax](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup_syntax.html)
- [AI opt-out policy syntax](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out_syntax.html)
- [Chatbot policy syntax](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_chatbot_syntax.html)
- [Policy size and limits](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_limits.html)
