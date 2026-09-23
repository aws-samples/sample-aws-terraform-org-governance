# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

################################################################################
# Control Tower Controls
################################################################################

resource "aws_controltower_control" "controls" {
  for_each = local.ct_control_attachments

  control_identifier = "arn:aws:controlcatalog:::control/${lookup(local.ct_control_ids, each.value.control, "")}"
  target_identifier  = lookup(local.control_target_arns, lower(each.value.ou_key), null)

  lifecycle {
    precondition {
      condition     = contains(keys(local.ct_control_ids), each.value.control)
      error_message = "CT control '${each.value.control}' is not in the ct_control_ids map. Add its global identifier to ct_controls_definition.tf — see https://docs.aws.amazon.com/controltower/latest/controlreference/all-global-identifiers.html"
    }

    precondition {
      condition     = contains(keys(local.control_target_arns), lower(each.value.ou_key))
      error_message = "CT control '${each.value.control}' targets '${each.value.ou_key}', which is not an OU key defined in var.organization or an OU already under the root. Controls cannot target the root."
    }
  }

  depends_on = [
    aws_controltower_baseline.level_1,
  ]
}
