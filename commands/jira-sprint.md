---
description: Manage Jira sprints, boards, and agile projects
agent: build
---

Execute the following Jira sprint command using the CLI tool:

```
node "$env:USERPROFILE\.config\gs-skills\lib\jira.js" $ARGUMENTS
```

If no arguments provided, run:
```
node "$env:USERPROFILE\.config\gs-skills\lib\jira.js" list-boards
```

Present the results clearly to the user.
