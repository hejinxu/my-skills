---
description: Query, create, and manage Jira issues
agent: build
---

Execute the following Jira issues command using the CLI tool:

```
node "$env:USERPROFILE\.config\gs-skills\lib\jira.js" $ARGUMENTS
```

If no arguments provided, run:
```
node "$env:USERPROFILE\.config\gs-skills\lib\jira.js" search --jql "assignee = currentUser() AND status != Done"
```

Present the results clearly to the user.
