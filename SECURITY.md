# Security

## Reporting a security issue

If you discover a potential security issue in this project, notify AWS/Amazon Security through the [vulnerability reporting page](https://aws.amazon.com/security/vulnerability-reporting/). Do **not** create a public GitHub issue.

This is sample code with no versioned releases. Fixes are made on the `main` branch.

## Security model

- **Runs in one place.** Terraform runs only in the organization management account and calls control-plane APIs: AWS Organizations, AWS Control Tower, and the delegated administrator APIs of the services listed in the README.
- **Provisions no data-plane resources.** It creates no compute, storage, network or database resources, and deploys nothing into member accounts. The one exception: setting the Amazon Macie delegation enables Macie in the management account, because AWS requires that before a Macie delegated administrator can be designated.
- **Requires no secrets.** No input takes a key, token or password. All account IDs in the example configurations are placeholders.
- **State contains identifiers only.** Terraform state records OU, policy and attachment identifiers, not credentials. Store it in an encrypted, access-controlled backend all the same, since it maps your organization's structure.

## Before you deploy

- **Policies take effect immediately on attachment** and apply to every account in the target OU and below. Attach a new deny policy to a non-production OU first and confirm its effect.
- **Keep a break-glass exemption.** The foundation service control policy takes a `breakglass_role` template variable so an emergency role is excluded from its deny statements. Do not remove it without a replacement.
- **A successful destroy can reduce your security posture.** Detaching or deleting a service control policy or resource control policy restores the permissions it was denying, and Terraform reports this as success. Read every `terraform plan` before applying it.
- **Deploy with a least-privilege role** using temporary credentials, scoped to the capabilities you actually deploy. The delegation actions differ per service, so most deployments need only a subset.
- **Commit your own provider lock file.** This repository does not ship `.terraform.lock.hcl`, so the AWS provider resolves within the `~> 6.0` constraint at `terraform init`. Pin it with a lock file in your own repository before production use.

## Design choices a scanner may flag

| Finding | Why it is intentional |
| --- | --- |
| `"Resource": "*"` in service control and resource control policy documents | A guardrail has to cover every resource the denied action can reach. Scope comes from the OU the policy is attached to and from each statement's `Condition` element, not from resource ARNs. |
| Service-wide action wildcards such as `ce:*` in deny statements | A deny guardrail that lists individual actions leaves gaps whenever a service adds an action. Denying the service namespace is the reliable form. |
| No `.terraform.lock.hcl` in the repository | Sample code consumers are expected to manage their own lock file. See above. |

This is sample code, for non-production usage. You should work with your security and legal teams to meet your organizational security, regulatory and compliance requirements before deployment.
