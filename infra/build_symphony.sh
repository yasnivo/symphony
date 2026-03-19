#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ELIXIR_DIR="${REPO_ROOT}/elixir"

if ! command -v mix >/dev/null 2>&1; then
  cat >&2 <<EOF
error: mix not found in PATH.
Install Elixir/OTP first (recommended: mise/asdf), then re-run.
EOF
  exit 1
fi

cd "${ELIXIR_DIR}"
mix setup
mix build

BIN_PATH="${ELIXIR_DIR}/bin/symphony"
if [[ ! -x "${BIN_PATH}" ]]; then
  echo "error: build finished but binary is missing: ${BIN_PATH}" >&2
  exit 1
fi

echo "Built Symphony binary:"
echo "  ${BIN_PATH}"
