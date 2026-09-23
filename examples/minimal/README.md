# Minimal Example

Lay down an OU hierarchy on top of Control Tower — nothing else.

## When to Use

- First-time setup. You just want your OU structure in place.
- You plan to add SCPs, tag policies, CT controls, and delegations later, one at a time.
- You want to see what the bare minimum config looks like.

## What Gets Created

```
Root
├── Security        (CT-managed — not in this config)
├── Sandbox         (CT-managed — not in this config)
├── Infrastructure  ← created
└── Workloads       ← created
```

Both new OUs are registered with the Control Tower baseline.

## Next Steps

Once this applies cleanly:

1. Add SCPs — start with `scp-foundation-guardrails` (see `standard` example)
2. Add tag policies (see `standard` example)
3. Enable CT controls for your Workloads OU (see `enterprise` example for the common set)
4. Delegate security services to a central account (see `enterprise` or `regulated-workload`)

## Apply

```bash
terraform plan -var-file=examples/minimal/terraform.tfvars
terraform apply -var-file=examples/minimal/terraform.tfvars
```
