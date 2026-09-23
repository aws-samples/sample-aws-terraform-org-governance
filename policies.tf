# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#
# Policy document size limits enforced below come from
# https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_limits.html
# Terraform submits the document exactly as rendered, so unlike the console no
# whitespace is stripped before the limit is applied.

################################################################################
# Service Control Policies (SCPs)
################################################################################

resource "aws_organizations_policy" "scp" {
  for_each = var.scp_policies

  name        = each.key
  content     = local.scp_content[each.key]
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"

  lifecycle {
    precondition {
      condition     = length(local.scp_content[each.key]) <= 10240
      error_message = "SCP '${each.key}' exceeds the 10240-character AWS limit after rendering (${length(local.scp_content[each.key])} characters)."
    }
  }
}

resource "aws_organizations_policy_attachment" "scp" {
  for_each = local.scp_attachments

  policy_id = aws_organizations_policy.scp[each.value.name].id
  target_id = lookup(local.policy_target_ids, lower(each.value.target), null)

  lifecycle {
    precondition {
      condition     = contains(keys(local.policy_target_ids), lower(each.value.target))
      error_message = "SCP '${each.value.name}' targets '${each.value.target}', which is not an OU key defined in var.organization, an OU already under the root, or \"root\"."
    }
  }
}

################################################################################
# Resource Control Policies (RCPs)
#
# RCPs restrict what can be done to resources in your accounts, even by
# external principals and AWS services. Complement SCPs which only restrict
# IAM principals within your member accounts.
################################################################################

resource "aws_organizations_policy" "rcp" {
  for_each = var.rcp_policies

  name        = each.key
  content     = local.rcp_content[each.key]
  description = each.value.description
  type        = "RESOURCE_CONTROL_POLICY"

  lifecycle {
    precondition {
      condition     = length(local.rcp_content[each.key]) <= 5120
      error_message = "RCP '${each.key}' exceeds the 5120-character AWS limit after rendering (${length(local.rcp_content[each.key])} characters)."
    }
  }
}

resource "aws_organizations_policy_attachment" "rcp" {
  for_each = local.rcp_attachments

  policy_id = aws_organizations_policy.rcp[each.value.name].id
  target_id = lookup(local.policy_target_ids, lower(each.value.target), null)

  lifecycle {
    precondition {
      condition     = contains(keys(local.policy_target_ids), lower(each.value.target))
      error_message = "RCP '${each.value.name}' targets '${each.value.target}', which is not an OU key defined in var.organization, an OU already under the root, or \"root\"."
    }
  }
}

################################################################################
# Tag Policies
################################################################################

resource "aws_organizations_policy" "tagging_policy" {
  for_each = var.tagging_policies

  name        = each.key
  content     = local.tag_policy_content[each.key]
  description = each.value.description
  type        = "TAG_POLICY"

  lifecycle {
    precondition {
      condition     = length(local.tag_policy_content[each.key]) <= 10000
      error_message = "Tag policy '${each.key}' exceeds the 10000-character AWS limit after rendering (${length(local.tag_policy_content[each.key])} characters)."
    }
  }
}

resource "aws_organizations_policy_attachment" "tagging_policy" {
  for_each = local.tag_policy_attachments

  policy_id = aws_organizations_policy.tagging_policy[each.value.name].id
  target_id = lookup(local.policy_target_ids, lower(each.value.target), null)

  lifecycle {
    precondition {
      condition     = contains(keys(local.policy_target_ids), lower(each.value.target))
      error_message = "Tag policy '${each.value.name}' targets '${each.value.target}', which is not an OU key defined in var.organization, an OU already under the root, or \"root\"."
    }
  }
}

################################################################################
# Backup Policies
#
# Org-wide AWS Backup plans applied to member accounts via AWS Backup org
# integration.
################################################################################

resource "aws_organizations_policy" "backup" {
  for_each = var.backup_policies

  name        = each.key
  content     = local.backup_content[each.key]
  description = each.value.description
  type        = "BACKUP_POLICY"

  lifecycle {
    precondition {
      condition     = length(local.backup_content[each.key]) <= 10000
      error_message = "Backup policy '${each.key}' exceeds the 10000-character AWS limit after rendering (${length(local.backup_content[each.key])} characters)."
    }
  }
}

resource "aws_organizations_policy_attachment" "backup" {
  for_each = local.backup_attachments

  policy_id = aws_organizations_policy.backup[each.value.name].id
  target_id = lookup(local.policy_target_ids, lower(each.value.target), null)

  lifecycle {
    precondition {
      condition     = contains(keys(local.policy_target_ids), lower(each.value.target))
      error_message = "Backup policy '${each.value.name}' targets '${each.value.target}', which is not an OU key defined in var.organization, an OU already under the root, or \"root\"."
    }
  }
}

################################################################################
# AI Services Opt-Out Policies
#
# Opt the organization out of AWS using your content for AI/ML service
# improvement (Rekognition, Transcribe, Comprehend, Textract, etc.).
################################################################################

resource "aws_organizations_policy" "ai_opt_out" {
  for_each = var.ai_opt_out_policies

  name        = each.key
  content     = local.ai_opt_out_content[each.key]
  description = each.value.description
  type        = "AISERVICES_OPT_OUT_POLICY"

  lifecycle {
    precondition {
      condition     = length(local.ai_opt_out_content[each.key]) <= 2500
      error_message = "AI opt-out policy '${each.key}' exceeds the 2500-character AWS limit after rendering (${length(local.ai_opt_out_content[each.key])} characters)."
    }
  }
}

resource "aws_organizations_policy_attachment" "ai_opt_out" {
  for_each = local.ai_opt_out_attachments

  policy_id = aws_organizations_policy.ai_opt_out[each.value.name].id
  target_id = lookup(local.policy_target_ids, lower(each.value.target), null)

  lifecycle {
    precondition {
      condition     = contains(keys(local.policy_target_ids), lower(each.value.target))
      error_message = "AI opt-out policy '${each.value.name}' targets '${each.value.target}', which is not an OU key defined in var.organization, an OU already under the root, or \"root\"."
    }
  }
}

################################################################################
# Chatbot Policies
#
# Restrict which Slack workspaces and Microsoft Teams channels can integrate
# with AWS accounts via AWS Chatbot.
################################################################################

resource "aws_organizations_policy" "chatbot" {
  for_each = var.chatbot_policies

  name        = each.key
  content     = local.chatbot_content[each.key]
  description = each.value.description
  type        = "CHATBOT_POLICY"

  lifecycle {
    precondition {
      condition     = length(local.chatbot_content[each.key]) <= 10000
      error_message = "Chatbot policy '${each.key}' exceeds the 10000-character AWS limit after rendering (${length(local.chatbot_content[each.key])} characters)."
    }
  }
}

resource "aws_organizations_policy_attachment" "chatbot" {
  for_each = local.chatbot_attachments

  policy_id = aws_organizations_policy.chatbot[each.value.name].id
  target_id = lookup(local.policy_target_ids, lower(each.value.target), null)

  lifecycle {
    precondition {
      condition     = contains(keys(local.policy_target_ids), lower(each.value.target))
      error_message = "Chatbot policy '${each.value.name}' targets '${each.value.target}', which is not an OU key defined in var.organization, an OU already under the root, or \"root\"."
    }
  }
}
