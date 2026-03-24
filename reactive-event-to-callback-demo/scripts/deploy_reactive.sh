#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

load_env
require_env "ORIGIN_CHAIN_ID"
require_env "DESTINATION_CHAIN_ID"
reactive_rpc="$(reactive_rpc_url)"
origin_contract="${ORIGIN_ADDR:-${ORIGIN_CONTRACT:-}}"
callback_addr="${CALLBACK_ADDR:-${DESTINATION_CONTRACT:-}}"
if [[ -z "${reactive_rpc}" ]]; then
  echo "Missing required env var: REACTIVE_RPC or REACTIVE_RPC_URL" >&2
  exit 1
fi
if [[ -z "${origin_contract}" ]]; then
  echo "Missing required env var: ORIGIN_ADDR or ORIGIN_CONTRACT" >&2
  exit 1
fi
if [[ -z "${callback_addr}" ]]; then
  echo "Missing required env var: CALLBACK_ADDR or DESTINATION_CONTRACT" >&2
  exit 1
fi
topic0="${RECEIVED_TOPIC0}"
reactive_key="$(effective_private_key REACTIVE_PRIVATE_KEY)"
reactive_deploy_amount="${REACTIVE_DEPLOY_AMOUNT:-0.1ether}"

output="$(
  forge_with_local_solc create src/BasicDemoReactiveContract.sol:BasicDemoReactiveContract \
    --rpc-url "${reactive_rpc}" \
    --private-key "${reactive_key}" \
    --broadcast \
    --value "${reactive_deploy_amount}" \
    --constructor-args \
      "${ORIGIN_CHAIN_ID}" \
      "${DESTINATION_CHAIN_ID}" \
      "${origin_contract}" \
      "${topic0}" \
      "${callback_addr}"
)"

printf '%s\n' "${output}"

reactive_address="$(printf '%s\n' "${output}" | extract_deployed_to)"
reactive_tx_hash="$(printf '%s\n' "${output}" | extract_tx_hash)"

set_env_value "REACTIVE_CONTRACT" "${reactive_address}"
set_env_value "REACTIVE_ADDR" "${reactive_address}"
set_env_value "REACTIVE_DEPLOY_TX" "${reactive_tx_hash}"
set_env_value "RECEIVED_TOPIC0" "${topic0}"

echo
echo "Updated .env:"
print_next_env_line "REACTIVE_CONTRACT" "${reactive_address}"
print_next_env_line "REACTIVE_ADDR" "${reactive_address}"
print_next_env_line "REACTIVE_DEPLOY_TX" "${reactive_tx_hash}"
print_next_env_line "RECEIVED_TOPIC0" "${topic0}"
