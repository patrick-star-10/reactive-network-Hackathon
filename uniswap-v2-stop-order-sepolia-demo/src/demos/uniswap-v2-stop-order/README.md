# Uniswap V2 止损单 Demo

## 概述

这个 **Uniswap V2 止损单 Demo** 展示了一个响应式智能合约如何持续监听 Uniswap V2 流动性池中的 `Sync` 事件，并在汇率达到预设阈值时自动执行卖出操作。

这个 Demo 延续了 Reactive Network 基础示例中的核心模式：

`事件 -> Reactive Contract 响应 -> callback 回调执行`

在这个例子里，Reactive Contract 监听 Sepolia 上 Uniswap V2 pair 的储备变化，当价格跌破阈值后，自动触发回调合约进行止损卖出。

## 合约说明

### 1. Token 合约

[UniswapDemoToken.sol](./UniswapDemoToken.sol)

这是一个简单的 ERC-20 测试代币合约。部署时会向部署者地址铸造 100 个 token，用于后续创建交易对和测试 swap。

### 2. Reactive 合约

[UniswapDemoStopOrderReactive.sol](./UniswapDemoStopOrderReactive.sol)

这个合约部署在 Reactive Network 上，主要职责是：

- 订阅 Ethereum Sepolia 上指定 Uniswap V2 pair 的 `Sync` 事件
- 订阅止损 callback 合约发出的 `Stop` 事件
- 持续检查 pair 储备是否低于预设阈值
- 当条件满足时，发出 `Callback` 事件，请求目标链上的 callback 合约执行止损
- 当收到对应的 `Stop` 事件后，将本次止损流程标记为完成

这个合约体现的是一种基础的“事件驱动自动化止损”模式。

### 3. Callback 合约

[UniswapDemoStopOrderCallback.sol](./UniswapDemoStopOrderCallback.sol)

这个合约部署在 Sepolia 上，负责实际执行止损逻辑。它被 Reactive Network 触发后会：

- 校验调用来源
- 读取 pair 当前储备并再次检查是否低于阈值
- 检查用户授权额度与余额
- 通过 Uniswap V2 Router 执行 token swap
- 把买入的 token 转回给用户
- 发出 `Stop` 事件，作为本次止损执行完成的证明

这个 callback 合约本身是无状态的，因此理论上可以被多个止损订单共用。

## 可以继续改进的方向

这个 Demo 已经能展示核心功能，但还有一些可以继续增强的点：

- 支持多个动态订单
- 增加更完整的错误处理和重试机制
- 支持不同 Router 或其他 DEX
- 优化 Reactive 合约与目标链 callback 合约之间的数据流

## 部署与测试

### 环境变量

在开始之前，请先配置以下环境变量：

- `DESTINATION_RPC`：目标链 RPC 地址，这个 Demo 使用的是 Ethereum Sepolia
- `DESTINATION_PRIVATE_KEY`：目标链交易签名私钥
- `REACTIVE_RPC`：Reactive Network RPC 地址
- `REACTIVE_PRIVATE_KEY`：Reactive Network 交易签名私钥
- `DESTINATION_CALLBACK_PROXY_ADDR`：Sepolia 上的 callback proxy 地址
- `CLIENT_WALLET`：你的 EOA 钱包地址

这个项目根目录已经提供了 `.env.example`，可以直接复制：

```bash
cp .env.example .env
source .env
```

对于这个精简后的作业模板，不需要额外配置 `ORIGIN_RPC` 或 `ORIGIN_PRIVATE_KEY`。

### Reactive Faucet 说明

如果你需要测试网 REACT，可以向 Reactive Sepolia faucet 合约发送 SepETH：

`0x9b9BB25f1A81078C544C829c5EB7822d747Cf434`

兑换比例是：

- `1 SepETH -> 100 REACT`

注意：

- 单次不要发送超过 `5 SepETH`
- 超出部分不会额外返还 REACT

### 如果 `forge create` 不支持 `--broadcast`

如果你看到类似错误：

```bash
error: unexpected argument '--broadcast' found
```

说明你的 Foundry 版本或本地环境不支持 `forge create --broadcast`，这时请移除 `--broadcast` 后再执行。

---

## 第 1 步：测试 token 与流动性池

要进行链上测试，你需要准备测试 token 和一个 Uniswap V2 流动性池。

你可以直接使用 README 提供的预置 token，也可以自己部署。

### 使用预置 token

```bash
export TK1=0x2AFDE4A3Bca17E830c476c568014E595EA916a04
export TK2=0x7EB2Ad352369bb6EDEb84D110657f2e40c912c95
```

### 自己部署 token

部署第一枚 token：

```bash
forge create --broadcast --rpc-url $DESTINATION_RPC --private-key $DESTINATION_PRIVATE_KEY src/demos/uniswap-v2-stop-order/UniswapDemoToken.sol:UniswapDemoToken --constructor-args TK1 TK1
```

部署第二枚 token：

```bash
forge create --broadcast --rpc-url $DESTINATION_RPC --private-key $DESTINATION_PRIVATE_KEY src/demos/uniswap-v2-stop-order/UniswapDemoToken.sol:UniswapDemoToken --constructor-args TK2 TK2
```

---

## 第 2 步：创建 Uniswap V2 Pair

如果你使用上面给出的预置 token，则可以直接使用预置 pair 地址：

```bash
export UNISWAP_V2_PAIR_ADDR=0x1DD11fD3690979f2602E42e7bBF68A19040E2e25
```

如果你是自己部署 token，则需要手动创建 pair：

```bash
cast send 0x7E0987E5b3a30e3f2828572Bb659A548460a3003 'createPair(address,address)' --rpc-url $DESTINATION_RPC --private-key $DESTINATION_PRIVATE_KEY $TOKEN0_ADDR $TOKEN1_ADDR
```

创建完成后，可以从 `PairCreated` 事件里拿到 pair 地址。

说明：

- 十六进制地址更小的 token 会成为 `token0`
- 另一个 token 会成为 `token1`

---

## 第 3 步：部署目标链 callback 合约

在 Ethereum Sepolia 上部署 callback 合约，Router 地址固定为：

`0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008`

部署命令：

```bash
forge create --broadcast --rpc-url $DESTINATION_RPC --private-key $DESTINATION_PRIVATE_KEY src/demos/uniswap-v2-stop-order/UniswapDemoStopOrderCallback.sol:UniswapDemoStopOrderCallback --value 0.02ether --constructor-args $DESTINATION_CALLBACK_PROXY_ADDR 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
```

部署成功后，请把输出中的 `Deployed to` 地址保存为：

```bash
export CALLBACK_ADDR=<你的 callback 合约地址>
```

---

## 第 4 步：给 Pair 注入流动性

先向 pair 地址分别转入两边 token：

```bash
cast send $TOKEN0_ADDR 'transfer(address,uint256)' --rpc-url $DESTINATION_RPC --private-key $DESTINATION_PRIVATE_KEY $UNISWAP_V2_PAIR_ADDR 10000000000000000000
```

```bash
cast send $TOKEN1_ADDR 'transfer(address,uint256)' --rpc-url $DESTINATION_RPC --private-key $DESTINATION_PRIVATE_KEY $UNISWAP_V2_PAIR_ADDR 10000000000000000000
```

然后 mint LP token 到你的钱包：

```bash
cast send $UNISWAP_V2_PAIR_ADDR 'mint(address)' --rpc-url $DESTINATION_RPC --private-key $DESTINATION_PRIVATE_KEY $CLIENT_WALLET
```

---

## 第 5 步：部署 Reactive 合约

Reactive 合约部署到 Reactive Network，构造参数如下：

- `UNISWAP_V2_PAIR_ADDR`：第 2 步创建得到的 pair 地址
- `CALLBACK_ADDR`：第 3 步部署得到的 callback 合约地址
- `CLIENT_WALLET`：发起止损的用户地址
- `DIRECTION_BOOLEAN`：
  - `true` 表示卖出 `token0`、买入 `token1`
  - `false` 表示卖出 `token1`、买入 `token0`
- `EXCHANGE_RATE_DENOMINATOR` 与 `EXCHANGE_RATE_NUMERATOR`：
  用整数表达阈值价格

例如，如果阈值价格是 `1.234`，可以设置：

- `EXCHANGE_RATE_DENOMINATOR=1000`
- `EXCHANGE_RATE_NUMERATOR=1234`

部署命令：

```bash
forge create --broadcast --rpc-url $REACTIVE_RPC --private-key $REACTIVE_PRIVATE_KEY src/demos/uniswap-v2-stop-order/UniswapDemoStopOrderReactive.sol:UniswapDemoStopOrderReactive --value 0.1ether --constructor-args $UNISWAP_V2_PAIR_ADDR $CALLBACK_ADDR $CLIENT_WALLET $DIRECTION_BOOLEAN $EXCHANGE_RATE_DENOMINATOR $EXCHANGE_RATE_NUMERATOR
```

---

## 第 6 步：授权 callback 合约使用 token

给 callback 合约授权，让它可以在止损触发时转走你的卖出 token。

下面的例子表示授权 `1` 个 18 位精度 token：

```bash
cast send $TOKEN_ADDR 'approve(address,uint256)' --rpc-url $DESTINATION_RPC --private-key $DESTINATION_PRIVATE_KEY $CALLBACK_ADDR 1000000000000000000
```

---

## 第 7 步：手动制造价格变化，触发止损

为了触发 Reactive Contract，你需要让 pair 的储备发生明显变化。

这里的做法是：

1. 先把 token 直接转进 pair
2. 再直接调用 pair 的 `swap(...)`

先转 token：

```bash
cast send $TOKEN_ADDR 'transfer(address,uint256)' --rpc-url $DESTINATION_RPC --private-key $DESTINATION_PRIVATE_KEY $UNISWAP_V2_PAIR_ADDR 20000000000000000
```

再执行 swap：

```bash
cast send $UNISWAP_V2_PAIR_ADDR 'swap(uint,uint,address,bytes calldata)' --rpc-url $DESTINATION_RPC --private-key $DESTINATION_PRIVATE_KEY 0 5000000000000000 $CLIENT_WALLET "0x"
```

成功后，你应该可以在 Sepolia 浏览器上看到：

- pair 的 `Sync` 事件
- Reactive Network 侧的 callback 请求
- callback 合约最终发出的 `Stop` 事件

---

## 作业实践中的额外注意事项

在实际跑这个 Demo 时，有一个很关键但 README 原本没有强调清楚的问题：

### Callback Proxy Reserve

即使 callback 合约部署时携带了 ETH，Sepolia callback proxy 也未必会自动把这部分 ETH 当作可派发 reserve。

如果你遇到下面这种情况：

- Reactive 合约已经发出了 `Callback`
- 但 Sepolia callback 合约一直没有发出 `Stop`

就要检查 callback proxy 中该目标合约的 reserve 是否为 `0`。

如果 reserve 为 `0`，需要额外执行：

```bash
cast send $DESTINATION_CALLBACK_PROXY_ADDR 'depositTo(address)' $CALLBACK_ADDR --value 0.01ether --rpc-url $DESTINATION_RPC --private-key $DESTINATION_PRIVATE_KEY
```

然后再重新部署一个新的 Reactive Contract，并重新触发一次 `Sync`，这样通常就可以成功跑通整个闭环。
