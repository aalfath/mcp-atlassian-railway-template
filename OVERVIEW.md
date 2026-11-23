# Deploy and Host MCP Atlassian on Railway

MCP Atlassian is an open-source (MIT) Model Context Protocol server for Jira and Confluence. It gives AI assistants such as Claude, Cursor and VS Code tools to search, read, create and update Jira issues and Confluence pages, on Atlassian Cloud or Server/Data Center, using your own Atlassian account.

## About Hosting MCP Atlassian

This template runs the official MCP Atlassian 0.24.8 image as a remote MCP server over streamable HTTP at `/mcp`, so any MCP client can reach it from anywhere. A small Caddy front on the public port lets requests through only with a generated bearer token (`MCP_AUTH_TOKEN`), and the server then calls Jira and Confluence with the API token you set. You answer three prompts: your Atlassian site URL, the account email and an Atlassian API token. The server keeps no state, so there is no database or volume. It needs about 120 MB of RAM and runs on Railway's smallest plan.

## Common Use Cases

* Let an AI assistant search Jira, summarise issues, add comments and move tickets through a workflow
* Give coding agents read access to Confluence specs and runbooks while they work
* Share one remote Jira and Confluence MCP endpoint across your own machines and agents without installing anything locally

## Dependencies for MCP Atlassian Hosting

* An Atlassian Cloud site (or Jira/Confluence Server or Data Center reachable from the internet)
* An Atlassian API token for the account the server acts as (a personal access token on Server/Data Center)

### Deployment Dependencies

* MCP Atlassian: https://github.com/sooperset/mcp-atlassian (release 0.24.8)
* Atlassian API tokens: https://id.atlassian.com/manage-profile/security/api-tokens
* Template repository: https://github.com/aalfath/mcp-atlassian-railway-template

### Implementation Details

One service, built from the template repository: the official image pinned by version and digest, plus Caddy in front. The Atlassian token stays on the server; clients only ever see the generated `MCP_AUTH_TOKEN`. Requests without it get 401, and `/healthz` answers Railway's health check without a token.

After deploy, copy `MCP_AUTH_TOKEN` from the service's Variables tab and add the server to your client:

```json
{
  "mcpServers": {
    "atlassian": {
      "type": "http",
      "url": "https://YOUR-DOMAIN.up.railway.app/mcp",
      "headers": { "Authorization": "Bearer YOUR-MCP_AUTH_TOKEN" }
    }
  }
}
```

Claude Code: `claude mcp add --transport http atlassian https://YOUR-DOMAIN.up.railway.app/mcp --header "Authorization: Bearer YOUR-MCP_AUTH_TOKEN"`

Every tool call runs as the one Atlassian account you configured, so share the token only with people who may act as it. Set `READ_ONLY_MODE=true` for read tools only, or `JIRA_PROJECTS_FILTER` and `CONFLUENCE_SPACES_FILTER` to narrow what the agent sees. For Server/Data Center, set `ATLASSIAN_URL` to the Jira URL, leave the email empty, use a personal access token, and add `CONFLUENCE_URL` if Confluence runs on its own host.

Updates: the template builds from its GitHub repository, so Railway shows an "update available" notice when a new MCP Atlassian version is tested and merged. Read the repository's CHANGELOG before applying it.

## Why Deploy MCP Atlassian on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying MCP Atlassian on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
