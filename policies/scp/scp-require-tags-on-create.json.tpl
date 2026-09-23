{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RequireMandatoryTagsOnEC2Volume",
      "Effect": "Deny",
      "Action": "ec2:CreateVolume",
      "Resource": "*",
      "Condition": {
        "Null": {
          "aws:RequestTag/Environment": "true",
          "aws:RequestTag/Team": "true",
          "aws:RequestTag/CostCenter": "true"
        }
      }
    },
    {
      "Sid": "RequireMandatoryTagsOnEC2Instance",
      "Effect": "Deny",
      "Action": "ec2:RunInstances",
      "Resource": [
        "arn:aws:ec2:*:*:instance/*",
        "arn:aws:ec2:*:*:volume/*"
      ],
      "Condition": {
        "Null": {
          "aws:RequestTag/Environment": "true",
          "aws:RequestTag/Team": "true",
          "aws:RequestTag/CostCenter": "true"
        }
      }
    },
    {
      "Sid": "RequireMandatoryTagsOnRDS",
      "Effect": "Deny",
      "Action": [
        "rds:CreateDBInstance",
        "rds:CreateDBCluster"
      ],
      "Resource": "*",
      "Condition": {
        "Null": {
          "aws:RequestTag/Environment": "true",
          "aws:RequestTag/Team": "true",
          "aws:RequestTag/CostCenter": "true"
        }
      }
    },
    {
      "Sid": "RequireMandatoryTagsOnS3",
      "Effect": "Deny",
      "Action": "s3:CreateBucket",
      "Resource": "*",
      "Condition": {
        "Null": {
          "aws:RequestTag/Environment": "true",
          "aws:RequestTag/Team": "true",
          "aws:RequestTag/CostCenter": "true"
        }
      }
    }
  ]
}
