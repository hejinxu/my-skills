#!/usr/bin/env node

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

import { loadConfig } from './config.js';
import { parseArgs, printHelp, executeCommand } from './skills/jira/commands.js';

async function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  const options = parseArgs(args.slice(1));

  if (!command || command === '--help' || command === '-h') {
    printHelp();
    process.exit(0);
  }

  const config = loadConfig('jira', {
    base_url: 'JIRA_BASE_URL',
    pat: 'JIRA_PAT',
    default_project: 'JIRA_DEFAULT_PROJECT'
  });
  if (!config.base_url || !config.pat) {
    console.error('Error: Jira configuration missing. Set JIRA_BASE_URL and JIRA_PAT environment variables, or create ~/.skills/config.json');
    process.exit(1);
  }

  try {
    await executeCommand(config, command, options);
  } catch (error) {
    console.error(`Error: ${error.message}`);
    console.error(`Stack: ${error.stack}`);
    process.exit(1);
  }
}

main();
