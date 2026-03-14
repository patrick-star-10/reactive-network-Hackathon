#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

load_env
require_env "ORIGIN_RPC_URL"

origin_key="$(effective_private_key ORIGIN_PRIVATE_KEY)"

output="$(
  forge_with_local_solc create src/OriginEventSource.sol:OriginEventSource \
    --rpc-url "${ORIGIN_RPC_URL}" \
    --private-key "${origin_key}" \
    --broadcast
)"

printf '%s\n' "${output}"

origin_address="$(printf '%s\n' "${output}" | extract_deployed_to)"
origin_tx_hash="$(printf '%s\n' "${output}" | extract_tx_hash)"
topic0="$(cast keccak "ValueSet(address,uint256,uint256)")"

set_env_value "ORIGIN_CONTRACT" "${origin_address}"
set_env_value "ORIGIN_DEPLOY_TX" "${origin_tx_hash}"
set_env_value "VALUE_SET_TOPIC0" "${topic0}"

echo
echo "Updated .env:"
print_next_env_line "ORIGIN_CONTRACT" "${origin_address}"
print_next_env_line "ORIGIN_DEPLOY_TX" "${origin_tx_hash}"
print_next_env_line "VALUE_SET_TOPIC0" "${topic0}"
