export function formatIssue(issue) {
  const fields = issue.fields;
  const key = issue.key;
  const summary = fields.summary || '';
  const status = fields.status?.name || 'Unknown';
  const assignee = fields.assignee?.displayName || 'Unassigned';
  const reporter = fields.reporter?.displayName || 'Unknown';
  const priority = fields.priority?.name || 'None';
  const issueType = fields.issuetype?.name || 'Unknown';
  const created = fields.created ? new Date(fields.created).toLocaleDateString() : '';
  const updated = fields.updated ? new Date(fields.updated).toLocaleDateString() : '';

  return {
    key,
    summary,
    status,
    assignee,
    reporter,
    priority,
    issueType,
    created,
    updated,
  };
}

export function formatIssueBrief(issue) {
  const f = formatIssue(issue);
  return `[${f.key}] ${f.summary} (${f.status}, ${f.assignee})`;
}

export function formatIssueTable(issues) {
  if (!issues || issues.length === 0) {
    return 'No issues found.';
  }

  const formatted = issues.map(formatIssue);
  const lines = ['Key | Summary | Status | Assignee | Priority | Type', '--- | --- | --- | --- | --- | ---'];
  
  formatted.forEach(f => {
    lines.push(`${f.key} | ${f.summary} | ${f.status} | ${f.assignee} | ${f.priority} | ${f.issueType}`);
  });

  return lines.join('\n');
}

export function formatProject(project) {
  return {
    key: project.key,
    name: project.name,
    id: project.id,
    lead: project.lead?.displayName || 'Unknown',
    projectTypeKey: project.projectTypeKey || 'Unknown',
  };
}

export function formatProjectBrief(project) {
  const f = formatProject(project);
  return `[${f.key}] ${f.name} (Lead: ${f.lead})`;
}

export function formatSprint(sprint) {
  return {
    id: sprint.id,
    name: sprint.name,
    state: sprint.state,
    startDate: sprint.startDate || 'N/A',
    endDate: sprint.endDate || 'N/A',
    goal: sprint.goal || '',
    originBoardId: sprint.originBoardId,
  };
}

export function formatSprintBrief(sprint) {
  const f = formatSprint(sprint);
  return `[${f.id}] ${f.name} (${f.state})`;
}

export function formatBoard(board) {
  return {
    id: board.id,
    name: board.name,
    type: board.type,
    projectKeyOrId: board.location?.projectKey || 'Unknown',
  };
}

export function formatBoardBrief(board) {
  const f = formatBoard(board);
  return `[${f.id}] ${f.name} (${f.type})`;
}

export function truncate(str, maxLength = 100) {
  if (!str) return '';
  if (str.length <= maxLength) return str;
  return str.substring(0, maxLength - 3) + '...';
}

export function formatJson(obj) {
  return JSON.stringify(obj, null, 2);
}
