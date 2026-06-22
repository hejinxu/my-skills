---
name: jira-issues
description: Use when querying, creating, updating, or managing Jira issues. Supports list, search, get, create, assign, transition, comment operations. Use for tasks like "list unclosed issues", "show my assigned issues", "create a bug ticket", "search Jira issues".
trigger: /jira-issues
---

# /jira-issues

Query, create, and manage Jira issues via REST API.

## Configuration

This skill reads Jira configuration in order of priority:
1. Environment variables: `JIRA_BASE_URL`, `JIRA_PAT`
2. Project config: `<project-root>/.config/gs-skills/config.json`
3. Global config: `~/.config/gs-skills/config.json`

Config file format:
```json
{
  "jira": {
    "base_url": "https://your-jira-domain.com",
    "pat": "your_personal_access_token",
    "default_project": "PROJ"
  }
}
```

Config file format:
```json
{
  "base_url": "https://your-jira-domain.com",
  "pat": "your_personal_access_token",
  "default_project": "PROJ"
}
```

## Script Location

The jira client script is located at:
`$HOME/.config/gs-skills/lib/jira.js`

## Usage

```
/jira-issues list <project> [--status open] [--type bug] [--assignee username]
/jira-issues search "<jql>"
/jira-issues get <issue-key>
/jira-issues create <project> <summary> [--type Story] [--description "desc"]
/jira-issues assign <issue-key> <username>
/jira-issues transition <issue-key> <status>
/jira-issues comment <issue-key> "<comment text>"
/jira-issues assigned [--project PROJ]
/jira-issues mine [--project PROJ]
```

## What You Must Do When Invoked

### Step 1 - Determine the script path

Find where the jira.js script is located. Check these locations in order:
1. `$JIRA_SKILLS_HOME/lib/jira.js` (if env var set)
2. `$HOME/.config/gs-skills/lib/jira.js` (Linux/Mac/Windows with Git Bash)

Use the first path that exists.

### Step 2 - Run the command

Based on the user's request, construct and run the appropriate command:

**List open issues in a project:**
```bash
node {SCRIPT_PATH} list-issues --project {PROJECT_KEY} --status "To Do,In Progress,Open"
```

**List all unclosed issues (not Done/Closed/Resolved):**
```bash
node {SCRIPT_PATH} list-issues --project {PROJECT_KEY} --status "-Done,-Closed,-Resolved"
```

**Search with JQL:**
```bash
node {SCRIPT_PATH} search --jql "{JQL_QUERY}"
```

**Get issue details:**
```bash
node {SCRIPT_PATH} get-issue --key {ISSUE_KEY}
```

**Get issues assigned to current user:**
```bash
node {SCRIPT_PATH} search --jql "assignee = currentUser() AND status != Done"
```

**Get issues created by current user:**
```bash
node {SCRIPT_PATH} search --jql "reporter = currentUser() AND status != Done"
```

**Create a new issue:**
```bash
node {SCRIPT_PATH} create-issue --project {PROJECT_KEY} --summary "{SUMMARY}" --type "{ISSUE_TYPE}"
```

**Assign an issue:**
```bash
node {SCRIPT_PATH} assign-issue --key {ISSUE_KEY} --assignee {USERNAME}
```

**Transition an issue:**
```bash
node {SCRIPT_PATH} transition --key {ISSUE_KEY} --transition "{STATUS_NAME}"
```

**Add a comment:**
```bash
node {SCRIPT_PATH} comment --key {ISSUE_KEY} --comment "{COMMENT_TEXT}"
```

### Step 3 - Present results

Format the output clearly for the user:
- For lists: show key, summary, status, assignee, priority
- For single issues: show all relevant fields
- For errors: explain what went wrong and suggest fixes

## Common JQL Patterns

- All open issues: `project = PROJ AND status NOT IN (Done, Closed, Resolved)`
- Assigned to me: `assignee = currentUser() AND status != Done`
- Created by me: `reporter = currentUser() AND status != Done`
- High priority bugs: `project = PROJ AND type = Bug AND priority in (Highest, High)`
- Updated this week: `project = PROJ AND updated >= -7d`
- My issues in sprint: `assignee = currentUser() AND sprint in openSprints()`

## Error Handling

If the script fails:
1. Check if JIRA_BASE_URL and JIRA_PAT are configured
2. Verify the Jira server is accessible
3. Check if the project key or issue key exists
4. Ensure the user has permission for the operation
