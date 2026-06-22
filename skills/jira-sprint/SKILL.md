---
name: jira-sprint
description: Use when querying or managing Jira sprints, boards, and agile project data. Supports list boards, list sprints, get current sprint, view sprint issues. Use for tasks like "show current sprint", "list sprints", "what's in the sprint", "show agile boards".
trigger: /jira-sprint
---

# /jira-sprint

Query and manage Jira sprints and boards via Agile REST API.

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
/jira-sprint boards
/jira-sprint list <board-id-or-name>
/jira-sprint current <board-id-or-name>
/jira-sprint issues <sprint-id>
/jira-sprint backlog <board-id-or-name>
```

## What You Must Do When Invoked

### Step 1 - Determine the script path

Find where the jira.js script is located. Check these locations in order:
1. `$JIRA_SKILLS_HOME/lib/jira.js` (if env var set)
2. `$HOME/.config/gs-skills/lib/jira.js` (Linux/Mac/Windows with Git Bash)

Use the first path that exists.

### Step 2 - Run the command

Based on the user's request, construct and run the appropriate command:

**List all boards:**
```bash
node {SCRIPT_PATH} list-boards
```

**List sprints for a board:**
```bash
node {SCRIPT_PATH} list-sprints --board {BOARD_ID_OR_NAME}
```

**Get current (active) sprint:**
```bash
node {SCRIPT_PATH} current-sprint --board {BOARD_ID_OR_NAME}
```

**Get issues in a sprint:**
```bash
node {SCRIPT_PATH} sprint-issues --sprint-id {SPRINT_ID}
```

**Get backlog issues:**
```bash
node {SCRIPT_PATH} backlog-issues --board {BOARD_ID_OR_NAME}
```

### Step 3 - Present results

Format the output clearly:
- For boards: show id, name, type
- For sprints: show id, name, state, dates, goal
- For sprint issues: show key, summary, status, assignee
- For current sprint: highlight sprint goal and progress

## Common Use Cases

- **Check sprint progress**: `current` to see active sprint
- **Plan next sprint**: `backlog` to see available issues
- **Review completed work**: `issues` with completed sprint
- **Find the right board**: `boards` to list all boards

## Sprint States

- **future**: Planned but not started
- **active**: Currently in progress
- **closed**: Completed

## Error Handling

If the script fails:
1. Check if JIRA_BASE_URL and JIRA_PAT are configured
2. Verify the Jira server is accessible
3. Check if the board ID or name exists
4. Ensure the user has permission to view the board/sprint
