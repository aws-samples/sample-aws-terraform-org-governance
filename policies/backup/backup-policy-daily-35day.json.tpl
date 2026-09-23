{
  "plans": {
    "OrgDailyBackupPlan": {
      "regions": {
        "@@assign": ["${primary_region}"]
      },
      "rules": {
        "DailyBackup": {
          "schedule_expression": { "@@assign": "cron(0 5 ? * * *)" },
          "start_backup_window_minutes": { "@@assign": "60" },
          "complete_backup_window_minutes": { "@@assign": "1440" },
          "lifecycle": {
            "delete_after_days": { "@@assign": "35" }
          },
          "target_backup_vault_name": { "@@assign": "${vault_name}" }
        }
      },
      "selections": {
        "tags": {
          "BackupEligible": {
            "iam_role_arn": { "@@assign": "arn:aws:iam::$$account:role/service-role/AWSBackupDefaultServiceRole" },
            "tag_key": { "@@assign": "Backup" },
            "tag_value": { "@@assign": ["true"] }
          }
        }
      }
    }
  }
}
