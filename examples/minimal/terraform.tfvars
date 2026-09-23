# Minimal Example — Just the OU structure, nothing else
#
# Use case: You want to lay down a clean OU hierarchy on top of Control Tower
# without attaching any SCPs, tag policies, CT controls, or delegations yet.
# Add features incrementally later.
#
# What this sets up:
#   Root
#   ├── Security        (CT-managed — not in this config)
#   ├── Sandbox         (CT-managed — not in this config)
#   ├── Infrastructure
#   └── Workloads

tags = {
  Project   = "org-governance"
  ManagedBy = "Terraform"
}

organization = {
  units = [
    {
      name        = "Infrastructure"
      key         = "infrastructure"
      ct_register = true
    },
    {
      name        = "Workloads"
      key         = "workloads"
      ct_register = true
    },
  ]
}

ct_baseline_version = "5.0"
