# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

################################################################################
# Organizational Units — up to 5 nesting levels
################################################################################

resource "aws_organizations_organizational_unit" "level_1_ous" {
  for_each  = { for record in local.level_1_ou_arguments : record.key => record }
  name      = each.value.name
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "level_2_ous" {
  for_each  = { for record in local.level_2_ou_arguments : record.key => record }
  name      = each.value.name
  parent_id = aws_organizations_organizational_unit.level_1_ous[each.value.parent].id
}

resource "aws_organizations_organizational_unit" "level_3_ous" {
  for_each  = { for record in local.level_3_ou_arguments : record.key => record }
  name      = each.value.name
  parent_id = aws_organizations_organizational_unit.level_2_ous[each.value.parent].id
}

resource "aws_organizations_organizational_unit" "level_4_ous" {
  for_each  = { for record in local.level_4_ou_arguments : record.key => record }
  name      = each.value.name
  parent_id = aws_organizations_organizational_unit.level_3_ous[each.value.parent].id
}

resource "aws_organizations_organizational_unit" "level_5_ous" {
  for_each  = { for record in local.level_5_ou_arguments : record.key => record }
  name      = each.value.name
  parent_id = aws_organizations_organizational_unit.level_4_ous[each.value.parent].id
}

################################################################################
# Control Tower baseline registration — parent before child
################################################################################

resource "aws_controltower_baseline" "level_1" {
  for_each = {
    for record in local.level_1_ou_arguments : record.key => record if record.ct_register
  }

  baseline_identifier = local.ct_baseline_arn
  baseline_version    = var.ct_baseline_version
  target_identifier   = aws_organizations_organizational_unit.level_1_ous[each.key].arn

  dynamic "parameters" {
    for_each = var.ct_identity_center_baseline_arn != "" ? [1] : []
    content {
      key   = "IdentityCenterEnabledBaselineArn"
      value = var.ct_identity_center_baseline_arn
    }
  }
}

resource "aws_controltower_baseline" "level_2" {
  for_each = {
    for record in local.level_2_ou_arguments : record.key => record if record.ct_register
  }

  baseline_identifier = local.ct_baseline_arn
  baseline_version    = var.ct_baseline_version
  target_identifier   = aws_organizations_organizational_unit.level_2_ous[each.key].arn

  dynamic "parameters" {
    for_each = var.ct_identity_center_baseline_arn != "" ? [1] : []
    content {
      key   = "IdentityCenterEnabledBaselineArn"
      value = var.ct_identity_center_baseline_arn
    }
  }

  depends_on = [aws_controltower_baseline.level_1]
}

resource "aws_controltower_baseline" "level_3" {
  for_each = {
    for record in local.level_3_ou_arguments : record.key => record if record.ct_register
  }

  baseline_identifier = local.ct_baseline_arn
  baseline_version    = var.ct_baseline_version
  target_identifier   = aws_organizations_organizational_unit.level_3_ous[each.key].arn

  dynamic "parameters" {
    for_each = var.ct_identity_center_baseline_arn != "" ? [1] : []
    content {
      key   = "IdentityCenterEnabledBaselineArn"
      value = var.ct_identity_center_baseline_arn
    }
  }

  depends_on = [aws_controltower_baseline.level_2]
}

resource "aws_controltower_baseline" "level_4" {
  for_each = {
    for record in local.level_4_ou_arguments : record.key => record if record.ct_register
  }

  baseline_identifier = local.ct_baseline_arn
  baseline_version    = var.ct_baseline_version
  target_identifier   = aws_organizations_organizational_unit.level_4_ous[each.key].arn

  dynamic "parameters" {
    for_each = var.ct_identity_center_baseline_arn != "" ? [1] : []
    content {
      key   = "IdentityCenterEnabledBaselineArn"
      value = var.ct_identity_center_baseline_arn
    }
  }

  depends_on = [aws_controltower_baseline.level_3]
}

resource "aws_controltower_baseline" "level_5" {
  for_each = {
    for record in local.level_5_ou_arguments : record.key => record if record.ct_register
  }

  baseline_identifier = local.ct_baseline_arn
  baseline_version    = var.ct_baseline_version
  target_identifier   = aws_organizations_organizational_unit.level_5_ous[each.key].arn

  dynamic "parameters" {
    for_each = var.ct_identity_center_baseline_arn != "" ? [1] : []
    content {
      key   = "IdentityCenterEnabledBaselineArn"
      value = var.ct_identity_center_baseline_arn
    }
  }

  depends_on = [aws_controltower_baseline.level_4]
}

################################################################################
# RAM — organization-wide resource sharing
################################################################################

resource "aws_ram_sharing_with_organization" "this" {
  count = var.enable_ram_sharing ? 1 : 0
}
