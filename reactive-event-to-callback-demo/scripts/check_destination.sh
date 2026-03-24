#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

load_env
destination_rpc="$(destination_rpc_url)"
destination_contract="${CALLBACK_ADDR:-${DESTINATION_CONTRACT:-}}"
if [[ -z "${destination_rpc}" ]]; then
  echo "Missing required env var: DESTINATION_RPC or DESTINATION_RPC_URL" >&2
  exit 1
fi
if [[ -z "${destination_contract}" ]]; then
  echo "Missing required env var: CALLBACK_ADDR or DESTINATION_CONTRACT" >&2
  exit 1
fi

echo "Recent callback events for ${destination_contract}:"
latest_block="$(cast block-number --rpc-url "${destination_rpc}")"
from_block="$(( latest_block > 5000 ? latest_block - 5000 : 0 ))"

cast logs \
  --rpc-url "${destination_rpc}" \
  --address "${destination_contract}" \
  --from-block "${from_block}" \
  --to-block "${latest_block}"
