# sample-aws-terraform-org-governance

Terraform sample code for managing governance in AWS Organizations on top of an existing AWS Control Tower landing zone. Covers OU hierarchies, six of the AWS Organizations policy types (service control, resource control, tag, backup, AI services opt-out, and chat applications policies), AWS Control Tower baselines and controls, and delegated administrator configuration for 14 AWS services.

## Disclaimer

This is sample code, for non-production usage. You should work with your security and legal teams to meet your organizational security, regulatory and compliance requirements before deployment.

The policies in this repository take effect immediately on attachment and apply to every account in the target OU and below. Attach a new deny policy to a non-production OU and confirm its effect before attaching it to an OU that holds production accounts, and read every `terraform plan` before applying it.

## Architecture

The following four figures each show something the others cannot:

| Figure | Answers |
| ------ | ------- |
| [Governance topology](#governance-topology) | What is deployed, and where each kind of governance lands |
| [What each policy type bounds](#what-each-policy-type-bounds) | Why more than one policy type is needed |
| [OU nesting and ordering](#ou-nesting-and-ordering) | How deep the hierarchy goes, and the baseline ordering AWS imposes |
| [Delegated administration](#delegated-administration) | Every service whose administration can be delegated |

### Governance topology

![Governance in AWS Organizations on an AWS Control Tower landing zone](docs/diagrams/org-governance-topology.svg)

This is a **root Terraform deployment**, not a module. It consumes no external modules, holds no provider aliases, and runs in exactly one place: the **organization's management account**, in the AWS Control Tower home Region. From there it writes three independent kinds of governance onto the OU tree — AWS Organizations policies, AWS Control Tower baselines and controls, and delegated administration.

Note the following four behaviors:

1. **Nothing is created in a member account.** Delegated administration designates an account; it does not deploy into it. The single exception is `aws_macie2_account`, which enables Macie in the _management_ account because AWS requires that before a Macie delegated administrator can be designated.
2. **Policies attach, they do not nest.** A policy document is created once and attached to as many targets as you list. Inheritance down the OU tree is an AWS Organizations behavior, not something this sample models.
3. **Controls target OUs, never the root.** AWS Control Tower controls resolve to an OU ARN, so `"root"` is not an addressable target for them the way it is for policies.
4. **AWS Resource Access Manager (AWS RAM) sharing is a single organization-wide toggle** with no OU dimension at all.

The figure shows the delegated administrator as a separate account. Conventionally it sits inside the `Security` OU, where AWS Control Tower places the Audit account, but this sample takes only an account ID and does not constrain where that account lives. The figure shows four of the 14 supported services; [Delegated administration](#delegated-administration) has the complete list.

### Ownership boundary

This sample assumes that AWS Control Tower already exists, and it stops at that boundary:

| This configuration owns                                        | AWS Control Tower owns                                                  |
| -------------------------------------------------------------- | ------------------------------------------------------------------- |
| OUs you declare in `var.organization`, up to five levels deep   | The `Security` and `Sandbox` OUs, and the Audit and Log Archive accounts |
| Six AWS Organizations policy types, and their attachments       | The landing zone itself, and its own mandatory controls            |
| Which AWS Control Tower baseline version each OU is registered at   | The baseline's contents                                              |
| Which controls are enabled on which OU                         | The control catalog                                                  |
| Delegated administrator designation for 14 services            | —                                                                    |

Declaring an AWS Control Tower OU in `var.organization` would make Terraform try to create it and fail. Targeting one from a policy or a control is supported and expected — see [Addressing targets](#addressing-targets).

### What each policy type bounds

![Service control policies bound principals; resource control policies bound resources, including access from outside the organization](docs/diagrams/org-policy-surfaces.svg)

This is why the configuration manages more than one policy type. A **service control policy** bounds what principals *inside* a member account may do — it is the familiar preventive policy, and it has no effect on a caller outside the organization. A **resource control policy** bounds what may be done *to* the account's resources, so it reaches a principal that an SCP cannot evaluate. The remaining four types govern different dimensions again: tag policies enforce tag key casing and allowed values, backup policies apply AWS Backup plans, AI services opt-out policies keep your content out of AI/ML service improvement, and chat applications policies restrict which Slack workspaces and Microsoft Teams teams can reach your accounts.

### OU nesting and ordering

![One OU branch at maximum depth, with AWS Control Tower registering the baseline parent before child](docs/diagrams/org-ou-nesting.svg)

The governance topology figure shows the OU tree as a flat row of siblings, which cannot show depth. AWS permits five levels beneath the root and the configuration implements exactly that. The figure also shows the baseline ordering that AWS imposes and Terraform cannot infer, one of the two explicit orderings that the next section explains.

### Apply ordering

Most of the ordering is implicit; it falls out of one resource referencing another's attribute. Two places need explicit `depends_on` because AWS imposes an order the data flow does not express:

- **OU levels order themselves.** `level_2_ous` uses `aws_organizations_organizational_unit.level_1_ous[each.value.parent].id` as its `parent_id`, so a level cannot start before its parent finishes. No `depends_on` needed.
- **Baselines are chained explicitly.** `aws_controltower_baseline.level_2` carries `depends_on = [aws_controltower_baseline.level_1]`, and so on to level 5. Without it Terraform would register all five levels in parallel and AWS Control Tower would reject the children.
- **Controls wait on the level 1 baseline.** `aws_controltower_control.controls` depends on `aws_controltower_baseline.level_1` rather than on the baseline for its own target OU — a deliberate simplification, since the level 1 registration is what enables the control plane for the tree.
- **Policy documents are independent of the tree.** Each `aws_organizations_policy` resource only reads files from disk. It is the _attachment_ that references an OU ID, so the attachment carries the dependency.
- **Delegations and RAM sharing have no ordering constraint** and run concurrently with everything else.

### Delegated administration

![The 14 AWS services whose administration this configuration can delegate to a member account](docs/diagrams/org-delegated-admin.svg)

Every service above is optional and is enabled by setting a member account ID; leave one unset to skip it. The governance topology figure shows only four of them, so this figure is the complete list.

Two icons are borrowed from the parent service because no icon exists for the feature itself: the AWS Identity and Access Management icon stands for IAM Access Analyzer, and the Amazon Virtual Private Cloud icon for Amazon VPC IP Address Manager.

The delegation mechanism is not uniform, which matters when scoping the deploying role's permissions. AWS Backup, AWS CloudFormation StackSets, AWS Config, IAM Access Analyzer, AWS IAM Identity Center, and AWS Systems Manager use `organizations:RegisterDelegatedAdministrator`. Amazon GuardDuty, AWS Security Hub CSPM, Amazon Detective, and Amazon Macie each use their own `EnableOrganizationAdminAccount` action; Amazon Inspector uses `inspector2:EnableDelegatedAdminAccount`, AWS Firewall Manager `fms:AssociateAdminAccount`, Amazon VPC IP Address Manager `ec2:EnableIpamOrganizationAdminAccount`, and AWS CloudTrail `cloudtrail:RegisterOrganizationDelegatedAdmin`.

> **Note:** The `config` entry registers `config.amazonaws.com`, the delegated administrator for AWS Config multi-account data aggregation. Organization AWS Config rules and conformance packs use a separate registration with `config-multiaccountsetup.amazonaws.com`, which this sample does not create.

> **Note:** AWS Organizations policy management is not delegated through `RegisterDelegatedAdministrator`. To delegate it, use a [resource-based delegation policy](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_delegate_policies.html), which this sample does not manage.

> **Note:** Setting the Macie delegation also enables Macie in the management account, because AWS requires that before a Macie delegated administrator can be designated.

All four figures use the official AWS Architecture Icons and are rendered to SVG and PNG in [`docs/diagrams/`](./docs/diagrams).

## What It Does

1. Creates additional OUs beyond what AWS Control Tower provides (up to 5 nesting levels)
2. Registers each OU with the AWS Control Tower baseline — parent before children
3. Creates and attaches six of the AWS Organizations policy types to target OUs:
   - **SCPs** — service control policies (deny statements on IAM principals)
   - **RCPs** — resource control policies (deny statements on resources, including external principals)
   - **Tag policies** — enforce tag key casing and allowed values
   - **Backup policies** — organization-wide AWS Backup plans
   - **AI services opt-out policies** — prevent AWS from using content for AI and ML improvement
   - **Chat applications policies** — restrict which Slack workspaces and Microsoft Teams teams can reach your accounts through Amazon Q Developer in chat applications

   AWS Organizations has more policy types, such as Amazon EC2 declarative policies, Security Hub policies, Amazon Inspector policies, Amazon Bedrock policies, Amazon S3 policies, Amazon GuardDuty policies, and upgrade rollout policies. This sample does not manage them.
4. Enables AWS Control Tower controls on target OUs: legacy `AWS-GR_*` controls, proactive `CT.*.PR.*` and preventive `CT.*.PV.*` controls, and detective `SH.*` controls
5. Delegates administration of 14 AWS services to designated member accounts
6. Optionally enables organization-wide AWS RAM sharing
7. Ships with a reusable policy template library and five scenario-based examples (minimal, standard, enterprise, regulated-workload, data-residency)

## Prerequisites

- AWS Control Tower landing zone deployed and operational
- `Security` and `Sandbox` OUs already exist (created by AWS Control Tower)
- Audit and Log Archive accounts provisioned by AWS Control Tower
- Terraform executed from the **management account**
- AWS Command Line Interface (AWS CLI), installed and configured
- An AWS Identity and Access Management (IAM) role in the management account with permissions to deploy this sample, and permission to assume it
- A configured Terraform backend
- SCP policy type enabled in the organization:
  ```bash
  aws organizations enable-policy-type --root-id r-xxxx --policy-type SERVICE_CONTROL_POLICY
  ```
- Additional policy types (enable only what you plan to use):
  ```bash
  aws organizations enable-policy-type --root-id r-xxxx --policy-type TAG_POLICY
  aws organizations enable-policy-type --root-id r-xxxx --policy-type RESOURCE_CONTROL_POLICY
  aws organizations enable-policy-type --root-id r-xxxx --policy-type BACKUP_POLICY
  aws organizations enable-policy-type --root-id r-xxxx --policy-type AISERVICES_OPT_OUT_POLICY
  aws organizations enable-policy-type --root-id r-xxxx --policy-type CHATBOT_POLICY
  ```

## Quick Start

1. Pick an example from [`examples/`](./examples) that matches your use case:
   - [`minimal`](./examples/minimal) — OU hierarchy only, nothing else
   - [`standard`](./examples/standard) — SCP + RCP + tag policies + daily backup plan
   - [`enterprise`](./examples/enterprise) — all six managed policy types, 14 delegations, broad AWS Control Tower controls
   - [`regulated-workload`](./examples/regulated-workload) — encryption, MFA and audit reporting + RCP + critical-tier backup + AI opt-out
   - [`data-residency`](./examples/data-residency) — Region-locked OUs + SSL-required RCP + AI opt-out
2. Customize the chosen example's `terraform.tfvars` in place (set `aws_region`, account IDs, OU names, etc.)
3. Run with `-var-file` pointing at it:

```bash
terraform init
terraform plan  -var-file=examples/standard/terraform.tfvars
terraform apply -var-file=examples/standard/terraform.tfvars
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | ~> 1.14 |
| aws       | ~> 6.0  |

## Module Sources

This is a root deployment that does not consume external modules — all resources are defined directly.

| Module | Source | Version |
| ------ | ------ | ------- |
| —      | —      | —       |

## Resources

| Name                                                        | Type     |
| ----------------------------------------------------------- | -------- |
| `aws_organizations_organizational_unit.level_*`             | resource |
| `aws_controltower_baseline.level_*`                         | resource |
| `aws_controltower_control.controls`                         | resource |
| `aws_organizations_policy.scp`                              | resource |
| `aws_organizations_policy_attachment.scp`                   | resource |
| `aws_organizations_policy.rcp`                              | resource |
| `aws_organizations_policy_attachment.rcp`                   | resource |
| `aws_organizations_policy.tagging_policy`                   | resource |
| `aws_organizations_policy_attachment.tagging_policy`        | resource |
| `aws_organizations_policy.backup`                           | resource |
| `aws_organizations_policy_attachment.backup`                | resource |
| `aws_organizations_policy.ai_opt_out`                       | resource |
| `aws_organizations_policy_attachment.ai_opt_out`            | resource |
| `aws_organizations_policy.chatbot`                          | resource |
| `aws_organizations_policy_attachment.chatbot`               | resource |
| `aws_ram_sharing_with_organization.this`                    | resource |
| `aws_guardduty_organization_admin_account.this`             | resource |
| `aws_securityhub_organization_admin_account.this`           | resource |
| `aws_detective_organization_admin_account.this`             | resource |
| `aws_inspector2_delegated_admin_account.this`               | resource |
| `aws_macie2_account.this`                                   | resource |
| `aws_macie2_organization_admin_account.this`                | resource |
| `aws_fms_admin_account.this`                                | resource |
| `aws_vpc_ipam_organization_admin_account.this`              | resource |
| `aws_cloudtrail_organization_delegated_admin_account.this`  | resource |
| `aws_iam_service_linked_role.access_analyzer`               | resource |
| `aws_organizations_delegated_administrator.stacksets`       | resource |
| `aws_organizations_delegated_administrator.access_analyzer` | resource |
| `aws_organizations_delegated_administrator.config`          | resource |
| `aws_organizations_delegated_administrator.sso`             | resource |
| `aws_organizations_delegated_administrator.backup`          | resource |
| `aws_organizations_delegated_administrator.ssm`             | resource |
| `aws_organizations_organization.this`                       | data     |
| `aws_organizations_organizational_units.current`            | data     |
| `aws_region.current`                                        | data     |

## Inputs

| Name                              | Description                                                                                                        | Type           | Default       | Required |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------ | -------------- | ------------- | -------- |
| `tags`                            | Tags applied to all resources                                                                                      | `map(string)`  | —             | yes      |
| `aws_region`                      | AWS Region — should match your AWS Control Tower home Region                                                           | `string`       | `"us-east-1"` | no       |
| `organization`                    | OU hierarchy — name, key, ct_register per OU (up to 5 levels)                                                      | `object`       | `{}`          | no       |
| `scp_policies`                    | Service control policies — file path (.json/.tpl), template vars, description, target OU keys                      | `map(object)`  | `{}`          | no       |
| `rcp_policies`                    | Resource control policies — file path (.json/.tpl), template vars, description, target OU keys                     | `map(object)`  | `{}`          | no       |
| `tagging_policies`                | Tag policies — file path (.json/.tpl), template vars, description, target OU keys                                  | `map(object)`  | `{}`          | no       |
| `backup_policies`                 | Backup policies — file path (.json/.tpl), template vars, description, target OU keys                       | `map(object)`  | `{}`          | no       |
| `ai_opt_out_policies`             | AI services opt-out policies — file path (.json/.tpl), template vars, description, targets (`"root"` for organization-wide) | `map(object)`  | `{}`          | no       |
| `chatbot_policies`                | Chat applications policies — file path (.json/.tpl), template vars, description, targets (`"root"` for organization-wide) | `map(object)`  | `{}`          | no       |
| `ct_controls`                     | AWS Control Tower control assignments — control name to target OU key (OUs only, never the root)                                  | `list(object)` | `[]`          | no       |
| `ct_baseline_version`             | AWS Control Tower baseline version — must be compatible with your landing zone version                             | `string`       | `"5.0"`       | no       |
| `ct_identity_center_baseline_arn` | AWS IAM Identity Center baseline ARN — required when you enable IAM Identity Center                                 | `string`       | `""`          | no       |
| `enable_ram_sharing`              | Allow cross-account resource sharing within the organization through AWS RAM                                       | `bool`         | `false`       | no       |
| `enable_delegation`               | Delegate AWS service admin to member accounts (14 services)                                                        | `object`       | `{}`          | no       |

## Outputs

| Name                  | Description                                          |
| --------------------- | ---------------------------------------------------- |
| organization_id       | Organization ID                                      |
| organization_arn      | Organization ARN                                     |
| management_account_id | Management account ID                                |
| organizational_units  | Map of all OUs — key => { id, arn, name, parent_id } |

## Addressing targets

Every policy `targets` entry and every `ct_controls` target is resolved the same way, in this order:

| You write           | Resolves to                                                              |
| ------------------- | ------------------------------------------------------------------------ |
| An OU `key`         | An OU created by this configuration — wins over a same-named existing OU |
| An existing OU name | An OU already directly under the root, for example the AWS Control Tower `Security`   |
| `"root"`            | The organization root — policies only, not `ct_controls`                 |

`locals.tf` builds two merged lookup maps, both keyed lowercase, and the key spaces above are merged in that order so later entries win:

| Map                   | Value              | Used by                            |
| --------------------- | ------------------ | ---------------------------------- |
| `policy_target_ids`   | OU or root **ID**  | All six managed policy types       |
| `control_target_arns` | OU **ARN**         | `aws_controltower_control`         |

Because both the map keys and the lookup are lowercased, casing in tfvars does not matter — `Security`, `security` and `SECURITY` are equivalent. An unresolvable target fails its `lifecycle.precondition` at plan time with a message naming both the policy and the offending target string, rather than the null-argument error a bare `coalesce` would produce.

OU `key` values must be unique across all five nesting levels — they are the map keys for every OU, policy target and control target. A duplicate key fails at plan with Terraform's "Duplicate object key" error.

## Plan-time guards

Four classes of error are rejected during `terraform plan`, before any AWS API call. One class is not guarded:

| Guard                | Where                                                          | What it catches                                                                            |
| -------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Duplicate OU key     | Terraform's own `for_each` map construction                    | The same `key` used twice at any level — keys are the addressing scheme for every target    |
| Policy document size | `lifecycle.precondition` on each `aws_organizations_policy.*`  | A rendered document over its per-type character limit                                       |
| Unresolvable target  | `lifecycle.precondition` on each attachment and on the control | A target that is not an OU key, an existing OU name, or `root`                               |
| Unknown control name | `validation` on `var.ct_controls`                              | A control name absent from the `ct_control_ids` map in `ct_controls_definition.tf`           |
| Not guarded          | —                                                              | A control name in the map that has **mandatory** guidance. The control APIs enable only Strongly recommended and Elective controls, so it passes plan and fails during apply. See [Identifiers for legacy controls](https://docs.aws.amazon.com/controltower/latest/controlreference/identifiers-for-legacy-controls.html) |

## Common Operations

### OUs

**Add** — Add an OU block to `organization.units` in your example's tfvars:

```hcl
{
  name        = "Workloads"
  key         = "workloads"
  ct_register = true
  units = [
    { name = "Production", key = "workloads/production", ct_register = true }
  ]
}
```

**Remove** — Move all accounts out first, then remove the OU block.

**Move** — AWS does not support moving an OU. Create the new OU, move the accounts by running `aws organizations move-account`, then remove the old OU.

**Import** — `terraform import 'aws_organizations_organizational_unit.level_1_ous["ou-key"]' ou-xxxx-xxxxxxxx`

### SCPs

**Add** — Create `.json` or `.json.tpl` in `policies/scp/`, then add to `scp_policies`:

```hcl
"scp-my-policy" = {
  description = "What this policy does"
  path        = "policies/scp/scp-my-policy.json.tpl"
  vars        = { my_var = "value" }
  targets     = ["workloads"]
}
```

> See [`policies/README.md`](./policies/README.md) for the full catalog of pre-built policies across the six managed policy types (service control, resource control, tag, backup, AI services opt-out, and chat applications).

All six managed policy types resolve their document the same way: a `.json` path is read verbatim, a `.json.tpl` path is rendered with `templatefile` using that policy's `vars` map. Rendered size is checked against the AWS per-type limit at plan time.

**Attach/Detach** — Add or remove targets from the `targets` list; see [Addressing targets](#addressing-targets).

### Tag policies

**Add** — Create `.json` or `.json.tpl` in `policies/tag-policy/`, then add to `tagging_policies`:

```hcl
"tag-policy-mandatory" = {
  description = "Enforce allowed values for mandatory tags"
  path        = "policies/tag-policy/tag-policy-mandatory.json"
  targets     = ["workloads", "infrastructure"]
}
```

### RCPs (resource control policies)

**Add** — Create `.json` or `.json.tpl` in `policies/rcp/`, then add to `rcp_policies`:

```hcl
"rcp-require-ssl" = {
  description = "Require SSL for S3, SQS, Secrets Manager — even for cross-account access"
  path        = "policies/rcp/rcp-require-ssl.json"
  vars        = {}
  targets     = ["workloads"]
}
```

RCPs complement SCPs — SCPs restrict IAM principals in your accounts; RCPs restrict resources, including access from external principals.

### Backup Policies

**Add** — Create `.json.tpl` in `policies/backup/`, then add to `backup_policies`:

```hcl
"backup-daily-35day" = {
  description = "Daily backups, 35-day retention for resources tagged Backup=true"
  path        = "policies/backup/backup-policy-daily-35day.json.tpl"
  vars = {
    primary_region = "us-east-1"
    vault_name     = "OrgDefaultBackupVault"
  }
  targets = ["workloads"]
}
```

### AI services opt-out policies

**Add** — Create `.json` or `.json.tpl` in `policies/ai-opt-out/`, then add to `ai_opt_out_policies`. Typically attached to `"root"` for organization-wide opt-out:

```hcl
"ai-opt-out-all" = {
  description = "Opt out of AWS using organization content for AI/ML service improvement"
  path        = "policies/ai-opt-out/ai-opt-out-all.json"
  targets     = ["root"]
}
```

### Chat applications policies

**Add** — Create `.json` or `.json.tpl` in `policies/chatbot/`, then add to `chatbot_policies`:

```hcl
"chatbot-approved-workspaces" = {
  description = "Allow only approved Slack workspaces and Microsoft Teams teams"
  path        = "policies/chatbot/chatbot-restrict-to-approved-workspaces.json.tpl"
  vars = {
    slack_workspace_ids = "[\"T0123456789\"]"
    teams_team_ids      = "[\"00000000-0000-0000-0000-000000000000\"]"
  }
  targets = ["root"]
}
```

### AWS Control Tower controls

**Enable** — Add entries to `ct_controls` in your example's tfvars:

```hcl
ct_controls = [
  { control = "AWS-GR_ENCRYPTED_VOLUMES",               target = "workloads" },
  { control = "AWS-GR_EC2_INSTANCE_NO_PUBLIC_IP",        target = "workloads" },
  { control = "AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED", target = "workloads" },
]
```

`ct_controls_definition.tf` maps control names to global identifiers. Terraform rejects a name that is missing from that map at plan time and reports the name. Get the control's global identifier from AWS Control Catalog, for example with `aws controlcatalog list-controls`, and add it to the map before use. For the identifier format, see [Resource identifiers for APIs and controls](https://docs.aws.amazon.com/controltower/latest/controlreference/control-identifiers.html). Controls attach to OUs only — including the AWS Control Tower `Security` and `Sandbox` — and never to the root.

### Service Delegation

**Enable** — Set account IDs in `enable_delegation` for the services you want to delegate:

```hcl
enable_delegation = {
  guardduty   = { account_id = "111111111111" }
  securityhub = { account_id = "111111111111" }
  config      = { account_id = "111111111111" }
  inspector   = { account_id = "111111111111" }
}
```

Supported services, by configuration key: `access_analyzer` (IAM Access Analyzer), `backup` (AWS Backup), `cloudtrail` (AWS CloudTrail), `config` (AWS Config), `detective` (Amazon Detective), `firewall_manager` (AWS Firewall Manager), `guardduty` (Amazon GuardDuty), `inspector` (Amazon Inspector), `ipam` (Amazon VPC IP Address Manager), `macie` (Amazon Macie), `securityhub` (AWS Security Hub CSPM), `sso` (AWS IAM Identity Center), `stacksets` (AWS CloudFormation StackSets), `systems_manager` (AWS Systems Manager).

> **Note:** Setting `macie` also enables Amazon Macie in the management account (`aws_macie2_account`), which AWS requires before a delegated administrator can be designated. Removing the `macie` entry later disables it again.

## File Structure

```
├── main.tf                      # OUs (5 levels), AWS Control Tower baseline registration, AWS RAM sharing
├── locals.tf                    # OU flattening, SCP rendering, attachment maps
├── variables.tf                 # All inputs
├── outputs.tf                   # Organization + OU outputs
├── data.tf                      # Organization + Region data sources
├── versions.tf                  # Provider + version constraints
├── policies.tf                  # SCP + RCP + tag + backup + AI services opt-out + chat applications policy resources
├── delegation.tf                # Service delegations
├── control_tower.tf             # AWS Control Tower controls
├── ct_controls_definition.tf    # AWS Control Tower control identifier mapping
├── .gitlab-ci.yml               # Validation + security scanning (scan-only, no AWS access)
├── docs/diagrams/               # Architecture diagrams, rendered SVG and PNG
├── examples/                    # Use-case-specific tfvars — pass via -var-file
│   ├── minimal/                 # OU hierarchy only
│   ├── standard/                # SCP + RCP + tag policies + daily backup
│   ├── enterprise/              # All six managed policy types, 14 delegations, broad AWS Control Tower controls
│   ├── regulated-workload/      # Encryption, MFA and audit reporting + RCP + critical-tier backup + AI opt-out
│   └── data-residency/          # Region-locked OUs + SSL-required RCP + AI opt-out
└── policies/
    ├── scp/                     # Service control policy files (.json / .json.tpl)
    ├── rcp/                     # Resource control policy files
    ├── tag-policy/              # Tag policy JSON files
    ├── backup/                  # Backup policy files
    ├── ai-opt-out/              # AI services opt-out policy files
    └── chatbot/                 # Chat applications policy files
```

## Limits

| Limit                      | Value                                                                  |
| -------------------------- | ---------------------------------------------------------------------- |
| OU nesting                 | 5 levels                                                               |
| Policies attached per OU   | SCP 10, RCP 5, tag 10, backup 10, chat applications 5, AI services opt-out 5. SCP counts include `FullAWSAccess`; RCP counts include `RCPFullAWSAccess`, which you cannot detach |
| SCP size                   | 10,240 characters                                                      |
| RCP size                   | 5,120 characters                                                       |
| Tag policy size            | 10,000 characters                                                      |
| Backup policy size         | 10,000 characters                                                      |
| Chat applications policy size | 10,000 characters                                                      |
| AI services opt-out policy size | 2,500 characters                                                      |
| Policy types in AWS Organizations | This sample manages six (service control, resource control, tag, backup, AI services opt-out, chat applications); AWS Organizations offers more |
| Delegated admin accounts   | Per-service limits apply (most allow 1 per organization)               |

Each size limit above is enforced as a plan-time precondition. Terraform submits the document exactly as rendered, so, unlike the console, Terraform does not strip whitespace before AWS applies the limit.

See [AWS Organizations quotas](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_limits.html) for the authoritative list.

## Security

See [SECURITY.md](SECURITY.md) for how to report a security issue, the security model, and design choices a scanner may flag.

## License

This sample code is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.
