#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

load_env
require_env "DESTINATION_RPC_URL"
require_env "DESTINATION_CONTRACT"

echo "lastOriginalSender: $(cast call "${DESTINATION_CONTRACT}" 'lastOriginalSender()(address)' --rpc-url "${DESTINATION_RPC_URL}")"
echo "lastOriginChainId: $(cast call "${DESTINATION_CONTRACT}" 'lastOriginChainId()(uint256)' --rpc-url "${DESTINATION_RPC_URL}")"
echo "lastOriginContract: $(cast call "${DESTINATION_CONTRACT}" 'lastOriginContract()(address)' --rpc-url "${DESTINATION_RPC_URL}")"
echo "mirroredValue: $(cast call "${DESTINATION_CONTRACT}" 'mirroredValue()(uint256)' --rpc-url "${DESTINATION_RPC_URL}")"
echo "lastOriginTimestamp: $(cast call "${DESTINATION_CONTRACT}" 'lastOriginTimestamp()(uint256)' --rpc-url "${DESTINATION_RPC_URL}")"
