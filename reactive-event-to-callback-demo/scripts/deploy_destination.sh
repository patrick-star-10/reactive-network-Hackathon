#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

load_env
destination_rpc="$(destination_rpc_url)"
callback_proxy="$(callback_proxy_addr)"
if [[ -z "${destination_rpc}" ]]; then
  echo "Missing required env var: DESTINATION_RPC or DESTINATION_RPC_URL" >&2
  exit 1
fi
if [[ -z "${callback_proxy}" ]]; then
  echo "Missing required env var: DESTINATION_CALLBACK_PROXY_ADDR or CALLBACK_PROXY" >&2
  exit 1
fi
destination_key="$(effective_private_key DESTINATION_PRIVATE_KEY)"
destination_deploy_amount="${DESTINATION_DEPLOY_AMOUNT:-0.02ether}"

output="$(
  forge_with_local_solc create src/BasicDemoL1Callback.sol:BasicDemoL1Callback \
    --rpc-url "${destination_rpc}" \
    --private-key "${destination_key}" \
    --broadcast \
    --value "${destination_deploy_amount}" \
    --constructor-args "${callback_proxy}"
)"

printf '%s\n' "${output}"

destination_address="$(printf '%s\n' "${output}" | extract_deployed_to)"
destination_tx_hash="$(printf '%s\n' "${output}" | extract_tx_hash)"

set_env_value "DESTINATION_CONTRACT" "${destination_address}"
set_env_value "CALLBACK_ADDR" "${destination_address}"
set_env_value "DESTINATION_DEPLOY_TX" "${destination_tx_hash}"

echo
echo "Updated .env:"
print_next_env_line "DESTINATION_CONTRACT" "${destination_address}"
print_next_env_line "CALLBACK_ADDR" "${destination_address}"
print_next_env_line "DESTINATION_DEPLOY_TX" "${destination_tx_hash}"
