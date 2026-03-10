#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

load_env
require_env "DESTINATION_RPC_URL"
require_env "CALLBACK_PROXY"

destination_key="$(effective_private_key DESTINATION_PRIVATE_KEY)"
authorized_rvm_id="$(effective_authorized_rvm_id)"
destination_deploy_amount="${DESTINATION_DEPLOY_AMOUNT:-0.01ether}"

output="$(
  forge_with_local_solc create src/DestinationCallbackReceiver.sol:DestinationCallbackReceiver \
    --rpc-url "${DESTINATION_RPC_URL}" \
    --private-key "${destination_key}" \
    --broadcast \
    --value "${destination_deploy_amount}" \
    --constructor-args "${CALLBACK_PROXY}"
)"

printf '%s\n' "${output}"

destination_address="$(printf '%s\n' "${output}" | extract_deployed_to)"
destination_tx_hash="$(printf '%s\n' "${output}" | extract_tx_hash)"

set_env_value "DESTINATION_CONTRACT" "${destination_address}"
set_env_value "DESTINATION_DEPLOY_TX" "${destination_tx_hash}"
set_env_value "AUTHORIZED_RVM_ID" "${authorized_rvm_id}"

echo
echo "Updated .env:"
print_next_env_line "DESTINATION_CONTRACT" "${destination_address}"
print_next_env_line "DESTINATION_DEPLOY_TX" "${destination_tx_hash}"
print_next_env_line "AUTHORIZED_RVM_ID" "${authorized_rvm_id}"
