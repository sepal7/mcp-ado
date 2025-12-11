#!/usr/bin/env node

/**
 * MCP Server for Azure DevOps
 * Enhanced with Microsoft official features + Azure deployment optimization
 * Provides comprehensive access to Azure DevOps services via Model Context Protocol
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ErrorCode,
  McpError,
} from '@modelcontextprotocol/sdk/types.js';
import axios from 'axios';
import dotenv from 'dotenv';
import * as appInsights from 'applicationinsights';

// Load environment variables
dotenv.config();

const AZURE_DEVOPS_ORG = process.env.AZURE_DEVOPS_ORG || 'YourOrganization';
const AZURE_DEVOPS_PROJECT = process.env.AZURE_DEVOPS_PROJECT || 'YourProject';
const AZURE_DEVOPS_PAT = process.env.AZURE_DEVOPS_PAT;
const AZURE_DEVOPS_WIKI = process.env.AZURE_DEVOPS_WIKI || `${AZURE_DEVOPS_PROJECT}.wiki`;
const APPINSIGHTS_CONNECTION_STRING = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;

if (!AZURE_DEVOPS_PAT) {
  console.error('Error: AZURE_DEVOPS_PAT environment variable is required');
  process.exit(1);
}

// Initialize Application Insights if connection string is provided
let telemetryClient = null;
if (APPINSIGHTS_CONNECTION_STRING) {
  appInsights.setup(APPINSIGHTS_CONNECTION_STRING)
    .setAutoDependencyCorrelation(true)
    .setAutoCollectRequests(true)
    .setAutoCollectPerformance(true)
    .setAutoCollectExceptions(true)
    .setAutoCollectDependencies(true)
    .setAutoCollectConsole(true)
    .setUseDiskRetryCaching(true)
    .start();
  
  telemetryClient = appInsights.defaultClient;
  telemetryClient.context.tags[telemetryClient.context.keys.cloudRole] = 'mcp-ado-server';
  console.error('Application Insights initialized');
} else {
  console.error('Application Insights not configured - set APPLICATIONINSIGHTS_CONNECTION_STRING');
}

// Azure DevOps API base URL (default project)
const DEFAULT_ADO_BASE_URL = `https://dev.azure.com/${AZURE_DEVOPS_ORG}/${AZURE_DEVOPS_PROJECT}/_apis`;

// Create basic auth header for PAT
const authHeader = Buffer.from(`:${AZURE_DEVOPS_PAT}`).toString('base64');

// Helper function to make ADO API calls
// Supports multiple projects via optional project parameter
async function adoApiCall(endpoint, params = {}, method = 'GET', body = null, project = null, contentType = 'application/json') {
  const startTime = Date.now();
  const queryString = new URLSearchParams({
    'api-version': '7.1',
    ...params,
  }).toString();
  
  // Use specified project or default
  const projectName = project || AZURE_DEVOPS_PROJECT;
  const baseUrl = `https://dev.azure.com/${AZURE_DEVOPS_ORG}/${projectName}/_apis`;
  const url = `${baseUrl}${endpoint}?${queryString}`;
  
  const config = {
    headers: {
      Authorization: `Basic ${authHeader}`,
      'Content-Type': contentType,
    },
  };
  
  let response;
  let success = true;
  let statusCode = 200;
  
  try {
    if (method === 'GET') {
      response = await axios.get(url, config);
    } else if (method === 'POST') {
      response = await axios.post(url, body, config);
    } else if (method === 'PATCH') {
      response = await axios.patch(url, body, config);
    } else if (method === 'PUT') {
      response = await axios.put(url, body, config);
    } else if (method === 'DELETE') {
      response = await axios.delete(url, config);
    } else {
      throw new Error(`Unsupported HTTP method: ${method}`);
    }
    
    statusCode = response.status;
  } catch (error) {
    success = false;
    statusCode = error.response?.status || 0;
    
    // Check for expired PAT token
    if (statusCode === 401) {
      const errorMessage = error.response?.data?.message || error.message;
      if (errorMessage && (errorMessage.includes('expired') || errorMessage.includes('Access Denied') || errorMessage.includes('Personal Access Token'))) {
        const helpfulError = new Error(
          `Azure DevOps PAT token has expired. Please update your PAT token:\n\n` +
          `1. Generate a new PAT at: https://dev.azure.com/${AZURE_DEVOPS_ORG}/_usersSettings/tokens\n` +
          `2. Run: .\\update-pat.ps1 -NewPAT "your_new_token_here"\n` +
          `3. Restart Cursor/VS Code and the MCP server\n\n` +
          `Original error: ${errorMessage}`
        );
        error.response.data = { ...error.response.data, helpfulMessage: helpfulError.message };
      }
    }
    
    // Track failed API call
    if (telemetryClient) {
      telemetryClient.trackDependency({
        name: `ADO API ${method} ${endpoint}`,
        data: url,
        duration: Date.now() - startTime,
        success: false,
        resultCode: statusCode,
        properties: {
          endpoint,
          method,
          project: projectName,
          error: error.message,
          isExpiredToken: statusCode === 401,
        },
      });
    }
    
    throw error;
  }
  
  // Track successful API call
  if (telemetryClient) {
    telemetryClient.trackDependency({
      name: `ADO API ${method} ${endpoint}`,
      data: url,
      duration: Date.now() - startTime,
      success: true,
      resultCode: statusCode,
      properties: {
        endpoint,
        method,
        project: projectName,
      },
    });
  }
  
  return response.data;
}

/**
 * Create MCP server instance
 */
const server = new Server(
  {
    name: 'ado-server',
    version: '2.0.0',
    description: 'Azure DevOps MCP Server - Enhanced with Microsoft official features + Azure deployment',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

/**
 * List available tools
 */
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      // Wiki Tools
      {
        name: 'get_wiki_page',
        description: 'Retrieve a specific Azure DevOps wiki page by ID or path',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            wiki: { type: 'string', description: 'Wiki name (default: project wiki)' },
            pageId: { type: 'string', description: 'Wiki page ID' },
            path: { type: 'string', description: 'Wiki page path' },
            includeContent: { type: 'boolean', description: 'Include page content', default: true },
          },
        },
      },
      {
        name: 'list_wiki_pages',
        description: 'List all pages in a wiki',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            wiki: { type: 'string', description: 'Wiki name' },
            recursive: { type: 'boolean', description: 'Include sub-pages', default: false },
          },
        },
      },
      {
        name: 'search_wiki_pages',
        description: 'Search wiki pages by content or title',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            query: { type: 'string', description: 'Search query' },
            wiki: { type: 'string', description: 'Wiki name' },
          },
          required: ['query'],
        },
      },
      // Repository Tools
      {
        name: 'list_repos',
        description: 'List all repositories in the project',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            includeLinks: { type: 'boolean', description: 'Include links', default: false },
          },
        },
      },
      {
        name: 'get_repo',
        description: 'Get repository details by name',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            repo: { type: 'string', description: 'Repository name' },
          },
          required: ['repo'],
        },
      },
      {
        name: 'get_repo_file',
        description: 'Get file content from a repository',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            repo: { type: 'string', description: 'Repository name' },
            path: { type: 'string', description: 'File path in repository' },
            branch: { type: 'string', description: 'Branch name (default: main)' },
            download: { type: 'boolean', description: 'Download as text', default: true },
          },
          required: ['repo', 'path'],
        },
      },
      {
        name: 'list_repo_branches',
        description: 'List branches in a repository',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            repo: { type: 'string', description: 'Repository name' },
            includeLinks: { type: 'boolean', description: 'Include links', default: false },
          },
          required: ['repo'],
        },
      },
      {
        name: 'search_code',
        description: 'Search code across repositories',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            searchText: { type: 'string', description: 'Search query' },
            repo: { type: 'string', description: 'Repository name (optional)' },
            $top: { type: 'number', description: 'Max results', default: 10 },
          },
          required: ['searchText'],
        },
      },
      // Work Items Tools
      {
        name: 'get_work_item',
        description: 'Get work item details by ID',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            workItemId: { type: 'number', description: 'Work item ID' },
            fields: { type: 'string', description: 'Comma-separated field names' },
            expand: { type: 'string', description: 'Expand options: all, relations, fields', default: 'all' },
          },
          required: ['workItemId'],
        },
      },
      {
        name: 'get_work_items',
        description: 'Get multiple work items by IDs',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            workItemIds: { type: 'array', items: { type: 'number' }, description: 'Array of work item IDs' },
            fields: { type: 'string', description: 'Comma-separated field names' },
            expand: { type: 'string', description: 'Expand options', default: 'all' },
          },
          required: ['workItemIds'],
        },
      },
      {
        name: 'query_work_items',
        description: 'Query work items using WIQL (Work Item Query Language)',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            wiql: { type: 'string', description: 'WIQL query string' },
            $top: { type: 'number', description: 'Max results', default: 100 },
          },
          required: ['wiql'],
        },
      },
      {
        name: 'create_work_item',
        description: 'Create a new work item',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            type: { type: 'string', description: 'Work item type (e.g., Task, Bug, User Story)' },
            title: { type: 'string', description: 'Work item title' },
            description: { type: 'string', description: 'Work item description' },
            fields: { type: 'object', description: 'Additional fields as key-value pairs' },
          },
          required: ['type', 'title'],
        },
      },
      {
        name: 'update_work_item',
        description: 'Update an existing work item',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            workItemId: { type: 'number', description: 'Work item ID' },
            fields: { type: 'object', description: 'Fields to update as key-value pairs' },
            links: { type: 'array', description: 'Array of links to add. Each link should have rel and url properties', items: { type: 'object', properties: { rel: { type: 'string' }, url: { type: 'string' } } } },
            removeLinks: { type: 'array', description: 'Array of link URLs to remove', items: { type: 'string' } },
          },
          required: ['workItemId'],
        },
      },
      // Pull Request Tools
      {
        name: 'list_pull_requests',
        description: 'List pull requests in a repository',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            repo: { type: 'string', description: 'Repository name' },
            status: { type: 'string', description: 'PR status: active, completed, abandoned, all', default: 'active' },
            $top: { type: 'number', description: 'Max results', default: 10 },
          },
          required: ['repo'],
        },
      },
      {
        name: 'get_pull_request',
        description: 'Get pull request details',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            repo: { type: 'string', description: 'Repository name' },
            pullRequestId: { type: 'number', description: 'Pull request ID' },
            includeCommits: { type: 'boolean', description: 'Include commits', default: false },
            includeWorkItems: { type: 'boolean', description: 'Include linked work items', default: false },
          },
          required: ['repo', 'pullRequestId'],
        },
      },
      {
        name: 'get_pr_comments',
        description: 'Get pull request review comments',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            repo: { type: 'string', description: 'Repository name' },
            pullRequestId: { type: 'number', description: 'Pull request ID' },
            $top: { type: 'number', description: 'Max results', default: 100 },
          },
          required: ['repo', 'pullRequestId'],
        },
      },
      // Build/Pipeline Tools
      {
        name: 'list_builds',
        description: 'List recent builds',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            definitionId: { type: 'number', description: 'Build definition ID (optional)' },
            status: { type: 'string', description: 'Build status filter' },
            result: { type: 'string', description: 'Build result filter' },
            $top: { type: 'number', description: 'Max results', default: 10 },
          },
        },
      },
      {
        name: 'get_build',
        description: 'Get build details by ID',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            buildId: { type: 'number', description: 'Build ID' },
          },
          required: ['buildId'],
        },
      },
      {
        name: 'list_pipelines',
        description: 'List pipelines in the project',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            $top: { type: 'number', description: 'Max results', default: 10 },
          },
        },
      },
      {
        name: 'get_pipeline_run',
        description: 'Get pipeline run details',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            pipelineId: { type: 'number', description: 'Pipeline ID' },
            runId: { type: 'number', description: 'Run ID' },
          },
          required: ['pipelineId', 'runId'],
        },
      },
      // Release/Deployment Tools
      {
        name: 'list_releases',
        description: 'List releases',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            definitionId: { type: 'number', description: 'Release definition ID (optional)' },
            status: { type: 'string', description: 'Release status filter' },
            $top: { type: 'number', description: 'Max results', default: 10 },
          },
        },
      },
      {
        name: 'get_release',
        description: 'Get release details',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            releaseId: { type: 'number', description: 'Release ID' },
          },
          required: ['releaseId'],
        },
      },
      // Test Plans Tools
      {
        name: 'list_test_plans',
        description: 'List test plans',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            $top: { type: 'number', description: 'Max results', default: 10 },
          },
        },
      },
      {
        name: 'get_test_plan',
        description: 'Get test plan details',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            planId: { type: 'number', description: 'Test plan ID' },
          },
          required: ['planId'],
        },
      },
      // Generic Tool
      {
        name: 'ado_api_call',
        description: 'Make a generic Azure DevOps REST API call',
        inputSchema: {
          type: 'object',
          properties: {
            project: { type: 'string', description: 'Project name (default: YourProject). Specify any project name in your organization' },
            endpoint: { type: 'string', description: 'API endpoint (e.g., /git/repositories)' },
            method: { type: 'string', description: 'HTTP method (GET, POST, PATCH, PUT, DELETE)', default: 'GET' },
            params: { type: 'object', description: 'Query parameters' },
            body: { type: 'object', description: 'Request body (for POST/PATCH/PUT)' },
          },
          required: ['endpoint'],
        },
      },
    ],
  };
});

/**
 * Handle tool calls
 */
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const startTime = Date.now();
  
  // Extract project parameter (defaults to configured project)
  const project = args?.project || null;

  // Track incoming MCP tool call
  if (telemetryClient) {
    telemetryClient.trackEvent({
      name: 'MCP Tool Call',
      properties: {
        toolName: name,
        project: project || AZURE_DEVOPS_PROJECT,
        hasArgs: !!args,
      },
    });
  }

  try {
    switch (name) {
      case 'get_wiki_page': {
        const wiki = args?.wiki || AZURE_DEVOPS_WIKI;
        const pageId = args?.pageId;
        const path = args?.path;
        const includeContent = args?.includeContent !== false;

        if (!pageId && !path) {
          throw new McpError(ErrorCode.InvalidParams, 'Either pageId or path must be provided');
        }

        const endpoint = pageId 
          ? `/wiki/wikis/${wiki}/pages/${pageId}`
          : `/wiki/wikis/${wiki}/pages`;
        const params = pageId ? {} : { path };
        if (includeContent) params.includeContent = 'true';
        
        const data = await adoApiCall(endpoint, params, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              pageId: data.id,
              path: data.path,
              content: data.content,
              url: data.url,
              gitItemPath: data.gitItemPath,
            }, null, 2),
          }],
        };
      }

      case 'list_wiki_pages': {
        const wiki = args?.wiki || AZURE_DEVOPS_WIKI;
        const recursive = args?.recursive || false;
        const data = await adoApiCall(`/wiki/wikis/${wiki}/pages`, { recursive: recursive.toString() }, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              pages: data.value?.map(p => ({ id: p.id, path: p.path, url: p.url })),
            }, null, 2),
          }],
        };
      }

      case 'search_wiki_pages': {
        const wiki = args?.wiki || AZURE_DEVOPS_WIKI;
        const query = args?.query;
        const data = await adoApiCall(`/wiki/wikis/${wiki}/pages`, { 
          $filter: `contains(path, '${query}')` 
        }, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              pages: data.value?.map(p => ({ id: p.id, path: p.path, url: p.url })),
            }, null, 2),
          }],
        };
      }

      case 'list_repos': {
        const data = await adoApiCall('/git/repositories', { 
          includeLinks: (args?.includeLinks || false).toString() 
        }, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              repositories: data.value?.map(r => ({
                id: r.id,
                name: r.name,
                url: r.url,
                defaultBranch: r.defaultBranch,
                size: r.size,
              })),
            }, null, 2),
          }],
        };
      }

      case 'get_repo': {
        const repo = args?.repo;
        const data = await adoApiCall(`/git/repositories/${repo}`, {}, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              id: data.id,
              name: data.name,
              url: data.url,
              defaultBranch: data.defaultBranch,
              size: data.size,
              remoteUrl: data.remoteUrl,
            }, null, 2),
          }],
        };
      }

      case 'get_repo_file': {
        const repo = args?.repo;
        const path = args?.path;
        const branch = args?.branch || 'main';
        const download = args?.download !== false;
        
        const data = await adoApiCall(`/git/repositories/${repo}/items/${path}`, {
          versionDescriptorVersion: branch,
          versionDescriptorVersionType: 'branch',
          download: download.toString(),
        }, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              path: data.path,
              content: data.content,
              size: data.size,
              url: data.url,
              isFolder: data.isFolder,
            }, null, 2),
          }],
        };
      }

      case 'list_repo_branches': {
        const repo = args?.repo;
        const data = await adoApiCall(`/git/repositories/${repo}/refs`, {
          filter: 'heads/',
        }, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              branches: data.value?.map(b => ({
                name: b.name.replace('refs/heads/', ''),
                objectId: b.objectId,
                url: b.url,
              })),
            }, null, 2),
          }],
        };
      }

      case 'search_code': {
        const searchText = args?.searchText;
        const repo = args?.repo;
        const top = args?.$top || 10;
        
        const body = {
          searchText,
          $top: top,
        };
        if (repo) {
          body.repositories = [repo];
        }
        
        const data = await adoApiCall('/search/codesearchresults', {}, 'POST', body, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              results: data.results?.map(r => ({
                fileName: r.fileName,
                path: r.path,
                repository: r.repository?.name,
                matches: r.matches,
              })),
            }, null, 2),
          }],
        };
      }

      case 'get_work_item': {
        const workItemId = args?.workItemId;
        const fields = args?.fields;
        const expand = args?.expand || 'all';
        
        const params = { $expand: expand };
        if (fields) params.fields = fields;
        
        const data = await adoApiCall(`/wit/workitems/${workItemId}`, params, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              id: data.id,
              rev: data.rev,
              fields: data.fields,
              relations: data.relations,
              url: data.url,
            }, null, 2),
          }],
        };
      }

      case 'get_work_items': {
        const workItemIds = args?.workItemIds;
        const fields = args?.fields;
        const expand = args?.expand || 'all';
        
        const ids = workItemIds.join(',');
        const params = { ids, $expand: expand };
        if (fields) params.fields = fields;
        
        const data = await adoApiCall('/wit/workitems', params, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              workItems: data.value?.map(wi => ({
                id: wi.id,
                rev: wi.rev,
                fields: wi.fields,
                url: wi.url,
              })),
            }, null, 2),
          }],
        };
      }

      case 'query_work_items': {
        const wiql = args?.wiql;
        const top = args?.$top || 100;
        
        const projectName = project || AZURE_DEVOPS_PROJECT;
        const baseUrl = `https://dev.azure.com/${AZURE_DEVOPS_ORG}/${projectName}/_apis`;
        const response = await axios.post(
          `${baseUrl}/wit/wiql?api-version=7.1`,
          { query: wiql },
          {
            headers: {
              Authorization: `Basic ${authHeader}`,
              'Content-Type': 'application/json',
            },
          }
        );
        
        const workItemIds = response.data.workItems?.map(wi => wi.id) || [];
        if (workItemIds.length === 0) {
          return {
            content: [{ type: 'text', text: JSON.stringify({ count: 0, workItems: [] }, null, 2) }],
          };
        }
        
        const ids = workItemIds.slice(0, top).join(',');
        const itemsData = await adoApiCall('/wit/workitems', { ids, $expand: 'all' }, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: itemsData.count,
              workItems: itemsData.value?.map(wi => ({
                id: wi.id,
                fields: wi.fields,
                url: wi.url,
              })),
            }, null, 2),
          }],
        };
      }

      case 'create_work_item': {
        const type = args?.type;
        const title = args?.title;
        const description = args?.description;
        const fields = args?.fields || {};
        
        const patchDocument = [
          { op: 'add', path: '/fields/System.Title', value: title },
        ];
        
        if (description) {
          patchDocument.push({ op: 'add', path: '/fields/System.Description', value: description });
        }
        
        // Add all custom fields, including Custom.* fields
        Object.entries(fields).forEach(([key, value]) => {
          patchDocument.push({ op: 'add', path: `/fields/${key}`, value });
        });
        
        // Use application/json-patch+json content type for work item operations
        const data = await adoApiCall(`/wit/workitems/$${type}`, {}, 'PATCH', patchDocument, project, 'application/json-patch+json');
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              id: data.id,
              rev: data.rev,
              fields: data.fields,
              url: data.url,
            }, null, 2),
          }],
        };
      }

      case 'update_work_item': {
        const workItemId = args?.workItemId;
        const fields = args?.fields || {};
        const links = args?.links || [];
        const removeLinks = args?.removeLinks || [];
        
        // First, get current work item to find relation indices for removal
        let currentRelations = [];
        if (removeLinks.length > 0) {
          try {
            const currentWi = await adoApiCall(`/wit/workitems/${workItemId}`, { $expand: 'relations' }, 'GET', null, project);
            currentRelations = currentWi.relations || [];
          } catch (error) {
            // If we can't get current relations, proceed without removing
            console.error('Could not fetch current relations for removal:', error.message);
          }
        }
        
        const patchDocument = [];
        
        // Add field updates
        Object.entries(fields).forEach(([key, value]) => {
          patchDocument.push({
            op: 'replace',
            path: `/fields/${key}`,
            value,
          });
        });
        
        // Remove links by finding their index in relations array
        // Process in reverse order to maintain correct indices after removal
        const indicesToRemove = [];
        removeLinks.forEach((urlToRemove) => {
          // Normalize URLs for comparison (case-insensitive, remove trailing slashes)
          const normalizedUrlToRemove = urlToRemove.toLowerCase().replace(/\/$/, '');
          const index = currentRelations.findIndex(rel => {
            const normalizedRelUrl = (rel.url || '').toLowerCase().replace(/\/$/, '');
            return normalizedRelUrl === normalizedUrlToRemove;
          });
          if (index >= 0) {
            indicesToRemove.push(index);
          }
        });
        // Sort in descending order to remove from end to beginning
        indicesToRemove.sort((a, b) => b - a).forEach(index => {
          patchDocument.push({
            op: 'remove',
            path: `/relations/${index}`,
          });
        });
        
        // Add link additions
        links.forEach((link) => {
          patchDocument.push({
            op: 'add',
            path: '/relations/-',
            value: {
              rel: link.rel,
              url: link.url,
            },
          });
        });
        
        // Ensure at least one operation exists
        if (patchDocument.length === 0) {
          throw new McpError(ErrorCode.InvalidParams, 'At least one field update or link operation is required');
        }
        
        // Use application/json-patch+json content type for work item operations
        const data = await adoApiCall(`/wit/workitems/${workItemId}`, {}, 'PATCH', patchDocument, project, 'application/json-patch+json');
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              id: data.id,
              rev: data.rev,
              fields: data.fields,
              relations: data.relations,
              url: data.url,
            }, null, 2),
          }],
        };
      }

      case 'list_pull_requests': {
        const repo = args?.repo;
        const status = args?.status || 'active';
        const top = args?.$top || 10;
        
        const data = await adoApiCall(`/git/repositories/${repo}/pullrequests`, {
          status,
          $top: top.toString(),
        }, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              pullRequests: data.value?.map(pr => ({
                pullRequestId: pr.pullRequestId,
                title: pr.title,
                status: pr.status,
                createdBy: pr.createdBy?.displayName,
                creationDate: pr.creationDate,
                url: pr.url,
              })),
            }, null, 2),
          }],
        };
      }

      case 'get_pull_request': {
        const repo = args?.repo;
        const pullRequestId = args?.pullRequestId;
        const includeCommits = args?.includeCommits || false;
        const includeWorkItems = args?.includeWorkItems || false;
        
        const params = {};
        if (includeCommits) params.includeCommits = 'true';
        if (includeWorkItems) params.includeWorkItemsRefs = 'true';
        
        const data = await adoApiCall(`/git/repositories/${repo}/pullrequests/${pullRequestId}`, params, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              pullRequestId: data.pullRequestId,
              title: data.title,
              description: data.description,
              status: data.status,
              createdBy: data.createdBy,
              reviewers: data.reviewers,
              commits: data.commits,
              workItemRefs: data.workItemRefs,
              url: data.url,
            }, null, 2),
          }],
        };
      }

      case 'get_pr_comments': {
        const repo = args?.repo;
        const pullRequestId = args?.pullRequestId;
        const top = args?.$top || 100;
        
        const data = await adoApiCall(`/git/repositories/${repo}/pullrequests/${pullRequestId}/threads`, {
          $top: top.toString(),
        }, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              threads: data.value?.map(t => ({
                id: t.id,
                comments: t.comments?.map(c => ({
                  id: c.id,
                  content: c.content,
                  author: c.author?.displayName,
                  publishedDate: c.publishedDate,
                })),
              })),
            }, null, 2),
          }],
        };
      }

      case 'list_builds': {
        const definitionId = args?.definitionId;
        const status = args?.status;
        const result = args?.result;
        const top = args?.$top || 10;
        
        const params = { $top: top.toString() };
        if (definitionId) params.definitions = definitionId.toString();
        if (status) params.statusFilter = status;
        if (result) params.resultFilter = result;
        
        const data = await adoApiCall('/build/builds', params, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              builds: data.value?.map(b => ({
                id: b.id,
                buildNumber: b.buildNumber,
                status: b.status,
                result: b.result,
                definition: b.definition?.name,
                requestedBy: b.requestedBy?.displayName,
                startTime: b.startTime,
                finishTime: b.finishTime,
                url: b.url,
              })),
            }, null, 2),
          }],
        };
      }

      case 'get_build': {
        const buildId = args?.buildId;
        const data = await adoApiCall(`/build/builds/${buildId}`, {}, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              id: data.id,
              buildNumber: data.buildNumber,
              status: data.status,
              result: data.result,
              definition: data.definition,
              logs: data.logs,
              timeline: data.timeline,
              url: data.url,
            }, null, 2),
          }],
        };
      }

      case 'list_pipelines': {
        const top = args?.$top || 10;
        const data = await adoApiCall('/pipelines', { $top: top.toString() }, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              pipelines: data.value?.map(p => ({
                id: p.id,
                name: p.name,
                folder: p.folder,
                url: p.url,
              })),
            }, null, 2),
          }],
        };
      }

      case 'get_pipeline_run': {
        const pipelineId = args?.pipelineId;
        const runId = args?.runId;
        const data = await adoApiCall(`/pipelines/${pipelineId}/runs/${runId}`, {}, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              id: data.id,
              name: data.name,
              state: data.state,
              result: data.result,
              createdDate: data.createdDate,
              finishedDate: data.finishedDate,
              url: data.url,
            }, null, 2),
          }],
        };
      }

      case 'list_releases': {
        const definitionId = args?.definitionId;
        const status = args?.status;
        const top = args?.$top || 10;
        
        const params = { $top: top.toString() };
        if (definitionId) params.definitionId = definitionId.toString();
        if (status) params.statusFilter = status;
        
        const data = await adoApiCall('/release/releases', params, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              releases: data.value?.map(r => ({
                id: r.id,
                name: r.name,
                status: r.status,
                createdOn: r.createdOn,
                url: r.url,
              })),
            }, null, 2),
          }],
        };
      }

      case 'get_release': {
        const releaseId = args?.releaseId;
        const data = await adoApiCall(`/release/releases/${releaseId}`, {}, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              id: data.id,
              name: data.name,
              status: data.status,
              environments: data.environments,
              url: data.url,
            }, null, 2),
          }],
        };
      }

      case 'list_test_plans': {
        const top = args?.$top || 10;
        const data = await adoApiCall('/test/plans', { $top: top.toString() }, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              count: data.count,
              testPlans: data.value?.map(tp => ({
                id: tp.id,
                name: tp.name,
                areaPath: tp.areaPath,
                url: tp.url,
              })),
            }, null, 2),
          }],
        };
      }

      case 'get_test_plan': {
        const planId = args?.planId;
        const data = await adoApiCall(`/test/plans/${planId}`, {}, 'GET', null, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              id: data.id,
              name: data.name,
              areaPath: data.areaPath,
              testSuites: data.testSuites,
              url: data.url,
            }, null, 2),
          }],
        };
      }

      case 'ado_api_call': {
        const endpoint = args?.endpoint;
        const method = (args?.method || 'GET').toUpperCase();
        const params = args?.params || {};
        const body = args?.body;

        const data = await adoApiCall(endpoint, params, method, body, project);
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify(data, null, 2),
          }],
        };
      }

      default:
        throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    
    // Track error
    if (telemetryClient) {
      telemetryClient.trackException({
        exception: error,
        properties: {
          toolName: name,
          project: project || AZURE_DEVOPS_PROJECT,
          errorCode: error instanceof McpError ? error.code : 'Unknown',
          duration,
        },
      });
    }
    
    if (error instanceof McpError) {
      throw error;
    }

    if (error.response) {
      // Check for expired PAT and provide helpful message
      if (error.response.status === 401) {
        const errorData = error.response.data || {};
        const errorMessage = errorData.message || errorData.helpfulMessage || error.message;
        if (errorMessage && (errorMessage.includes('expired') || errorMessage.includes('Access Denied') || errorMessage.includes('Personal Access Token'))) {
          throw new McpError(
            ErrorCode.InvalidRequest,
            `Azure DevOps PAT token has expired. Please update your PAT token:\n\n` +
            `1. Generate a new PAT at: https://dev.azure.com/${AZURE_DEVOPS_ORG}/_usersSettings/tokens (replace with your organization)\n` +
            `2. Run: .\\update-pat.ps1 -NewPAT "your_new_token_here"\n` +
            `3. Restart Cursor/VS Code and the MCP server\n\n` +
            `Original error: ${errorMessage}`
          );
        }
      }
      
      throw new McpError(
        ErrorCode.InternalError,
        `Azure DevOps API error: ${error.response.status} - ${error.response.statusText}\n${JSON.stringify(error.response.data, null, 2)}`
      );
    }

    throw new McpError(ErrorCode.InternalError, `Error: ${error.message}`);
  } finally {
    // Track successful completion
    const duration = Date.now() - startTime;
    if (telemetryClient) {
      telemetryClient.trackRequest({
        name: `MCP Tool: ${name}`,
        url: `/mcp/tool/${name}`,
        duration,
        resultCode: 200,
        success: true,
        properties: {
          toolName: name,
          project: project || AZURE_DEVOPS_PROJECT,
        },
      });
    }
  }
});

/**
 * Start the server
 */
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('MCP Azure DevOps Server running on stdio');
  console.error(`Connected to: ${AZURE_DEVOPS_ORG}/${AZURE_DEVOPS_PROJECT}`);
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
