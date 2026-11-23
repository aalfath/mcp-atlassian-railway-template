# MCP Atlassian for Railway: the official server image plus a small Caddy front that
# checks a generated bearer token. The server itself listens on loopback only.
FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0 AS caddy

FROM ghcr.io/sooperset/mcp-atlassian:0.24.8@sha256:a62b1725c31ef2ac50074eb8b1dac88f9167fa56901b2dfa0a45414225e3431b
USER root
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY start.sh /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh /usr/local/bin/caddy \
 && chmod 644 /etc/caddy/Caddyfile \
 && caddy version && mcp-atlassian --version
USER app
ENV PORT=8080 MCP_INTERNAL_PORT=9000 PYTHONDONTWRITEBYTECODE=1 GOMAXPROCS=1 GOMEMLIMIT=64MiB \
    FASTMCP_SHOW_SERVER_BANNER=false FASTMCP_CHECK_FOR_UPDATES=off
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/start.sh"]
