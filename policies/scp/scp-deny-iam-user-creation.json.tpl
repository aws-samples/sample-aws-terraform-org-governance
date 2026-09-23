{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyIAMUserCreation",
      "Effect": "Deny",
      "Action": [
        "iam:CreateUser",
        "iam:CreateLoginProfile",
        "iam:CreateAccessKey",
        "iam:UpdateAccessKey",
        "iam:UpdateLoginProfile"
      ],
      "Resource": "arn:aws:iam::*:user/*",
      "Condition": {
        "ArnNotLike": {
          "aws:PrincipalARN": [
            "arn:aws:iam::*:role/${breakglass_role}",
            "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*"
          ]
        }
      }
    }
  ]
}
