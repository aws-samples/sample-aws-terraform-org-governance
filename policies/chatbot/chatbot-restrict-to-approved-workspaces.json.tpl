{
  "chatbot": {
    "platforms": {
      "slack": {
        "workspaces": {
          "@@assign": ${slack_workspace_ids}
        }
      },
      "microsoft_teams": {
        "teams": {
          "@@assign": ${teams_team_ids}
        }
      }
    }
  }
}
