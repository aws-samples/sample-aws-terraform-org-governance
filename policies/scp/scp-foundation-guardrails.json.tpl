{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyOrgLeave",
      "Effect": "Deny",
      "Action": "organizations:LeaveOrganization",
      "Resource": "*"
    },
    {
      "Sid": "DenyIMDSv1Launch",
      "Effect": "Deny",
      "Action": "ec2:RunInstances",
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringNotEquals": { "ec2:MetadataHttpTokens": "required" }
      }
    },
    {
      "Sid": "DenyIMDSv1Modification",
      "Effect": "Deny",
      "Action": "ec2:ModifyInstanceMetadataOptions",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": { "ec2:MetadataHttpTokens": "required" },
        "ArnNotLike": { "aws:PrincipalARN": "arn:aws:iam::*:role/${breakglass_role}" }
      }
    },
    {
      "Sid": "DenyUnencryptedEBS",
      "Effect": "Deny",
      "Action": ["ec2:CreateVolume","ec2:RunInstances"],
      "Resource": "arn:aws:ec2:*:*:volume/*",
      "Condition": {
        "Bool": { "ec2:Encrypted": "false" }
      }
    },
    {
      "Sid": "DenyUnencryptedRDS",
      "Effect": "Deny",
      "Action": "rds:CreateDBInstance",
      "Resource": "*",
      "Condition": {
        "Bool": { "rds:StorageEncrypted": "false" }
      }
    },
    {
      "Sid": "DenyExternalRAMSharing",
      "Effect": "Deny",
      "Action": ["ram:CreateResourceShare","ram:UpdateResourceShare"],
      "Resource": "*",
      "Condition": {
        "Bool": { "ram:RequestedAllowsExternalPrincipals": "true" }
      }
    }
  ]
}
