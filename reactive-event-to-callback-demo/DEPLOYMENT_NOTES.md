# Deployment Notes

## Constructor Args

### OriginEventSource

无需参数。

### DestinationCallbackReceiver

1. `callbackProxy`
2. `authorizedRvmId`

`authorizedRvmId` 填部署 Reactive 合约的那个 EOA 地址。

### ValueSetListenerReactive

1. `service`
2. `originChainId`
3. `destinationChainId`
4. `originContract`
5. `expectedTopic0`
6. `destinationContract`

## `expectedTopic0`

两种拿法都可以：

1. 部署 `OriginEventSource` 后，直接调用 `valueSetTopic0()`
2. 用 `cast` 本地计算

```bash
cast keccak "ValueSet(address,uint256,uint256)"
```

## Trigger Proof

源链调用：

```solidity
setValue(42)
```

目标链验证：

1. 检查 `CallbackReceived` 事件
2. 读取 `mirroredValue()`
3. 读取 `lastOriginalSender()`
4. 读取 `lastOriginTimestamp()`

## Important

- `reactCallback` 的第一个参数必须保留给 Reactive Network 注入的 `rvmId`
- 目标回调合约需要有原生代币余额，否则 `pay(uint256)` 无法成功结算
- `callbackProxy` 和 `system contract` 请以 Reactive 官方当前文档为准
