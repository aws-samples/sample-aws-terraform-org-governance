{
  "plans": {
    "CriticalWorkloadBackupPlan": {
      "regions": {
        "@@assign": ["${primary_region}", "${dr_region}"]
      },
      "rules": {
        "DailyBackup": {
          "schedule_expression": { "@@assign": "cron(0 5 ? * * *)" },
          "start_backup_window_minutes": { "@@assign": "60" },
          "complete_backup_window_minutes": { "@@assign": "1440" },
          "lifecycle": {
            "move_to_cold_storage_after_days": { "@@assign": "30" },
            "delete_after_days": { "@@assign": "90" }
          },
          "target_backup_vault_name": { "@@assign": "${vault_name}" },
          "copy_actions": {
            "arn:aws:backup:${dr_region}:$$account:backup-vault:${dr_vault_name}": {
              "lifecycle": {
                "move_to_cold_storage_after_days": { "@@assign": "30" },
                "delete_after_days": { "@@assign": "365" }
              }
            }
          }
        },
        "WeeklyBackup": {
          "schedule_expression": { "@@assign": "cron(0 5 ? * SUN *)" },
          "start_backup_window_minutes": { "@@assign": "60" },
          "complete_backup_window_minutes": { "@@assign": "1440" },
          "lifecycle": {
            "move_to_cold_storage_after_days": { "@@assign": "90" },
            "delete_after_days": { "@@assign": "2555" }
          },
          "target_backup_vault_name": { "@@assign": "${vault_name}" }
        }
      },
      "selections": {
        "tags": {
          "CriticalBackup": {
            "iam_role_arn": { "@@assign": "arn:aws:iam::$$account:role/service-role/AWSBackupDefaultServiceRole" },
            "tag_key": { "@@assign": "BackupTier" },
            "tag_value": { "@@assign": ["critical"] }
          }
        }
      }
    }
  }
}
