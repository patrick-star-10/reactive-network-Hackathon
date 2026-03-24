#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

load_env
origin_rpc="$(origin_rpc_url)"
if [[ -z "${origin_rpc}" ]]; then
  echo "Missing required env var: ORIGIN_RPC or ORIGIN_RPC_URL" >&2
  exit 1
fi
origin_key="$(effective_private_key ORIGIN_PRIVATE_KEY)"

output="$(
  forge_with_local_solc create src/BasicDemoL1Contract.sol:BasicDemoL1Contract \
    --rpc-url "${origin_rpc}" \
    --private-key "${origin_key}" \
    --broadcast
)"

printf '%s\n' "${output}"

origin_address="$(printf '%s\n' "${output}" | extract_deployed_to)"
origin_tx_hash="$(printf '%s\n' "${output}" | extract_tx_hash)"

set_env_value "ORIGIN_CONTRACT" "${origin_address}"
set_env_value "ORIGIN_ADDR" "${origin_address}"
set_env_value "ORIGIN_DEPLOY_TX" "${origin_tx_hash}"
set_env_value "RECEIVED_TOPIC0" "${RECEIVED_TOPIC0}"

echo
echo "Updated .env:"
print_next_env_line "ORIGIN_CONTRACT" "${origin_address}"
print_next_env_line "ORIGIN_ADDR" "${origin_address}"
print_next_env_line "ORIGIN_DEPLOY_TX" "${origin_tx_hash}"
print_next_env_line "RECEIVED_TOPIC0" "${RECEIVED_TOPIC0}"
