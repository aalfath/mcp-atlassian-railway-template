#!/bin/sh
# Starts MCP Atlassian (streamable HTTP, loopback only) and Caddy in front of it.
# If either process stops, the container exits non-zero so Railway restarts it.
set -eu

: "${PORT:=8080}"
: "${MCP_INTERNAL_PORT:=9000}"
export PORT MCP_INTERNAL_PORT

fail() { echo "$*" >&2; exit 1; }

if [ -z "${MCP_AUTH_TOKEN:-}" ] || [ "${#MCP_AUTH_TOKEN}" -lt 24 ]; then
  fail "MCP_AUTH_TOKEN must be set (at least 24 characters); the template generates one."
fi
case "$MCP_AUTH_TOKEN" in
  *[!A-Za-z0-9_-]*) fail "MCP_AUTH_TOKEN may only use letters, digits, '-' and '_'." ;;
esac

# --- Atlassian connection -------------------------------------------------------
# ATLASSIAN_URL / ATLASSIAN_EMAIL / ATLASSIAN_API_TOKEN cover Atlassian Cloud in three
# prompts. Upstream's own JIRA_* / CONFLUENCE_* variables, when set, win.
site="${ATLASSIAN_URL:-}"
site="$(printf '%s' "$site" | tr -d ' \t\r\n')"
site="${site%/}"
case "$site" in
  "") ;;
  http://*|https://*) ;;
  *) site="https://$site" ;;
esac
site="${site%/wiki}"
host="$(printf '%s' "$site" | sed -E 's#^https?://##; s#[/:].*$##')"

if [ -z "${JIRA_URL:-}" ] && [ -z "${CONFLUENCE_URL:-}" ] && [ -z "$site" ]; then
  fail "Set ATLASSIAN_URL (for example https://your-company.atlassian.net) on this service."
fi

case "$host" in
  *.atlassian.net|*.jira.com|*.atlassian-gov.net|*.atlassian-us-gov-mod.net)
    # Atlassian Cloud: Jira at the site root, Confluence under /wiki, email + API token.
    if [ -n "$site" ]; then
      : "${JIRA_URL:=$site}"
      : "${CONFLUENCE_URL:=$site/wiki}"
    fi
    if [ -n "${ATLASSIAN_EMAIL:-}" ] && [ -n "${ATLASSIAN_API_TOKEN:-}" ]; then
      : "${JIRA_USERNAME:=$ATLASSIAN_EMAIL}"
      : "${JIRA_API_TOKEN:=$ATLASSIAN_API_TOKEN}"
      : "${CONFLUENCE_USERNAME:=$ATLASSIAN_EMAIL}"
      : "${CONFLUENCE_API_TOKEN:=$ATLASSIAN_API_TOKEN}"
    fi
    ;;
  ?*)
    # Server / Data Center: ATLASSIAN_URL is the Jira URL; ATLASSIAN_API_TOKEN is a
    # personal access token. Set CONFLUENCE_URL (and CONFLUENCE_PERSONAL_TOKEN if it
    # differs) for Confluence on its own host.
    if [ -n "$site" ]; then : "${JIRA_URL:=$site}"; fi
    if [ -n "${ATLASSIAN_API_TOKEN:-}" ]; then
      if [ -z "${JIRA_USERNAME:-}" ]; then : "${JIRA_PERSONAL_TOKEN:=$ATLASSIAN_API_TOKEN}"; fi
      if [ -n "${CONFLUENCE_URL:-}" ] && [ -z "${CONFLUENCE_USERNAME:-}" ]; then
        : "${CONFLUENCE_PERSONAL_TOKEN:=$ATLASSIAN_API_TOKEN}"
      fi
    fi
    ;;
esac
for v in JIRA_URL CONFLUENCE_URL JIRA_USERNAME JIRA_API_TOKEN JIRA_PERSONAL_TOKEN \
         CONFLUENCE_USERNAME CONFLUENCE_API_TOKEN CONFLUENCE_PERSONAL_TOKEN; do
  eval "val=\${$v:-}"
  if [ -n "$val" ]; then export "$v"; else unset "$v"; fi
done
if [ -z "${JIRA_URL:-}${CONFLUENCE_URL:-}" ]; then
  fail "No Jira or Confluence URL could be derived; check ATLASSIAN_URL."
fi
if [ -z "${JIRA_API_TOKEN:-}${JIRA_PERSONAL_TOKEN:-}${CONFLUENCE_API_TOKEN:-}${CONFLUENCE_PERSONAL_TOKEN:-}" ]; then
  fail "No Atlassian credentials: set ATLASSIAN_EMAIL and ATLASSIAN_API_TOKEN on this service."
fi

# --- Server mode ------------------------------------------------------------------
# Single-operator mode: Caddy has already checked MCP_AUTH_TOKEN and removed the
# Authorization header, so the server uses the credentials above for every request.
export IGNORE_HEADER_AUTH=true ALLOW_GLOBAL_CRED_FALLBACK=true
export TRANSPORT=streamable-http STATELESS="${STATELESS:-true}"
export TOOLSETS="${TOOLSETS:-all}"
export MCP_ATLASSIAN_FILES_DIR="${MCP_ATLASSIAN_FILES_DIR:-/home/app/.mcp-atlassian/files}"
if [ -z "${MCP_ALLOWED_URL_DOMAINS:-}" ]; then
  doms=""
  for u in "${JIRA_URL:-}" "${CONFLUENCE_URL:-}"; do
    [ -n "$u" ] || continue
    h="$(printf '%s' "$u" | sed -E 's#^https?://##; s#[/:].*$##')"
    case ",$doms," in *",$h,"*) ;; *) doms="${doms:+$doms,}$h" ;; esac
  done
  export MCP_ALLOWED_URL_DOMAINS="$doms"
fi
unset ATLASSIAN_API_TOKEN

echo "MCP Atlassian: Jira=${JIRA_URL:-off} Confluence=${CONFLUENCE_URL:-off} read_only=${READ_ONLY_MODE:-false} toolsets=$TOOLSETS"

# The upstream server reads PORT too, so give it its own port explicitly.
env -u MCP_AUTH_TOKEN mcp-atlassian --transport streamable-http \
  --host 127.0.0.1 --port "$MCP_INTERNAL_PORT" &
MCP_PID=$!
env -u JIRA_API_TOKEN -u JIRA_PERSONAL_TOKEN -u CONFLUENCE_API_TOKEN -u CONFLUENCE_PERSONAL_TOKEN \
  caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
CADDY_PID=$!

trap 'kill "$MCP_PID" "$CADDY_PID" 2>/dev/null; exit 0' TERM INT

# BusyBox `wait -n` does not return on the first child exit, so poll.
while kill -0 "$MCP_PID" 2>/dev/null && kill -0 "$CADDY_PID" 2>/dev/null; do
  sleep 2
done
echo "A process stopped unexpectedly; exiting so Railway restarts the service." >&2
kill "$MCP_PID" "$CADDY_PID" 2>/dev/null || true
exit 1
