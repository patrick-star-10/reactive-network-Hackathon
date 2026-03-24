# Reactive Network Demo

## Overview

The **Reactive Network Demo** illustrates a basic use case of the Reactive Network with two key functionalities:

* Low-latency monitoring of logs emitted by a contract on the origin chain.
* Executing calls from the Reactive Network to a contract on the destination chain.

This setup can be adapted for various scenarios, from simple stop orders to fully decentralized algorithmic trading.

## Contracts

**Origin Contract**: `src/BasicDemoL1Contract.sol` receives Ether and returns it to the sender, emitting a `Received` event with transaction details.

**Reactive Contract**: `src/BasicDemoReactiveContract.sol` demonstrates a reactive subscription model. It subscribes to logs from a specified contract and processes event data in a decentralized manner. The contract subscribes to events from a specified contract on the origin chain. Upon receiving a log, it checks if `topic_3` is at least `0.001 ether`. If the condition is met, it emits a `Callback` event containing a payload to invoke an external callback function on the destination chain.

**Destination Contract**: `src/BasicDemoL1Callback.sol` serves as the destination contract for handling reactive callbacks. When triggered by a cross-chain event, it logs key transaction details while ensuring only authorized senders can invoke the callback. Upon execution, it emits a `CallbackReceived` event, capturing metadata such as the origin, sender, and reactive sender addresses.

## Further Considerations

The demo highlights just a fraction of Reactive Network’s capabilities. Future enhancements could include:

- **Expanded Event Subscriptions**: Monitoring multiple event sources, including callback logs.
- **Dynamic Subscriptions**: Adjusting subscriptions in real-time based on evolving conditions.
- **State Persistence**: Maintaining contract state for more complex, context-aware reactions.
- **Versatile Callbacks**: Enabling customizable transaction payloads to improve adaptability.

## Deployment & Testing

### Environment Variables

Before proceeding further, configure these environment variables:

* `ORIGIN_RPC` or `ORIGIN_RPC_URL`
* `ORIGIN_CHAIN_ID`
* `ORIGIN_PRIVATE_KEY`
* `DESTINATION_RPC` or `DESTINATION_RPC_URL`
* `DESTINATION_CHAIN_ID`
* `DESTINATION_PRIVATE_KEY`
* `REACTIVE_RPC` or `REACTIVE_RPC_URL`
* `REACTIVE_PRIVATE_KEY`
* `DESTINATION_CALLBACK_PROXY_ADDR` or `CALLBACK_PROXY`

### Compile

```bash
forge build --no-auto-detect --use ./tools/solc-0.8.20
```

### Step 1 — Origin Contract

Deploy the `BasicDemoL1Contract` contract:

```bash
./scripts/deploy_origin.sh
```

### Step 2 — Destination Contract

Deploy the `BasicDemoL1Callback` contract:

```bash
./scripts/deploy_destination.sh
```

### Step 3 — Reactive Contract

Deploy the `BasicDemoReactiveContract` contract:

```bash
./scripts/deploy_reactive.sh
```

### Step 4 — Test Reactive Callback

Fund the callback reserve and trigger the origin contract with at least `0.001 ether`:

```bash
./scripts/fund_and_trigger.sh 0.001ether
```

Inspect recent callback logs:

```bash
./scripts/check_destination.sh
```

## Submission

This folder has now been aligned to the official `basic` demo contract flow and file structure.

### Challenge Format

```text
Demo 1: Reactive Network Demo (basic) / 0xf03e39d45a2272d41f5f61841c270e81e8271d641de757891b8f6d7fb8dbd877 / 0x310955264bf4dd23d7095dbdb620734306eb639878d47f55f12b15705acb1eec / 0xed0013734a9b0d0b456f75dee8dcafc11d3eb0ee5914e0594175a9a45da5e384
```

### Proof Details

- Origin contract: `0x3e29fb93e258885Ba96250545207AaB0Fd8DC2FB`
- Reactive contract: `0x4998fdC1f405103f1465F98cc418D6020eF74080`
- Destination callback contract: `0xE835A7d7E344C9FE5bFDe425d0974917012C0211`
- Callback proxy reserve deposit tx: `0x5438b0a78f0cf8d430b76f58cba8aee30351c587be74f988af222b481f2f7924`
- Origin tx: `0xf03e39d45a2272d41f5f61841c270e81e8271d641de757891b8f6d7fb8dbd877`
- Reactive tx: `0x310955264bf4dd23d7095dbdb620734306eb639878d47f55f12b15705acb1eec`
- Destination tx: `0xed0013734a9b0d0b456f75dee8dcafc11d3eb0ee5914e0594175a9a45da5e384`

### Notes

- The Lasna `reactive tx` was identified via `rnk_getRnkAddressMapping`, `rnk_getHeadNumber`, and `rnk_getTransactions`, matched by `refTx = 0xf03e39d45a2272d41f5f61841c270e81e8271d641de757891b8f6d7fb8dbd877`.
- The destination callback proof comes from the `CallbackReceived` event emitted by `BasicDemoL1Callback`.
