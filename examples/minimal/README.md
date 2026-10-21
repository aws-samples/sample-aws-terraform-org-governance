# Minimal Example

Lay down an OU hierarchy on top of AWS Control Tower — nothing else.

## When to Use

- First-time setup. You just want your OU structure in place.
- You plan to add SCPs, tag policies, AWS Control Tower controls, and delegations later, one at a time.
- You want to see what the bare minimum config looks like.

## What Gets Created

```
Root
├── Security        (managed by AWS Control Tower — not in this config)
├── Sandbox         (managed by AWS Control Tower — not in this config)
├── Infrastructure  ← created
└── Workloads       ← created
```

Both new OUs are registered with the AWS Control Tower baseline.

## Next Steps

Once this applies cleanly:

1. Add SCPs — start with `scp-foundation-guardrails` (see `standard` example)
2. Add tag policies (see `standard` example)
3. Enable AWS Control Tower controls for your Workloads OU (see `enterprise` example for the common set)
4. Delegate security services to a central account (see `enterprise` or `regulated-workload`)

## Apply

```bash
terraform plan -var-file=examples/minimal/terraform.tfvars
terraform apply -var-file=examples/minimal/terraform.tfvars
```
