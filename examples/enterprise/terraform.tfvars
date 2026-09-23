# Enterprise Example — All features enabled
#
# Use case: A large organization with mature security practices,
# dedicated security/network/automation accounts, and strict governance.
#
# What this sets up:
#   Root
#   ├── Infrastructure
#   │   ├── Network
#   │   └── Shared Services
#   ├── Workloads
#   │   ├── Production
#   │   └── Non-Production
#   │       ├── Development
#   │       ├── Staging
#   │       └── QA
#   ├── Deployments
#   │   └── CI/CD
#   └── Data
#       ├── Analytics
#       └── Data Lake
#
# All 15 service delegations point to purpose-specific accounts.
# Foundation SCPs applied across all custom OUs.
# RCP: require SSL + confused-deputy protection on Workloads/Data.
# Backup policy: daily + weekly with DR region copy on Workloads/Data.
# AI opt-out: organization-wide opt out of AI service content use.
# Chatbot policy: restrict to approved Slack workspaces and Teams.
# CT controls for encryption, network, S3, logging, and IAM across Workloads.
# Tag policies enforced everywhere.

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
      units = [
        { name = "Network", key = "infrastructure/network", ct_register = true },
        { name = "Shared Services", key = "infrastructure/shared-services", ct_register = true },
      ]
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
            { name = "Development", key = "workloads/non-production/development", ct_register = true },
            { name = "Staging", key = "workloads/non-production/staging", ct_register = true },
            { name = "QA", key = "workloads/non-production/qa", ct_register = true },
          ]
        },
      ]
    },
    {
      name        = "Deployments"
      key         = "deployments"
      ct_register = true
      units = [
        { name = "CI/CD", key = "deployments/cicd", ct_register = true },
      ]
    },
    {
      name        = "Data"
      key         = "data"
      ct_register = true
      units = [
        { name = "Analytics", key = "data/analytics", ct_register = true },
        { name = "Data Lake", key = "data/data-lake", ct_register = true },
      ]
    },
  ]
}

scp_policies = {
  "scp-foundation-guardrails" = {
    description = "Foundation: deny org leave, IMDSv2, encryption, RAM external sharing"
    path        = "policies/scp/scp-foundation-guardrails.json.tpl"
    vars        = { breakglass_role = "BreakGlass-Admin" }
    targets     = ["infrastructure", "workloads", "deployments", "data"]
  }
}

ct_baseline_version             = "5.0"
ct_identity_center_baseline_arn = "arn:aws:controltower:us-east-1:123456789012:enabledbaseline/XXXXXXXXXXXXXXXX"
enable_ram_sharing              = true

rcp_policies = {
  "rcp-require-ssl" = {
    description = "Require SSL for S3, SQS, Secrets Manager — applies even to cross-account access"
    path        = "policies/rcp/rcp-require-ssl.json"
    vars        = {}
    targets     = ["workloads", "data"]
  }
  "rcp-confused-deputy-protection" = {
    description = "Block external-principal access and enforce aws:SourceAccount for service principals"
    path        = "policies/rcp/rcp-enforce-confused-deputy-protection.json.tpl"
    vars        = {}
    targets     = ["workloads", "data"]
  }
}

backup_policies = {
  "backup-critical-daily-weekly" = {
    description = "Daily + weekly backups with DR region copy for resources tagged BackupTier=critical"
    path        = "policies/backup/backup-policy-critical-daily-weekly.json.tpl"
    vars = {
      primary_region = "us-east-1"
      dr_region      = "us-west-2"
      vault_name     = "OrgCentralBackupVault"
      dr_vault_name  = "OrgDRBackupVault"
    }
    targets = ["workloads", "data"]
  }
}

ai_opt_out_policies = {
  "ai-opt-out-all" = {
    description = "Opt out of AWS using org content for AI/ML service improvement"
    path        = "policies/ai-opt-out/ai-opt-out-all.json"
    targets     = ["root"]
  }
}

chatbot_policies = {
  "chatbot-approved-workspaces" = {
    description = "Only allow Chatbot integrations with approved Slack workspaces and Teams"
    path        = "policies/chatbot/chatbot-restrict-to-approved-workspaces.json.tpl"
    vars = {
      slack_workspace_ids = "[\"T0123456789\"]"
      teams_team_ids      = "[\"00000000-0000-0000-0000-000000000000\"]"
    }
    targets = ["root"]
  }
}

ct_controls = [
  # Encryption
  { control = "AWS-GR_ENCRYPTED_VOLUMES", target = "workloads" },
  { control = "AWS-GR_ENCRYPTED_VOLUMES", target = "data" },

  # Network
  { control = "AWS-GR_EC2_INSTANCE_NO_PUBLIC_IP", target = "workloads" },
  { control = "AWS-GR_SUBNET_AUTO_ASSIGN_PUBLIC_IP_DISABLED", target = "workloads" },
  { control = "AWS-GR_RESTRICTED_SSH", target = "workloads" },

  # S3
  { control = "AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED", target = "workloads" },
  { control = "AWS-GR_S3_BUCKET_PUBLIC_WRITE_PROHIBITED", target = "workloads" },
  { control = "AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED", target = "data" },
  { control = "AWS-GR_S3_BUCKET_PUBLIC_WRITE_PROHIBITED", target = "data" },

  # Logging
  { control = "AWS-GR_CLOUDTRAIL_VALIDATION_ENABLED", target = "workloads" },
  { control = "AWS-GR_CLOUDTRAIL_VALIDATION_ENABLED", target = "infrastructure" },

  # IAM
  { control = "AWS-GR_IAM_USER_MFA_ENABLED", target = "workloads" },
  { control = "AWS-GR_ROOT_ACCOUNT_MFA_ENABLED", target = "workloads" },
]

tagging_policies = {
  "tag-policy-mandatory" = {
    description = "Mandatory tag policy: enforce allowed values for Environment, Team, CostCenter, ManagedBy"
    path        = "policies/tag-policy/tag-policy-mandatory.json"
    targets     = ["workloads", "infrastructure", "deployments", "data"]
  }
  "tag-policy-recommended" = {
    description = "Recommended tag policy: enforce key casing for Name, Owner, Description"
    path        = "policies/tag-policy/tag-policy-recommended.json"
    targets     = ["workloads", "infrastructure", "data"]
  }
}

enable_delegation = {
  access_analyzer  = { account_id = "111111111111" } # Security Tooling account
  backup           = { account_id = "222222222222" } # Infrastructure account
  cloudtrail       = { account_id = "111111111111" } # Security Tooling account
  config           = { account_id = "111111111111" } # Security Tooling account
  detective        = { account_id = "111111111111" } # Security Tooling account
  firewall_manager = { account_id = "333333333333" } # Network account
  guardduty        = { account_id = "111111111111" } # Security Tooling account
  inspector        = { account_id = "111111111111" } # Security Tooling account
  ipam             = { account_id = "333333333333" } # Network account
  macie            = { account_id = "111111111111" } # Security Tooling account
  organizations    = { account_id = "444444444444" } # Automation account
  securityhub      = { account_id = "111111111111" } # Security Tooling account
  sso              = { account_id = "555555555555" } # Identity account
  stacksets        = { account_id = "222222222222" } # Infrastructure account
  systems_manager  = { account_id = "222222222222" } # Infrastructure account
}
