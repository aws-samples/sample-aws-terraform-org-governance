# Standard Example — Typical mid-size setup
#
# Use case: A growing company that wants foundational guardrails,
# tag governance, and a sensible OU hierarchy. No service delegation
# or CT controls yet — add those as the org matures.
#
# What this sets up:
#   Root
#   ├── Infrastructure
#   └── Workloads
#       ├── Production
#       └── Non-Production
#           ├── Development
#           └── Staging
#
# SCP:           foundation guardrails on Infrastructure + Workloads
# RCP:           require SSL for S3/SQS/Secrets Manager on Workloads
# Tag policies:  mandatory + recommended across Workloads + Infrastructure
# Backup policy: daily 35-day retention for resources tagged Backup=true

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
      units = [
        {
          name        = "Production"
          key         = "workloads/production"
          ct_register = true
        },
        {
          name        = "Non-Production"
          key         = "workloads/non-production"
          ct_register = true
          units = [
            {
              name        = "Development"
              key         = "workloads/non-production/development"
              ct_register = true
            },
            {
              name        = "Staging"
              key         = "workloads/non-production/staging"
              ct_register = true
            },
          ]
        },
      ]
    },
  ]
}

scp_policies = {
  "scp-foundation-guardrails" = {
    description = "Foundation: deny org leave, IMDSv2, encryption, RAM external sharing"
    path        = "policies/scp/scp-foundation-guardrails.json.tpl"
    vars        = { breakglass_role = "BreakGlass-Admin" }
    targets     = ["infrastructure", "workloads"]
  }
}

rcp_policies = {
  "rcp-require-ssl" = {
    description = "Require SSL for S3, SQS, Secrets Manager — applies even to cross-account access"
    path        = "policies/rcp/rcp-require-ssl.json"
    vars        = {}
    targets     = ["workloads"]
  }
}

backup_policies = {
  "backup-daily-35day" = {
    description = "Daily backups, 35-day retention for resources tagged Backup=true"
    path        = "policies/backup/backup-policy-daily-35day.json.tpl"
    vars = {
      primary_region = "us-east-1"
      vault_name     = "OrgDefaultBackupVault"
    }
    targets = ["workloads"]
  }
}

tagging_policies = {
  "tag-policy-mandatory" = {
    description = "Mandatory tag policy: enforce allowed values for Environment, Team, CostCenter, ManagedBy"
    path        = "policies/tag-policy/tag-policy-mandatory.json"
    targets     = ["workloads", "infrastructure"]
  }
  "tag-policy-recommended" = {
    description = "Recommended tag policy: enforce key casing for Name, Owner, Description"
    path        = "policies/tag-policy/tag-policy-recommended.json"
    targets     = ["workloads", "infrastructure"]
  }
}

ct_baseline_version             = "5.0"
ct_identity_center_baseline_arn = ""
enable_ram_sharing              = false
