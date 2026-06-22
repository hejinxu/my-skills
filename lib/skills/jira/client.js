import https from 'https';

const API_VERSION = '2';

function getHeaders(config) {
  return {
    'Authorization': `Bearer ${config.pat}`,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

function buildUrl(config, endpoint, params = {}) {
  const base = config.base_url.replace(/\/+$/, '');
  const url = new URL(`/rest/api/${API_VERSION}${endpoint}`, base);
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      url.searchParams.set(key, String(value));
    }
  });
  return url.toString();
}

function buildAgileUrl(config, endpoint, params = {}) {
  const base = config.base_url.replace(/\/+$/, '');
  const url = new URL(`/rest/agile/1.0${endpoint}`, base);
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      url.searchParams.set(key, String(value));
    }
  });
  return url.toString();
}

async function request(config, url, options = {}) {
  const headers = getHeaders(config);
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const reqOptions = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname + urlObj.search,
      method: options.method || 'GET',
      headers: { ...headers, ...options.headers },
      rejectUnauthorized: false
    };

    const req = https.request(reqOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        if (res.statusCode < 200 || res.statusCode >= 300) {
          reject(new Error(`Jira API error ${res.statusCode}: ${data}`));
          return;
        }
        const contentType = res.headers['content-type'];
        if (contentType && contentType.includes('application/json')) {
          resolve(JSON.parse(data));
        } else {
          resolve(data);
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (options.body) {
      req.write(options.body);
    }
    req.end();
  });
}

export async function jiraGet(config, endpoint, params = {}) {
  const url = buildUrl(config, endpoint, params);
  return request(config, url);
}

export async function jiraPost(config, endpoint, body, params = {}) {
  const url = buildUrl(config, endpoint, params);
  return request(config, url, {
    method: 'POST',
    body: JSON.stringify(body),
  });
}

export async function jiraPut(config, endpoint, body, params = {}) {
  const url = buildUrl(config, endpoint, params);
  return request(config, url, {
    method: 'PUT',
    body: JSON.stringify(body),
  });
}

export async function jiraAgileGet(config, endpoint, params = {}) {
  const url = buildAgileUrl(config, endpoint, params);
  return request(config, url);
}

export async function searchIssues(config, jql, options = {}) {
  const params = {
    jql,
    maxResults: options.maxResults || 50,
    startAt: options.startAt || 0,
    fields: options.fields || 'summary,status,assignee,reporter,priority,issuetype,created,updated',
  };
  return jiraGet(config, '/search', params);
}

export async function getIssue(config, issueKey) {
  return jiraGet(config, `/issue/${issueKey}`);
}

export async function createIssue(config, issueData) {
  return jiraPost(config, '/issue', issueData);
}

export async function assignIssue(config, issueKey, assignee) {
  return jiraPut(config, `/issue/${issueKey}/assignee`, { name: assignee });
}

export async function addComment(config, issueKey, comment) {
  return jiraPost(config, `/issue/${issueKey}/comment`, { body: comment });
}

export async function getTransitions(config, issueKey) {
  return jiraGet(config, `/issue/${issueKey}/transitions`);
}

export async function transitionIssue(config, issueKey, transitionId, comment) {
  const body = { transition: { id: transitionId } };
  if (comment) {
    body.update = { comment: [{ add: { body: comment } }] };
  }
  return jiraPost(config, `/issue/${issueKey}/transitions`, body);
}

export async function getProjects(config) {
  return jiraGet(config, '/project');
}

export async function getProject(config, projectKey) {
  return jiraGet(config, `/project/${projectKey}`);
}

export async function getProjectRoles(config, projectKey) {
  return jiraGet(config, `/project/${projectKey}/role`);
}

export async function getMyself(config) {
  return jiraGet(config, '/myself');
}

export async function getBoards(config, params = {}) {
  return jiraAgileGet(config, '/board', params);
}

export async function resolveBoardId(config, boardInput) {
  const boardId = isNaN(boardInput) ? null : boardInput;
  if (boardId) return boardId;
  
  const boards = await getBoards(config);
  const found = boards.values?.find(b => b.name.toLowerCase() === boardInput.toLowerCase());
  if (!found) {
    console.error(`Board "${boardInput}" not found`);
    process.exit(1);
  }
  return found.id;
}

export async function getSprints(config, boardId, params = {}) {
  return jiraAgileGet(config, `/board/${boardId}/sprint`, params);
}

export async function getSprintIssues(config, sprintId, params = {}) {
  return jiraAgileGet(config, `/sprint/${sprintId}/issue`, params);
}
