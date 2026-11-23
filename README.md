[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/mcp-atlassian-1?utm_medium=integration&utm_source=button&utm_campaign=mcp-atlassian)

# MCP Atlassian on Railway

One-click Railway template for [MCP Atlassian](https://github.com/sooperset/mcp-atlassian) **0.24.8** (`ghcr.io/sooperset/mcp-atlassian:0.24.8@sha256:a62b1725c31ef2ac50074eb8b1dac88f9167fa56901b2dfa0a45414225e3431b`), an MCP server for Jira and Confluence, running remotely over streamable HTTP and locked with a generated bearer token.

## What it deploys

One service built from this repo's `Dockerfile`:

- the official MCP Atlassian image, started by `start.sh` with `--transport streamable-http` (stateless) on `127.0.0.1:9000`;
- [Caddy](https://caddyserver.com) 2.11.9 on Railway's `PORT` (8080). It lets a request through only with `Authorization: Bearer $MCP_AUTH_TOKEN`, strips that header, and the server then calls Jira and Confluence with the Atlassian credentials set on the service. `/healthz` answers 200 without a token (Railway's health check).

`start.sh` exits non-zero when either process stops, so Railway's restart policy brings the service back. The server keeps no state (no volume, no database): your data stays in Jira and Confluence. Idle RAM is about 120 MB; it runs on Railway's smallest plan (0.5 GB, 1 vCPU).

## Variables

| Variable | Set by | What it is |
|---|---|---|
| `ATLASSIAN_URL` | you | Your Atlassian site, for example `https://your-company.atlassian.net`. Jira is used at the site root and Confluence under `/wiki`. For Server/Data Center, give the Jira base URL. |
| `ATLASSIAN_EMAIL` | you | The email of the Atlassian account the server acts as (Cloud). Leave empty for Server/Data Center with a personal access token. |
| `ATLASSIAN_API_TOKEN` | you | Cloud: an API token from <https://id.atlassian.com/manage-profile/security/api-tokens>. Server/Data Center: a personal access token. |
| `MCP_AUTH_TOKEN` | generated | Bearer token your MCP client must send. Copy it from the service's Variables tab. |
| `PORT` | template | 8080, the port of the Caddy front. |

Every tool call runs with the permissions of that one Atlassian account, so share the endpoint and `MCP_AUTH_TOKEN` only with people who may act as it.

Optional (add them on the service; see the upstream [configuration guide](https://github.com/sooperset/mcp-atlassian/blob/v0.24.8/docs/configuration.mdx)):

- `READ_ONLY_MODE=true`: only read tools.
- `TOOLSETS` (default here `all`), `ENABLED_TOOLS`, `JIRA_PROJECTS_FILTER`, `CONFLUENCE_SPACES_FILTER`: limit what the agent sees.
- Upstream's own `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN`, `JIRA_PERSONAL_TOKEN`, `CONFLUENCE_URL`, `CONFLUENCE_USERNAME`, `CONFLUENCE_API_TOKEN`, `CONFLUENCE_PERSONAL_TOKEN`: set them when Jira and Confluence live on different hosts or use different accounts; they win over the `ATLASSIAN_*` shortcuts.

## Client config

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

## Updates

The upstream image is pinned by version and digest in the `Dockerfile`. When this repo's `main` changes, Railway shows deployers an "update available" notice; read `CHANGELOG.md` first, breaking changes are listed at the top of each entry.

## Template overview

The marketplace overview is in [`OVERVIEW.md`](OVERVIEW.md).
