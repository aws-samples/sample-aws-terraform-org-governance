# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

################################################################################
# Global
################################################################################

variable "tags" {
  description = "Tags applied to all resources created by this deployment via provider default_tags"
  type        = map(string)
}

variable "aws_region" {
  description = "AWS region for the provider. Should match your Control Tower home region."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region (e.g., us-east-1, eu-west-2)."
  }
}

################################################################################
# Organizational Units
################################################################################

variable "organization" {
  description = "OU hierarchy — structure only. SCPs and controls are assigned separately. Each `key` must be unique across all nesting levels; keys are how policies and controls address an OU."
  type = object({
    units = optional(list(object({
      name        = string
      key         = string
      ct_register = optional(bool, true)
      units = optional(list(object({
        name        = string
        key         = string
        ct_register = optional(bool, true)
        units = optional(list(object({
          name        = string
          key         = string
          ct_register = optional(bool, true)
          units = optional(list(object({
            name        = string
            key         = string
            ct_register = optional(bool, true)
            units = optional(list(object({
              name        = string
              key         = string
              ct_register = optional(bool, true)
            })), [])
          })), [])
        })), [])
      })), [])
    })), [])
  })
  default = {}
}

################################################################################
# Control Tower
################################################################################

variable "ct_baseline_version" {
  description = "CT baseline version to enable on governed OUs"
  type        = string
  default     = "5.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.ct_baseline_version))
    error_message = "CT baseline version must be in format X.Y (e.g., 5.0)."
  }
}

variable "ct_identity_center_baseline_arn" {
  description = "ARN of enabled IdentityCenterBaseline. Leave empty if not using Identity Center."
  type        = string
  default     = ""

  validation {
    condition     = var.ct_identity_center_baseline_arn == "" || can(regex("^arn:aws:controltower:[a-z0-9-]+:[0-9]{12}:enabledbaseline/[A-Z0-9]+$", var.ct_identity_center_baseline_arn))
    error_message = "ct_identity_center_baseline_arn must be empty or a valid enabledbaseline ARN."
  }
}

variable "ct_controls" {
  description = "CT control assignments — each entry maps a control name to a target OU key. Controls target OUs only, never the root."
  type = list(object({
    control = string
    target  = string
  }))
  default = []

  validation {
    condition     = alltrue([for c in var.ct_controls : length(c.control) > 0 && length(c.target) > 0])
    error_message = "Each CT control must have a non-empty control name and target OU key."
  }

  validation {
    condition     = alltrue([for c in var.ct_controls : contains(keys(local.ct_control_ids), c.control)])
    error_message = "Unknown CT control name(s): ${join(", ", [for c in var.ct_controls : c.control if !contains(keys(local.ct_control_ids), c.control)])}. Add the global identifier to ct_controls_definition.tf — see https://docs.aws.amazon.com/controltower/latest/controlreference/all-global-identifiers.html"
  }
}

################################################################################
# Service Control Policies (SCPs)
################################################################################

variable "scp_policies" {
  description = "SCPs — each entry defines the policy file path, template vars, description, and target OU keys."
  type = map(object({
    description = string
    path        = string
    vars        = optional(map(string), {})
    targets     = list(string)
  }))
  default = {}
}

################################################################################
# Resource Control Policies (RCPs)
################################################################################

variable "rcp_policies" {
  description = "Resource Control Policies (RCPs). RCPs restrict what resources can be accessed, even by external principals. Complements SCPs."
  type = map(object({
    description = string
    path        = string
    vars        = optional(map(string), {})
    targets     = list(string)
  }))
  default = {}
}

################################################################################
# Tag Policies
################################################################################

variable "tagging_policies" {
  description = "Tag policies to attach to OUs. Key = policy name, value = file path, template vars, description, and target OU keys."
  type = map(object({
    description = string
    path        = string
    vars        = optional(map(string), {})
    targets     = list(string)
  }))
  default = {}
}

################################################################################
# Backup Policies
################################################################################

variable "backup_policies" {
  description = "AWS Backup policies — org-wide backup plans applied to target OUs."
  type = map(object({
    description = string
    path        = string
    vars        = optional(map(string), {})
    targets     = list(string)
  }))
  default = {}
}

################################################################################
# AI Services Opt-Out Policies
################################################################################

variable "ai_opt_out_policies" {
  description = "AI Services opt-out policies — prevent AWS AI services from using your content for model improvement."
  type = map(object({
    description = string
    path        = string
    vars        = optional(map(string), {})
    targets     = list(string)
  }))
  default = {}
}

################################################################################
# Chatbot Policies
################################################################################

variable "chatbot_policies" {
  description = "AWS Chatbot policies — restrict which Slack/Teams integrations can interact with AWS accounts."
  type = map(object({
    description = string
    path        = string
    vars        = optional(map(string), {})
    targets     = list(string)
  }))
  default = {}
}

################################################################################
# RAM Sharing
################################################################################

variable "enable_ram_sharing" {
  description = "Allow cross-account resource sharing via RAM across the org"
  type        = bool
  default     = false
}

################################################################################
# Service Delegation
################################################################################

variable "enable_delegation" {
  description = "Delegate AWS service admin to member accounts. Set account_id per service to enable. Setting `macie` also enables Macie in the management account, which is a prerequisite for designating its delegated administrator."
  type = object({
    access_analyzer  = optional(object({ account_id = string }), null)
    backup           = optional(object({ account_id = string }), null)
    cloudtrail       = optional(object({ account_id = string }), null)
    config           = optional(object({ account_id = string }), null)
    detective        = optional(object({ account_id = string }), null)
    firewall_manager = optional(object({ account_id = string }), null)
    guardduty        = optional(object({ account_id = string }), null)
    inspector        = optional(object({ account_id = string }), null)
    ipam             = optional(object({ account_id = string }), null)
    macie            = optional(object({ account_id = string }), null)
    organizations    = optional(object({ account_id = string }), null)
    securityhub      = optional(object({ account_id = string }), null)
    sso              = optional(object({ account_id = string }), null)
    stacksets        = optional(object({ account_id = string }), null)
    systems_manager  = optional(object({ account_id = string }), null)
  })
  default = {}

  validation {
    condition = alltrue([
      for svc, cfg in var.enable_delegation :
      cfg == null ? true : can(regex("^[0-9]{12}$", cfg.account_id))
    ])
    error_message = "Each delegation account_id must be a 12-digit AWS account ID."
  }
}
