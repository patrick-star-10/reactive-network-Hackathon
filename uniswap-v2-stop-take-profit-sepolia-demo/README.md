# Uniswap V2 Stop-Loss & Take-Profit Orders

## Overview

This folder is the packaged `Demo3` submission for the Reactive Network challenge.

The selected official demo is:

- `src/demos/uniswap-v2-stop-take-profit-order`

This package keeps the working Sepolia + Reactive Lasna testnet version that was actually deployed and verified.

## Contracts

- Origin / Destination contract: `src/demos/uniswap-v2-stop-take-profit-order/UniswapDemoStopTakeProfitCallback.sol`
- Reactive contract: `src/demos/uniswap-v2-stop-take-profit-order/UniswapDemoStopTakeProfitReactive.sol`
- Demo token contract: `src/demos/uniswap-v2-stop-order/UniswapDemoToken.sol`

## Testnet Adaptation

The official demo was adapted to the challenge environment by using:

- Ethereum Sepolia as the supported origin / destination testnet
- Reactive Lasna Testnet as the reactive deployment target

The reactive contract in this folder is already patched for:

- `SEPOLIA_CHAIN_ID = 11155111`
- `REACTIVE_CHAIN_ID = 5318007`

## Project Layout

- `README.md`: submission overview and final challenge line
- `demo跑通证明.md`: full workflow proof and deployment record
- `.env.example`: environment template
- `scripts/uniswap-stop-take-profit-sepolia.sh`: helper script for deployment and triggering
- `src/demos/uniswap-v2-stop-take-profit-order/*`: main demo contracts

## Environment

Copy `.env.example` to `.env` and fill the private keys and RPCs:

```bash
cp .env.example .env
```

## Build

```bash
forge build
```

## Helper Script

```bash
./scripts/uniswap-stop-take-profit-sepolia.sh info
./scripts/uniswap-stop-take-profit-sepolia.sh env-check
```

Supported commands:

- `deploy-token <name> <symbol>`
- `create-pair`
- `add-liquidity`
- `deploy-callback`
- `fund-callback-proxy`
- `deploy-reactive`
- `approve`
- `create-order`
- `trigger`

## Submission

```text
Demo 3: Uniswap V2 Stop-Loss & Take-Profit Orders / 0x565ec6b790ded5b615c37a7b2602503bcf72f1accc6d0c192f986000ed526cc2 / 0xc70996d9d085c3466fe497aacf0a52f548616b946bffec6d754e2f1e4bebc155 / 0xe15496acc49fa1d1ebd2514dd433f76342d2906c9e19fc418de2df1f683e22fa
```

## Proof Summary

- Origin pair: `0x437192927863E11456634f4212845fD60ef17E16`
- Destination callback: `0x397aebEcB95454A6482e6136641b886eF293F8c3`
- Reactive contract: `0xea795B0cb4e4068f44304A27B8a455EF66B223DF`
- Origin tx: `0x565ec6b790ded5b615c37a7b2602503bcf72f1accc6d0c192f986000ed526cc2`
- Reactive tx: `0xc70996d9d085c3466fe497aacf0a52f548616b946bffec6d754e2f1e4bebc155`
- Destination tx: `0xe15496acc49fa1d1ebd2514dd433f76342d2906c9e19fc418de2df1f683e22fa`

See `demo跑通证明.md` for the full workflow record.
