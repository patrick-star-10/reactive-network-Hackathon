#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
DEFAULT_SOLC_BIN="${ROOT_DIR}/tools/solc-0.8.20"

load_env() {
  if [[ -f "${ENV_FILE}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
    set +a
  fi
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required env var: ${name}" >&2
    exit 1
  fi
}

require_file() {
  local path="$1"
  if [[ ! -f "${path}" ]]; then
    echo "Missing required file: ${path}" >&2
    exit 1
  fi
}

effective_private_key() {
  local specific_name="$1"
  if [[ -n "${!specific_name:-}" ]]; then
    printf '%s\n' "${!specific_name}"
    return 0
  fi
  require_env "PRIVATE_KEY"
  printf '%s\n' "${PRIVATE_KEY}"
}

effective_authorized_rvm_id() {
  if [[ -n "${AUTHORIZED_RVM_ID:-}" ]]; then
    printf '%s\n' "${AUTHORIZED_RVM_ID}"
    return 0
  fi

  local reactive_key
  reactive_key="$(effective_private_key REACTIVE_PRIVATE_KEY)"
  cast wallet address --private-key "${reactive_key}"
}

effective_solc_bin() {
  local solc_bin="${SOLC_BIN:-${DEFAULT_SOLC_BIN}}"
  require_file "${solc_bin}"
  printf '%s\n' "${solc_bin}"
}

forge_with_local_solc() {
  local solc_bin
  local subcommand="$1"
  shift
  solc_bin="$(effective_solc_bin)"
  forge "${subcommand}" --no-auto-detect --use "${solc_bin}" "$@"
}

extract_deployed_to() {
  awk '/Deployed to:/ { print $3 }' | tail -n 1
}

extract_tx_hash() {
  awk '/Transaction hash:/ { print $3 }' | tail -n 1
}

print_next_env_line() {
  local key="$1"
  local value="$2"
  printf '%s=%s\n' "${key}" "${value}"
}

set_env_value() {
  local key="$1"
  local value="$2"

  touch "${ENV_FILE}"

  if rg -q "^${key}=" "${ENV_FILE}"; then
    python3 - "${ENV_FILE}" "${key}" "${value}" <<'PY'
from pathlib import Path
import sys

env_file = Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]
lines = env_file.read_text().splitlines()
updated = []
replaced = False
for line in lines:
    if line.startswith(f"{key}="):
        updated.append(f"{key}={value}")
        replaced = True
    else:
        updated.append(line)
if not replaced:
    updated.append(f"{key}={value}")
env_file.write_text("\n".join(updated) + "\n")
PY
  else
    print_next_env_line "${key}" "${value}" >> "${ENV_FILE}"
  fi
}
