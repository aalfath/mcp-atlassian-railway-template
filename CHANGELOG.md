# Changelog

## 2026-11-23: MCP Atlassian 0.24.8 (first release)

- Breaking changes: none (first release).
- MCP Atlassian 0.24.8, `ghcr.io/sooperset/mcp-atlassian:0.24.8@sha256:a62b1725c31ef2ac50074eb8b1dac88f9167fa56901b2dfa0a45414225e3431b`, streamable HTTP on `/mcp`, stateless.
- Caddy 2.11.9 (`caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0`) in front, checking the generated `MCP_AUTH_TOKEN`.
- Health check `/healthz`; the container exits non-zero if the server or Caddy stops.
