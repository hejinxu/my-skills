import { formatIssueTable, formatProject, formatProjectBrief, formatSprint, formatSprintBrief, formatBoard, formatBoardBrief, formatJson } from '../../utils.js';
import {
  searchIssues, getIssue, createIssue, assignIssue, addComment,
  getTransitions, transitionIssue, getProjects, getProject, getProjectRoles,
  getMyself, getBoards, resolveBoardId, getSprints, getSprintIssues, jiraAgileGet
} from './client.js';

export function parseArgs(args) {
  const parsed = {};
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const value = args[i + 1] && !args[i + 1].startsWith('--') ? args[i + 1] : true;
      parsed[key] = value;
      if (value !== true) i++;
    }
  }
  return parsed;
}

export function printHelp() {
  console.log(`
Jira CLI Client

Usage: node jira.js <command> [options]

Commands:
  list-issues              List issues with filters
  get-issue                Get issue details
  create-issue             Create a new issue
  assign-issue             Assign an issue
  comment                  Add a comment
  transition               Transition an issue
  search                   Search with JQL
  list-projects            List all projects
  get-project              Get project details
  get-project-roles        Get project roles
  project-stats           Get project statistics
  list-boards              List all boards
  list-sprints             List sprints for a board
  current-sprint           Get current active sprint
  sprint-issues            Get issues in a sprint
  backlog-issues           Get backlog issues
  whoami                   Get current user info

Options:
  --project <key>          Project key
  --key <issue-key>        Issue key (e.g., PROJ-123)
  --jql <query>            JQL query string
  --status <status>        Issue status filter
  --type <type>            Issue type filter
  --assignee <user>        Assignee username
  --summary <text>         Issue summary
  --description <text>     Issue description
  --transition <name>      Transition name
  --comment <text>         Comment text
  --board <id-or-name>     Board ID or name
  --sprint-id <id>         Sprint ID
  --max-results <n>        Max results (default: 50)
`);
}

export async function executeCommand(config, command, options) {
  let result;

  switch (command) {
    case 'list-issues': {
      const jqlParts = [];
      if (options.project) jqlParts.push(`project = ${options.project}`);
      if (options.status) {
        const statuses = options.status.split(',').map(s => s.trim());
        const positive = statuses.filter(s => !s.startsWith('-'));
        const negative = statuses.filter(s => s.startsWith('-')).map(s => s.slice(1));
        if (positive.length) jqlParts.push(`status IN (${positive.map(s => `"${s}"`).join(',')})`);
        if (negative.length) jqlParts.push(`status NOT IN (${negative.map(s => `"${s}"`).join(',')})`);
      }
      if (options.type) jqlParts.push(`issuetype = "${options.type}"`);
      if (options.assignee) jqlParts.push(`assignee = "${options.assignee}"`);
      if (jqlParts.length === 0) jqlParts.push('status != Done');
      const jql = jqlParts.join(' AND ');
      result = await searchIssues(config, jql, { maxResults: options['max-results'] || 50 });
      console.log(`Found ${result.total} issues:\n`);
      console.log(formatIssueTable(result.issues));
      break;
    }

    case 'get-issue': {
      if (!options.key) { console.error('Error: --key is required'); process.exit(1); }
      result = await getIssue(config, options.key);
      console.log(formatJson(result));
      break;
    }

    case 'create-issue': {
      if (!options.project || !options.summary) {
        console.error('Error: --project and --summary are required');
        process.exit(1);
      }
      const issueData = {
        fields: {
          project: { key: options.project },
          summary: options.summary,
          issuetype: { name: options.type || 'Task' },
        }
      };
      if (options.description) {
        issueData.fields.description = options.description;
      }
      result = await createIssue(config, issueData);
      console.log(`Created issue: ${result.key}`);
      break;
    }

    case 'assign-issue': {
      if (!options.key || !options.assignee) {
        console.error('Error: --key and --assignee are required');
        process.exit(1);
      }
      await assignIssue(config, options.key, options.assignee);
      console.log(`Assigned ${options.key} to ${options.assignee}`);
      break;
    }

    case 'comment': {
      if (!options.key || !options.comment) {
        console.error('Error: --key and --comment are required');
        process.exit(1);
      }
      await addComment(config, options.key, options.comment);
      console.log(`Added comment to ${options.key}`);
      break;
    }

    case 'transition': {
      if (!options.key || !options.transition) {
        console.error('Error: --key and --transition are required');
        process.exit(1);
      }
      const transitions = await getTransitions(config, options.key);
      const target = transitions.transitions?.find(
        t => t.name.toLowerCase() === options.transition.toLowerCase()
      );
      if (!target) {
        console.error(`Transition "${options.transition}" not found. Available:`);
        transitions.transitions?.forEach(t => console.log(`  - ${t.name}`));
        process.exit(1);
      }
      await transitionIssue(config, options.key, target.id);
      console.log(`Transitioned ${options.key} to ${options.transition}`);
      break;
    }

    case 'search': {
      if (!options.jql) { console.error('Error: --jql is required'); process.exit(1); }
      result = await searchIssues(config, options.jql, { maxResults: options['max-results'] || 50 });
      console.log(`Found ${result.total} issues:\n`);
      console.log(formatIssueTable(result.issues));
      break;
    }

    case 'list-projects': {
      result = await getProjects(config);
      console.log(`Found ${result.length} projects:\n`);
      result.forEach(p => console.log(formatProjectBrief(p)));
      break;
    }

    case 'get-project': {
      if (!options.key) { console.error('Error: --key is required'); process.exit(1); }
      result = await getProject(config, options.key);
      console.log(formatJson(result));
      break;
    }

    case 'get-project-roles': {
      if (!options.key) { console.error('Error: --key is required'); process.exit(1); }
      result = await getProjectRoles(config, options.key);
      console.log(formatJson(result));
      break;
    }

    case 'project-stats': {
      if (!options.key) { console.error('Error: --key is required'); process.exit(1); }
      const statsJql = `project = ${options.key}`;
      const [openResult, doneResult, totalResult] = await Promise.all([
        searchIssues(config, `${statsJql} AND status NOT IN (Done, Closed, Resolved)`, { maxResults: 0 }),
        searchIssues(config, `${statsJql} AND status IN (Done, Closed, Resolved)`, { maxResults: 0 }),
        searchIssues(config, statsJql, { maxResults: 0 }),
      ]);
      console.log(`Project ${options.key} Statistics:`);
      console.log(`  Total: ${totalResult.total}`);
      console.log(`  Open: ${openResult.total}`);
      console.log(`  Done: ${doneResult.total}`);
      break;
    }

    case 'list-boards': {
      result = await getBoards(config);
      const boards = result.values || [];
      console.log(`Found ${boards.length} boards:\n`);
      boards.forEach(b => console.log(formatBoardBrief(b)));
      break;
    }

    case 'list-sprints': {
      if (!options.board) { console.error('Error: --board is required'); process.exit(1); }
      const boardIdentifier = await resolveBoardId(config, options.board);
      result = await getSprints(config, boardIdentifier);
      const sprints = result.values || [];
      console.log(`Found ${sprints.length} sprints:\n`);
      sprints.forEach(s => console.log(formatSprintBrief(s)));
      break;
    }

    case 'current-sprint': {
      if (!options.board) { console.error('Error: --board is required'); process.exit(1); }
      const boardIdentifier = await resolveBoardId(config, options.board);
      result = await getSprints(config, boardIdentifier, { state: 'active' });
      const activeSprints = result.values || [];
      if (activeSprints.length === 0) {
        console.log('No active sprint found');
      } else {
        activeSprints.forEach(s => console.log(formatJson(formatSprint(s))));
      }
      break;
    }

    case 'sprint-issues': {
      if (!options['sprint-id']) { console.error('Error: --sprint-id is required'); process.exit(1); }
      result = await getSprintIssues(config, options['sprint-id']);
      const issues = result.issues || [];
      console.log(`Found ${issues.length} issues in sprint:\n`);
      console.log(formatIssueTable(issues));
      break;
    }

    case 'backlog-issues': {
      if (!options.board) { console.error('Error: --board is required'); process.exit(1); }
      const boardIdentifier = await resolveBoardId(config, options.board);
      result = await jiraAgileGet(config, `/board/${boardIdentifier}/backlog`);
      const issues = result.issues || [];
      console.log(`Found ${issues.length} backlog issues:\n`);
      console.log(formatIssueTable(issues));
      break;
    }

    case 'whoami': {
      result = await getMyself(config);
      console.log(`Logged in as: ${result.displayName} (${result.name})`);
      console.log(`Email: ${result.emailAddress || 'N/A'}`);
      break;
    }

    default:
      console.error(`Unknown command: ${command}`);
      printHelp();
      process.exit(1);
  }
}
