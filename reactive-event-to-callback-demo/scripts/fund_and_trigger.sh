#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

load_env
require_env "DESTINATION_RPC_URL"
require_env "ORIGIN_RPC_URL"
require_env "DESTINATION_CONTRACT"
require_env "ORIGIN_CONTRACT"
require_env "CALLBACK_PROXY"

fund_key="$(effective_private_key DESTINATION_PRIVATE_KEY)"
origin_key="$(effective_private_key ORIGIN_PRIVATE_KEY)"

fund_amount="${DESTINATION_FUND_AMOUNT:-0.01ether}"
new_value="${1:-${SET_VALUE:-42}}"

echo "Funding destination callback contract via callback proxy deposit..."
fund_tx_hash="$(
  cast send "${CALLBACK_PROXY}" \
    'depositTo(address)' "${DESTINATION_CONTRACT}" \
    --rpc-url "${DESTINATION_RPC_URL}" \
    --private-key "${fund_key}" \
    --value "${fund_amount}" | awk '/transactionHash/ { print $2 }' | tail -n 1
)"

echo "Triggering origin event..."
trigger_tx_hash="$(
  cast send "${ORIGIN_CONTRACT}" \
    'setValue(uint256)' "${new_value}" \
    --rpc-url "${ORIGIN_RPC_URL}" \
    --private-key "${origin_key}" | awk '/transactionHash/ { print $2 }' | tail -n 1
)"

set_env_value "DESTINATION_FUND_TX" "${fund_tx_hash}"
set_env_value "ORIGIN_TRIGGER_TX" "${trigger_tx_hash}"
set_env_value "SET_VALUE" "${new_value}"

echo
echo "Updated .env:"
print_next_env_line "DESTINATION_FUND_TX" "${fund_tx_hash}"
print_next_env_line "ORIGIN_TRIGGER_TX" "${trigger_tx_hash}"
print_next_env_line "SET_VALUE" "${new_value}"
