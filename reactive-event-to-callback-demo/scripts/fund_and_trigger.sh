#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

load_env
destination_rpc="$(destination_rpc_url)"
origin_rpc="$(origin_rpc_url)"
callback_proxy="$(callback_proxy_addr)"
destination_contract="${CALLBACK_ADDR:-${DESTINATION_CONTRACT:-}}"
origin_contract="${ORIGIN_ADDR:-${ORIGIN_CONTRACT:-}}"
if [[ -z "${destination_rpc}" ]]; then
  echo "Missing required env var: DESTINATION_RPC or DESTINATION_RPC_URL" >&2
  exit 1
fi
if [[ -z "${origin_rpc}" ]]; then
  echo "Missing required env var: ORIGIN_RPC or ORIGIN_RPC_URL" >&2
  exit 1
fi
if [[ -z "${destination_contract}" ]]; then
  echo "Missing required env var: CALLBACK_ADDR or DESTINATION_CONTRACT" >&2
  exit 1
fi
if [[ -z "${origin_contract}" ]]; then
  echo "Missing required env var: ORIGIN_ADDR or ORIGIN_CONTRACT" >&2
  exit 1
fi
if [[ -z "${callback_proxy}" ]]; then
  echo "Missing required env var: DESTINATION_CALLBACK_PROXY_ADDR or CALLBACK_PROXY" >&2
  exit 1
fi
fund_key="$(effective_private_key DESTINATION_PRIVATE_KEY)"
origin_key="$(effective_private_key ORIGIN_PRIVATE_KEY)"

fund_amount="${DESTINATION_FUND_AMOUNT:-0.01ether}"
trigger_amount="${1:-${TRIGGER_VALUE:-0.001ether}}"

echo "Funding destination callback contract via callback proxy deposit..."
fund_tx_hash="$(
  cast send "${callback_proxy}" \
    'depositTo(address)' "${destination_contract}" \
    --rpc-url "${destination_rpc}" \
    --private-key "${fund_key}" \
    --value "${fund_amount}" | awk '/transactionHash/ { print $2 }' | tail -n 1
)"

echo "Triggering origin receive() with ETH..."
trigger_tx_hash="$(
  cast send "${origin_contract}" \
    --rpc-url "${origin_rpc}" \
    --private-key "${origin_key}" \
    --value "${trigger_amount}" | awk '/transactionHash/ { print $2 }' | tail -n 1
)"

set_env_value "DESTINATION_FUND_TX" "${fund_tx_hash}"
set_env_value "ORIGIN_TRIGGER_TX" "${trigger_tx_hash}"
set_env_value "TRIGGER_VALUE" "${trigger_amount}"

echo
echo "Updated .env:"
print_next_env_line "DESTINATION_FUND_TX" "${fund_tx_hash}"
print_next_env_line "ORIGIN_TRIGGER_TX" "${trigger_tx_hash}"
print_next_env_line "TRIGGER_VALUE" "${trigger_amount}"
