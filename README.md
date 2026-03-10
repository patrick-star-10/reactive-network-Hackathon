# Reactive Assignment Starter

这个目录是一个从零搭建的最小作业模板，覆盖三份合约：

- `OriginEventSource`: 在源链执行 `setValue` 并发出事件
- `ValueSetListenerReactive`: 在 Reactive Network 订阅源链事件，并向目标链发 callback
- `DestinationCallbackReceiver`: 在目标链接收 callback 并同步另一个 `value`

当前版本已经切到直接依赖官方 `reactive-lib` 的实现。官方库源码被放在 `lib/reactive-lib`，来源：

- https://github.com/Reactive-Network/reactive-lib

## 项目说明

这个项目实现了一个最小的 Reactive Network 事件到回调闭环：

1. 在 Base Sepolia 上调用 `OriginEventSource.setValue(uint256)`
2. 源链发出 `ValueSet(address,uint256,uint256)` 事件
3. Reactive Lasna 上的 `ValueSetListenerReactive` 监听该事件
4. 监听合约发出 `Callback(...)`
5. Ethereum Sepolia 上的 `DestinationCallbackReceiver.callback(...)` 被 callback proxy 调用
6. 目标链状态被更新，`mirroredValue` 与源链传入值保持一致

## 已验证结果

当前仓库已经完成一组成功验证：

- OriginEventSource: `0x57A372A1C2cfCEf2C5be589c95f4aF1Ccd5412Ae`
- ValueSetListenerReactive: `0xbC2592E0686b6900AD382CA6Ae9A01Dc3b412498`
- DestinationCallbackReceiver: `0x32Bf10b95fE7bd489b3255E7839153E281d40Ee9`
- 最终同步值: `44`

更完整的部署地址、交易哈希和浏览器证明见 [SUBMISSION_BRIEF.md](/Users/wx/Desktop/Reactive-learning/SUBMISSION_BRIEF.md)。

## 项目结构

- `src/OriginEventSource.sol`
- `src/ValueSetListenerReactive.sol`
- `src/DestinationCallbackReceiver.sol`
- `lib/reactive-lib/src/abstract-base/AbstractReactive.sol`
- `lib/reactive-lib/src/abstract-base/AbstractPayer.sol`
- `lib/reactive-lib/src/interfaces/IReactive.sol`
- `lib/reactive-lib/src/interfaces/ISystemContract.sol`
- `scripts/deploy_origin.sh`
- `scripts/deploy_destination.sh`
- `scripts/deploy_reactive.sh`
- `scripts/fund_and_trigger.sh`
- `scripts/check_destination.sh`

## 机制对应关系

1. 在源链调用 `OriginEventSource.setValue(42)`
2. 源链发出 `ValueSet(address,uint256,uint256)` 事件
3. `ValueSetListenerReactive` 在 RNK 上已订阅该事件
4. Reactive VM 收到日志后执行 `react(LogRecord)`
5. Reactive 合约发出 `Callback(...)`
6. 目标链上的 `DestinationCallbackReceiver.callback(...)` 被 callback proxy 调用

`callback` 的第一个参数 `rvmId` 必须预留给 Reactive Network 注入。

## 合约说明

### 1. OriginEventSource

- `setValue(uint256 newValue)`: 更新源链 `value` 并发出一条 `ValueSet` 事件
- `valueSetTopic0()`: 返回 `ValueSet` 事件的 `topic0`

### 2. ValueSetListenerReactive

构造参数：

1. `service`: Reactive Network 系统合约地址
2. `originChainId`: 源链 chain id
3. `destinationChainId`: 目标链 chain id
4. `originContract`: 源链事件合约地址
5. `expectedTopic0`: 监听的事件签名 topic0
6. `destinationContract`: 目标链回调合约地址

行为：

- 继承官方 `AbstractReactive`
- 构造时通过官方 `ISystemContract` 调用 `subscribe(...)`
- 在 RVM 侧通过 `vmOnly` 执行 `react(...)`
- 将源链事件里的 `sender`、`newValue`、`timestamp` 编码后发往目标链

### 3. DestinationCallbackReceiver

构造参数：

1. `callbackProxy`: 目标链 callback proxy 地址

行为：

- 继承官方 `AbstractPayer`
- 仅允许 `callbackProxy` 调用 `callback(...)`
- 仅接受指定 `authorizedRvmId` 的回调
- 更新目标链上的 `mirroredValue`
- 复用官方 `pay(uint256)` 以便 callback proxy 从合约余额中扣费

## 部署顺序

推荐顺序：

1. 部署 `OriginEventSource` 到源链
2. 部署 `DestinationCallbackReceiver` 到目标链
3. 部署 `ValueSetListenerReactive` 到 Reactive Network
4. 给 `DestinationCallbackReceiver` 充值原生代币
5. 触发 `OriginEventSource.setValue(...)`
6. 在目标链检查 `CallbackReceived` 事件

## 参数准备

你至少需要准备这些值：

- `ORIGIN_CHAIN_ID`
- `DESTINATION_CHAIN_ID`
- `SYSTEM_CONTRACT`
- `CALLBACK_PROXY`
- `AUTHORIZED_RVM_ID`

说明：

- `AUTHORIZED_RVM_ID` 一般就是部署 Reactive 合约的 EOA 地址
- `SYSTEM_CONTRACT` 需要填 Reactive Network 当前网络的系统合约地址
- `CALLBACK_PROXY` 需要填目标链当前已部署的 callback proxy 地址

请以 Reactive 官方文档中的当前网络参数为准：

- https://dev.reactive.network/reactive-mainnet
- https://dev.reactive.network/origins-and-destinations
- https://dev.reactive.network/events-%26-callbacks

当前目录里的 [`.env`](/Users/wx/Desktop/Reactive-learning/.env) 已经填入一组可用网络参数，基于 2026-03-09 当天文档内容：

- Origin: Base Sepolia `84532`
- Reactive: Reactive Lasna `5318007`
- Destination: Ethereum Sepolia `11155111`
- System contract: `0x0000000000000000000000000000000000fffFfF`
- Ethereum Sepolia callback proxy: `0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA`

只需要在 [`.env`](/Users/wx/Desktop/Reactive-learning/.env) 里填上 `PRIVATE_KEY` 即可开始部署。

## 编译

```bash
forge build --no-auto-detect --use ./tools/solc-0.8.20
```

当前项目已经自带官方原生 `solc 0.8.20`，位于 [tools/solc-0.8.20](/Users/wx/Desktop/Reactive-learning/tools/solc-0.8.20)。这样可以绕开这台机器上 Foundry 自动安装 `solc` 时的崩溃问题。

## 一个典型提交流程

你最终可以提交一份简短说明，格式类似下面这样：

```md
# Reactive Homework Submission

## Deployment
- OriginEventSource: <address>
- DestinationCallbackReceiver: <address>
- ValueSetListenerReactive: <address>

## Transactions
- Origin deploy tx: <hash>
- Destination deploy tx: <hash>
- Reactive deploy tx: <hash>
- Trigger tx: <hash>

## Proof
- 源链事件浏览器链接: <url>
- 目标链回调事件浏览器链接: <url>
- 截图: <optional>

## Notes
- Origin chain id: <id>
- Destination chain id: <id>
- Authorized RVM ID: <address>
- Synced value: <value>
```

## 验证点

如果流程正确，你应该能看到：

1. 源链 `ValueSet` 事件成功发出
2. 目标链 `CallbackReceived` 事件成功发出
3. `mirroredValue` 和 `lastOriginalSender` 被更新

## 本地验证记录

已完成：

- `forge fmt --check`
- `forge --no-auto-detect --use ./tools/solc-0.8.20 build`

## 部署脚本

1. 部署源链合约：

```bash
./scripts/deploy_origin.sh
```

2. 部署目标链回调合约：

```bash
./scripts/deploy_destination.sh
```

3. 部署 Reactive 合约：

```bash
./scripts/deploy_reactive.sh
```

4. 充值并触发事件：

```bash
./scripts/fund_and_trigger.sh
```

5. 查询目标链状态：

```bash
./scripts/check_destination.sh
```
