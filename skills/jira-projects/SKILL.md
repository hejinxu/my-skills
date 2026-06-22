---
name: jira-projects
description: Use when listing, viewing, or managing Jira projects. Supports list projects, get project details, view members, get project statistics. Use for tasks like "list all Jira projects", "show project details", "who is in this project".
trigger: /jira-projects
---

# /jira-projects

List, view, and manage Jira projects via REST API.

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
/jira-projects list
/jira-projects get <project-key>
/jira-projects members <project-key>
/jira-projects stats <project-key>
```

## What You Must Do When Invoked

### Step 1 - Determine the script path

Find where the jira.js script is located. Check these locations in order:
1. `$JIRA_SKILLS_HOME/lib/jira.js` (if env var set)
2. `$HOME/.config/gs-skills/lib/jira.js` (Linux/Mac/Windows with Git Bash)

Use the first path that exists.

### Step 2 - Run the command

Based on the user's request, construct and run the appropriate command:

**List all projects:**
```bash
node {SCRIPT_PATH} list-projects
```

**Get project details:**
```bash
node {SCRIPT_PATH} get-project --key {PROJECT_KEY}
```

**Get project members (roles):**
```bash
node {SCRIPT_PATH} get-project-roles --key {PROJECT_KEY}
```

**Get project statistics:**
```bash
node {SCRIPT_PATH} project-stats --key {PROJECT_KEY}
```

### Step 3 - Present results

Format the output clearly:
- For project list: show key, name, lead, type
- For project details: show all relevant fields
- For members: list roles and their members
- For stats: show issue counts by status, type, priority

## Common Use Cases

- **Find a project**: `list` then search by name
- **Check project health**: `stats` to see issue distribution
- **Find team members**: `members` to see who's assigned
- **Verify project exists**: `get` with project key

## Error Handling

If the script fails:
1. Check if JIRA_BASE_URL and JIRA_PAT are configured
2. Verify the Jira server is accessible
3. Check if the project key exists
4. Ensure the user has permission to view the project
