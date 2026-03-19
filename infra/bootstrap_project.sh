#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bootstrap_project.sh \
    --project-root /abs/path/to/project \
    --project-slug linear-project-slug \
    --repo-url git@github.com:org/repo.git \
    [--workspace-root /abs/path/to/workspaces] \
    [--force]

Creates project-local Symphony files in <project-root>/.symphony:
  - WORKFLOW.md
  - .env.example
  - run-symphony.sh
EOF
}

require_arg() {
  local name="$1"
  local value="$2"
  if [[ -z "${value}" ]]; then
    echo "error: missing required ${name}" >&2
    usage
    exit 1
  fi
}

PROJECT_ROOT=""
PROJECT_SLUG=""
REPO_URL=""
WORKSPACE_ROOT=""
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    --project-slug)
      PROJECT_SLUG="${2:-}"
      shift 2
      ;;
    --repo-url)
      REPO_URL="${2:-}"
      shift 2
      ;;
    --workspace-root)
      WORKSPACE_ROOT="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

require_arg "--project-root" "${PROJECT_ROOT}"
require_arg "--project-slug" "${PROJECT_SLUG}"
require_arg "--repo-url" "${REPO_URL}"

PROJECT_ROOT="$(cd "${PROJECT_ROOT}" && pwd)"
PROJECT_NAME="$(basename "${PROJECT_ROOT}")"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${HOME}/code/symphony-workspaces/${PROJECT_NAME}}"
PROJECT_SYMPHONY_DIR="${PROJECT_ROOT}/.symphony"
WORKFLOW_PATH="${PROJECT_SYMPHONY_DIR}/WORKFLOW.md"
ENV_EXAMPLE_PATH="${PROJECT_SYMPHONY_DIR}/.env.example"
RUN_PATH="${PROJECT_SYMPHONY_DIR}/run-symphony.sh"

mkdir -p "${PROJECT_SYMPHONY_DIR}"

if [[ -f "${WORKFLOW_PATH}" && "${FORCE}" -ne 1 ]]; then
  echo "error: ${WORKFLOW_PATH} already exists. Re-run with --force to overwrite." >&2
  exit 1
fi

cat > "${WORKFLOW_PATH}" <<EOF
---
tracker:
  kind: linear
  project_slug: "${PROJECT_SLUG}"
  api_key: \$LINEAR_API_KEY
  active_states:
    - Todo
    - In Progress
    - Merging
    - Rework
  terminal_states:
    - Closed
    - Cancelled
    - Canceled
    - Duplicate
    - Done
polling:
  interval_ms: 5000
workspace:
  root: "${WORKSPACE_ROOT}"
hooks:
  after_create: |
    git clone --depth 1 "\$SYMPHONY_SOURCE_REPO_URL" .
agent:
  max_concurrent_agents: 4
  max_turns: 20
codex:
  command: codex app-server
  approval_policy: never
  thread_sandbox: workspace-write
  turn_sandbox_policy:
    type: workspaceWrite
---

You are working on a Linear issue {{ issue.identifier }}.

Title: {{ issue.title }}
State: {{ issue.state }}
URL: {{ issue.url }}

Description:
{% if issue.description %}
{{ issue.description }}
{% else %}
No description provided.
{% endif %}

Requirements:
- Work only in the provided workspace.
- Operate autonomously end-to-end.
- Run tests relevant to changed code.
- Report completed actions and blockers only.
EOF

cat > "${ENV_EXAMPLE_PATH}" <<EOF
# Required
LINEAR_API_KEY=
SYMPHONY_SOURCE_REPO_URL=${REPO_URL}

# Optional
# SYMPHONY_LOGS_ROOT=${PROJECT_ROOT}/.symphony/log
# SYMPHONY_DASHBOARD_PORT=4000
# SYMPHONY_BIN=/absolute/path/to/symphony/elixir/bin/symphony
EOF

cat > "${RUN_PATH}" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_PATH="${SCRIPT_DIR}/WORKFLOW.md"
ENV_PATH="${SCRIPT_DIR}/.env"

if [[ -f "${ENV_PATH}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_PATH}"
fi

if [[ -z "${LINEAR_API_KEY:-}" ]]; then
  echo "error: LINEAR_API_KEY is not set. Put it into ${ENV_PATH}." >&2
  exit 1
fi

if [[ -z "${SYMPHONY_SOURCE_REPO_URL:-}" ]]; then
  echo "error: SYMPHONY_SOURCE_REPO_URL is not set. Put it into ${ENV_PATH}." >&2
  exit 1
fi

if [[ -z "${SYMPHONY_BIN:-}" ]]; then
  echo "error: SYMPHONY_BIN is not set. Example:" >&2
  echo "  export SYMPHONY_BIN=/Users/dmitrii/Documents/1-Projects/symphony/elixir/bin/symphony" >&2
  exit 1
fi

if [[ ! -x "${SYMPHONY_BIN}" ]]; then
  echo "error: SYMPHONY_BIN does not exist or is not executable: ${SYMPHONY_BIN}" >&2
  exit 1
fi

ARGS=(
  "--i-understand-that-this-will-be-running-without-the-usual-guardrails"
)

if [[ -n "${SYMPHONY_LOGS_ROOT:-}" ]]; then
  ARGS+=("--logs-root" "${SYMPHONY_LOGS_ROOT}")
fi

if [[ -n "${SYMPHONY_DASHBOARD_PORT:-}" ]]; then
  ARGS+=("--port" "${SYMPHONY_DASHBOARD_PORT}")
fi

exec "${SYMPHONY_BIN}" "${ARGS[@]}" "${WORKFLOW_PATH}"
EOF

chmod +x "${RUN_PATH}"

echo "Created:"
echo "  ${WORKFLOW_PATH}"
echo "  ${ENV_EXAMPLE_PATH}"
echo "  ${RUN_PATH}"
echo
echo "Next:"
echo "  1) cp ${ENV_EXAMPLE_PATH} ${PROJECT_SYMPHONY_DIR}/.env"
echo "  2) Fill LINEAR_API_KEY and SYMPHONY_SOURCE_REPO_URL in .env"
echo "  3) Set SYMPHONY_BIN in .env"
echo "  4) Run: ${RUN_PATH}"
