#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

load_env
require_env "REACTIVE_RPC_URL"
require_env "SYSTEM_CONTRACT"
require_env "ORIGIN_CHAIN_ID"
require_env "DESTINATION_CHAIN_ID"
require_env "ORIGIN_CONTRACT"
require_env "DESTINATION_CONTRACT"

topic0="${VALUE_SET_TOPIC0:-$(cast keccak "ValueSet(address,uint256,uint256)")}"
reactive_key="$(effective_private_key REACTIVE_PRIVATE_KEY)"
reactive_deploy_amount="${REACTIVE_DEPLOY_AMOUNT:-0.01ether}"

output="$(
  forge_with_local_solc create src/ValueSetListenerReactive.sol:ValueSetListenerReactive \
    --rpc-url "${REACTIVE_RPC_URL}" \
    --private-key "${reactive_key}" \
    --broadcast \
    --value "${reactive_deploy_amount}" \
    --constructor-args \
      "${SYSTEM_CONTRACT}" \
      "${ORIGIN_CHAIN_ID}" \
      "${DESTINATION_CHAIN_ID}" \
      "${ORIGIN_CONTRACT}" \
      "${topic0}" \
      "${DESTINATION_CONTRACT}"
)"

printf '%s\n' "${output}"

reactive_address="$(printf '%s\n' "${output}" | extract_deployed_to)"
reactive_tx_hash="$(printf '%s\n' "${output}" | extract_tx_hash)"

set_env_value "REACTIVE_CONTRACT" "${reactive_address}"
set_env_value "REACTIVE_DEPLOY_TX" "${reactive_tx_hash}"
set_env_value "VALUE_SET_TOPIC0" "${topic0}"

echo
echo "Updated .env:"
print_next_env_line "REACTIVE_CONTRACT" "${reactive_address}"
print_next_env_line "REACTIVE_DEPLOY_TX" "${reactive_tx_hash}"
print_next_env_line "VALUE_SET_TOPIC0" "${topic0}"
