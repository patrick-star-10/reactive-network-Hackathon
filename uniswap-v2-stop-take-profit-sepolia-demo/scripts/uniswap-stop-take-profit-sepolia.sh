#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

DEMO_CONTRACT_DIR="src/demos/uniswap-v2-stop-take-profit-order"
TOKEN_CONTRACT_PATH="src/demos/uniswap-v2-stop-order/UniswapDemoToken.sol:UniswapDemoToken"
DEFAULT_TK1="0x2AFDE4A3Bca17E830c476c568014E595EA916a04"
DEFAULT_TK2="0x7EB2Ad352369bb6EDEb84D110657f2e40c912c95"
DEFAULT_PAIR="0x1DD11fD3690979f2602E42e7bBF68A19040E2e25"
DEFAULT_FACTORY="0x7E0987E5b3a30e3f2828572Bb659A548460a3003"
DEFAULT_ROUTER="0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008"
DEFAULT_CALLBACK_PROXY="0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA"
DEFAULT_REACTIVE_RPC="https://lasna-rpc.rnk.dev/"

: "${TK1:=$DEFAULT_TK1}"
: "${TK2:=$DEFAULT_TK2}"
: "${UNISWAP_V2_PAIR_ADDR:=$DEFAULT_PAIR}"
: "${UNISWAP_V2_FACTORY_ADDR:=$DEFAULT_FACTORY}"
: "${UNISWAP_V2_ROUTER_ADDR:=$DEFAULT_ROUTER}"
: "${DESTINATION_CALLBACK_PROXY_ADDR:=$DEFAULT_CALLBACK_PROXY}"
: "${REACTIVE_RPC:=$DEFAULT_REACTIVE_RPC}"
: "${USER_WALLET:=${CLIENT_WALLET:-}}"
: "${CLIENT_WALLET:=${USER_WALLET:-}}"
: "${ORDER_SELL_TOKEN0:=true}"
: "${ORDER_AMOUNT_WEI:=1000000000000000000}"
: "${ORDER_COEFFICIENT:=10000}"
: "${ORDER_THRESHOLD:=12000}"
: "${ORDER_TYPE:=1}"
: "${LIQUIDITY_TOKEN0_AMOUNT:=10000000000000000000}"
: "${LIQUIDITY_TOKEN1_AMOUNT:=10000000000000000000}"
: "${APPROVE_AMOUNT:=1000000000000000000}"
: "${CALLBACK_PROXY_DEPOSIT:=0.01ether}"
: "${TRIGGER_TRANSFER_AMOUNT:=20000000000000000}"
: "${TRIGGER_SWAP_AMOUNT0_OUT:=0}"
: "${TRIGGER_SWAP_AMOUNT1_OUT:=5000000000000000}"

usage() {
  cat <<'EOF'
Usage:
  scripts/uniswap-stop-take-profit-sepolia.sh <command> [args]

Commands:
  info
  env-check
  deploy-token <name> <symbol>
  create-pair
  add-liquidity
  deploy-callback
  fund-callback-proxy
  deploy-reactive
  approve
  create-order
  trigger

Notes:
  - This helper targets Ethereum Sepolia for origin / destination and
    Reactive Lasna for the reactive contract.
  - It loads .env automatically if present.
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

require_env() {
  local name
  for name in "$@"; do
    [[ -n "${!name:-}" ]] || die "missing required env var: $name"
  done
}

normalized_addr() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

lower() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

maybe_set_token_order() {
  if [[ -z "${TOKEN0_ADDR:-}" || -z "${TOKEN1_ADDR:-}" ]]; then
    local a b
    a="$(normalized_addr "$TK1")"
    b="$(normalized_addr "$TK2")"
    if [[ "$a" < "$b" ]]; then
      TOKEN0_ADDR="$TK1"
      TOKEN1_ADDR="$TK2"
    else
      TOKEN0_ADDR="$TK2"
      TOKEN1_ADDR="$TK1"
    fi
  fi
}

maybe_set_token_addr() {
  maybe_set_token_order
  if [[ "$(lower "$ORDER_SELL_TOKEN0")" == "true" ]]; then
    TOKEN_ADDR="$TOKEN0_ADDR"
  else
    TOKEN_ADDR="$TOKEN1_ADDR"
  fi
}

print_info() {
  maybe_set_token_order
  maybe_set_token_addr
  cat <<EOF
Destination chain: Ethereum Sepolia (chain id 11155111)
Reactive RPC:      $REACTIVE_RPC
Callback proxy:    $DESTINATION_CALLBACK_PROXY_ADDR
Factory:           $UNISWAP_V2_FACTORY_ADDR
Router:            $UNISWAP_V2_ROUTER_ADDR
Demo TK1:          $TK1
Demo TK2:          $TK2
Demo pair:         $UNISWAP_V2_PAIR_ADDR
Order owner:       ${USER_WALLET:-}
Derived token0:    ${TOKEN0_ADDR:-}
Derived token1:    ${TOKEN1_ADDR:-}
Sell token addr:   ${TOKEN_ADDR:-}
Sell token0:       $ORDER_SELL_TOKEN0
Order amount:      $ORDER_AMOUNT_WEI
Coefficient:       $ORDER_COEFFICIENT
Threshold:         $ORDER_THRESHOLD
Order type:        $ORDER_TYPE
EOF
}

env_check() {
  local missing=0
  local vars=(
    DESTINATION_RPC
    DESTINATION_PRIVATE_KEY
    REACTIVE_RPC
    REACTIVE_PRIVATE_KEY
    DESTINATION_CALLBACK_PROXY_ADDR
    USER_WALLET
  )
  local name
  for name in "${vars[@]}"; do
    if [[ -z "${!name:-}" ]]; then
      echo "missing: $name"
      missing=1
    else
      echo "ok: $name"
    fi
  done
  if [[ "$missing" -ne 0 ]]; then
    exit 1
  fi
}

deploy_token() {
  local name="${1:-}"
  local symbol="${2:-}"
  [[ -n "$name" && -n "$symbol" ]] || die "usage: deploy-token <name> <symbol>"
  require_env DESTINATION_RPC DESTINATION_PRIVATE_KEY
  forge create --broadcast \
    --rpc-url "$DESTINATION_RPC" \
    --private-key "$DESTINATION_PRIVATE_KEY" \
    "$TOKEN_CONTRACT_PATH" \
    --constructor-args "$name" "$symbol"
}

create_pair() {
  maybe_set_token_order
  require_env DESTINATION_RPC DESTINATION_PRIVATE_KEY TOKEN0_ADDR TOKEN1_ADDR
  cast send "$UNISWAP_V2_FACTORY_ADDR" \
    'createPair(address,address)' \
    --rpc-url "$DESTINATION_RPC" \
    --private-key "$DESTINATION_PRIVATE_KEY" \
    "$TOKEN0_ADDR" "$TOKEN1_ADDR"
}

deploy_callback() {
  require_env DESTINATION_RPC DESTINATION_PRIVATE_KEY DESTINATION_CALLBACK_PROXY_ADDR USER_WALLET
  forge create --broadcast \
    --rpc-url "$DESTINATION_RPC" \
    --private-key "$DESTINATION_PRIVATE_KEY" \
    "$DEMO_CONTRACT_DIR/UniswapDemoStopTakeProfitCallback.sol:UniswapDemoStopTakeProfitCallback" \
    --value 0.02ether \
    --constructor-args "$USER_WALLET" "$DESTINATION_CALLBACK_PROXY_ADDR" "$UNISWAP_V2_ROUTER_ADDR"
}

add_liquidity() {
  maybe_set_token_order
  require_env DESTINATION_RPC DESTINATION_PRIVATE_KEY UNISWAP_V2_PAIR_ADDR USER_WALLET TOKEN0_ADDR TOKEN1_ADDR
  cast send "$TOKEN0_ADDR" \
    'transfer(address,uint256)' \
    --rpc-url "$DESTINATION_RPC" \
    --private-key "$DESTINATION_PRIVATE_KEY" \
    "$UNISWAP_V2_PAIR_ADDR" "$LIQUIDITY_TOKEN0_AMOUNT"
  cast send "$TOKEN1_ADDR" \
    'transfer(address,uint256)' \
    --rpc-url "$DESTINATION_RPC" \
    --private-key "$DESTINATION_PRIVATE_KEY" \
    "$UNISWAP_V2_PAIR_ADDR" "$LIQUIDITY_TOKEN1_AMOUNT"
  cast send "$UNISWAP_V2_PAIR_ADDR" \
    'mint(address)' \
    --rpc-url "$DESTINATION_RPC" \
    --private-key "$DESTINATION_PRIVATE_KEY" \
    "$USER_WALLET"
}

fund_callback_proxy() {
  require_env DESTINATION_RPC DESTINATION_PRIVATE_KEY DESTINATION_CALLBACK_PROXY_ADDR CALLBACK_ADDR
  cast send "$DESTINATION_CALLBACK_PROXY_ADDR" \
    'depositTo(address)' \
    --rpc-url "$DESTINATION_RPC" \
    --private-key "$DESTINATION_PRIVATE_KEY" \
    --value "$CALLBACK_PROXY_DEPOSIT" \
    "$CALLBACK_ADDR"
}

deploy_reactive() {
  require_env REACTIVE_RPC REACTIVE_PRIVATE_KEY CALLBACK_ADDR USER_WALLET
  forge create --broadcast \
    --rpc-url "$REACTIVE_RPC" \
    --private-key "$REACTIVE_PRIVATE_KEY" \
    "$DEMO_CONTRACT_DIR/UniswapDemoStopTakeProfitReactive.sol:UniswapDemoStopTakeProfitReactive" \
    --value 0.1ether \
    --constructor-args "$USER_WALLET" "$CALLBACK_ADDR"
}

approve_token() {
  maybe_set_token_addr
  require_env DESTINATION_RPC DESTINATION_PRIVATE_KEY TOKEN_ADDR CALLBACK_ADDR
  cast send "$TOKEN_ADDR" \
    'approve(address,uint256)' \
    --rpc-url "$DESTINATION_RPC" \
    --private-key "$DESTINATION_PRIVATE_KEY" \
    "$CALLBACK_ADDR" "$APPROVE_AMOUNT"
}

create_order() {
  require_env DESTINATION_RPC DESTINATION_PRIVATE_KEY CALLBACK_ADDR UNISWAP_V2_PAIR_ADDR ORDER_SELL_TOKEN0 ORDER_AMOUNT_WEI ORDER_COEFFICIENT ORDER_THRESHOLD ORDER_TYPE
  cast send "$CALLBACK_ADDR" \
    'createStopOrder(address,bool,uint256,uint256,uint256,uint8)' \
    --rpc-url "$DESTINATION_RPC" \
    --private-key "$DESTINATION_PRIVATE_KEY" \
    "$UNISWAP_V2_PAIR_ADDR" "$ORDER_SELL_TOKEN0" "$ORDER_AMOUNT_WEI" "$ORDER_COEFFICIENT" "$ORDER_THRESHOLD" "$ORDER_TYPE"
}

trigger_order() {
  maybe_set_token_addr
  require_env DESTINATION_RPC DESTINATION_PRIVATE_KEY TOKEN_ADDR UNISWAP_V2_PAIR_ADDR USER_WALLET
  cast send "$TOKEN_ADDR" \
    'transfer(address,uint256)' \
    --rpc-url "$DESTINATION_RPC" \
    --private-key "$DESTINATION_PRIVATE_KEY" \
    "$UNISWAP_V2_PAIR_ADDR" "$TRIGGER_TRANSFER_AMOUNT"
  cast send "$UNISWAP_V2_PAIR_ADDR" \
    'swap(uint,uint,address,bytes)' \
    --rpc-url "$DESTINATION_RPC" \
    --private-key "$DESTINATION_PRIVATE_KEY" \
    "$TRIGGER_SWAP_AMOUNT0_OUT" "$TRIGGER_SWAP_AMOUNT1_OUT" "$USER_WALLET" "0x"
}

command="${1:-info}"
shift || true

case "$command" in
  info)
    print_info
    ;;
  env-check)
    env_check
    ;;
  deploy-token)
    deploy_token "$@"
    ;;
  create-pair)
    create_pair
    ;;
  add-liquidity)
    add_liquidity
    ;;
  deploy-callback)
    deploy_callback
    ;;
  fund-callback-proxy)
    fund_callback_proxy
    ;;
  deploy-reactive)
    deploy_reactive
    ;;
  approve)
    approve_token
    ;;
  create-order)
    create_order
    ;;
  trigger)
    trigger_order
    ;;
  *)
    usage
    exit 1
    ;;
esac
