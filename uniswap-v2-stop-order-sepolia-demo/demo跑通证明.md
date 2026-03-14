# Reactive Network 说明

## 一眼看结论

- 选择的 Demo：`Uniswap V2 Stop Order Demo`
- 最终结果：**已成功跑通**
- 成功证明：
  - Sepolia 上 `Sync` 事件已触发
  - Reactive 合约已发出 `Callback`
  - Sepolia callback 合约已成功发出 `Stop(...)` 事件

最终成功交易：

- Sepolia callback 执行成功交易：
  `0x59155732aaee11e6a6217c61fa8d024b44087b9fa9c4decb32ddf9b82d9e0dfd`

浏览器链接：

- <https://sepolia.etherscan.io/tx/0x59155732aaee11e6a6217c61fa8d024b44087b9fa9c4decb32ddf9b82d9e0dfd>

---

## 1. 我选择了哪个 Demo

我选择的是：

**Uniswap V2 Stop Order Demo**

这个 Demo 的核心流程是：

`Sepolia 上 Uniswap Pair 的 Sync 事件 -> Reactive Contract 响应 -> Callback Contract 自动执行止损 -> 发出 Stop 事件`

---

## 2. 关键地址

| 项目 | 地址 |
|---|---|
| 我的钱包 / Client Wallet | `0x791DdA64Ce022269244647699C071dea2cf0fa82` |
| Sepolia Callback Contract | `0x503DE856bd8279cd6E31F49c22bEB81b638e2666` |
| Reactive Stop-Order Contract（第一次） | `0x6b1958c79e71bB075B911308AD4e87A2F30a7C97` |
| Reactive Stop-Order Contract（最终成功版本） | `0xbcA33816115F1f36aB4f391Ea46a3CBace0fF8A0` |
| Demo Token 1 | `0xefa1ea3e3a651bC970f17E711Ee26468C2501dBc` |
| Demo Token 2 | `0xAc6586AA3777694d8B10eadf177fF5587207F86D` |
| Uniswap V2 Pair | `0x5Fb620511186Abc45De05e28432eC124280E39D6` |
| Sepolia Callback Proxy | `0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA` |
| Uniswap V2 Factory | `0x7E0987E5b3a30e3f2828572Bb659A548460a3003` |
| Uniswap V2 Router | `0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008` |

---

## 3. 主要部署交易

| 步骤 | 交易哈希 | 状态 |
|---|---|---|
| 部署 callback 合约 | `0x3f86ba247838f106f8812ec7792c7476609207a766ad8d5c2fd30c91fc98e3b4` | Success |
| 部署 token 1 | `0x59f281a73a396ffdc006058cabec68fad535600a50593d9a9c6b18b325fff457` | Success |
| 部署 token 2 | `0x93d1a5e00b3e96927ae07443bfc497b03d5fe081f935ba4aa2346835b31b4a31` | Success |
| 创建 pair | `0x33ec3cdabec8910579488a6fe004f9b629e84332f220a9a4cb817a7bfc72ad05` | Success |
| 注入 token0 流动性 | `0xbb9fa2521df78fb92a8caf598d63600a04b542f54bcb585d10fcd0d1d61e5b62` | Success |
| 注入 token1 流动性 | `0xea360fa33e1e78c7a28214b7f54de610a8145c1ef210b03940fe7e3f3e61bbf7` | Success |
| Mint LP | `0xe0c415438b19d957ec63d2c470b27a39df49154b780e13ed13d1651c7dca7e20` | Success |
| 第一次部署 Reactive Contract | `0x5b5c2b1bad488806096bedee194838ae3f730d8c69b8e1768fb32100d813dd06` | Success |
| 授权 callback 花费 token | `0xbb5d746ecefd24aca03294c659e1d3e014f381384c8d9c0362f9e97182f282c8` | Success |
| 给 Callback Proxy 充值 reserve | `0x8d89169e816a9f18ca88464ac20191585ec6001c6e5f4746622809b638832dc8` | Success |
| 第二次部署 Reactive Contract（最终成功版本） | `0x16c0289fc1d8d48c0615a2b967e91ade4959c28fc38af62322bbdbec411f0d18` | Success |

---

## 4. 我是如何触发它的

我没有直接使用仓库 README 里预置的 demo token，因为当前钱包地址在那两枚预置 token 上余额为 `0`。

所以我采用了完整自建流程：

1. 在 Sepolia 部署两枚 ERC20 demo token
2. 在 Sepolia 创建新的 Uniswap V2 pair
3. 往 pair 中加入两边各 `10` 个 token 的流动性
4. 在 Sepolia 部署 callback 合约
5. 在 Reactive Network 部署 stop-order reactive 合约
6. 在 Sepolia 上对 callback 合约做 `approve`
7. 手动向 pair 转入卖出 token
8. 直接调用 pair 的 `swap(...)`，制造价格变化，触发 `Sync`

最终成功触发使用的是最后一次流程：

- 触发转账交易：
  `0xc0fdf22c79479dc3a9980a80104781947a186eea2f61beedc88e94d507fd3552`
- 触发 swap 交易：
  `0x7ced15420faa662d6b0f81587c3f9d6fc7d1ae6e434e511d9984eb07513e48b4`

---

## 5. 触发成功的证明

### A. Sepolia 上价格变化已经发生

最终成功使用的 pair swap 交易：

- <https://sepolia.etherscan.io/tx/0x7ced15420faa662d6b0f81587c3f9d6fc7d1ae6e434e511d9984eb07513e48b4>

这笔交易会在 pair 上产生 `Sync` 事件。

---

### B. Reactive Contract 已经响应

最终成功流程对应的 Reactive VM 内部交易包括：

- `0x0b63692637bee3264c2c2af814f08b60888d7dd9c9d47b67ac7a75eff0ef2b4f`

这说明新的 Reactive Contract 已经消费了最后一次 `Sync` 事件并发起 callback 请求。

---

### C. Sepolia Callback 合约已成功执行

最终 callback 成功交易：

- `0x59155732aaee11e6a6217c61fa8d024b44087b9fa9c4decb32ddf9b82d9e0dfd`

浏览器链接：

- <https://sepolia.etherscan.io/tx/0x59155732aaee11e6a6217c61fa8d024b44087b9fa9c4decb32ddf9b82d9e0dfd>

这笔交易的关键点：

- `to = 0xc9f36411...`，说明交易先进入了 Sepolia callback proxy
- 交易日志中可以看到 callback 合约地址
  `0x503DE856bd8279cd6E31F49c22bEB81b638e2666`
  发出了 `Stop(address,address,address,uint256[])`
- 这就是本次作业最关键的“自动执行成功证明”

`Stop` 事件日志信息：

- Pair：
  `0x5Fb620511186Abc45De05e28432eC124280E39D6`
- Client：
  `0x791DdA64Ce022269244647699C071dea2cf0fa82`
- 卖出 Token：
  `0xAc6586AA3777694d8B10eadf177fF5587207F86D`

---

## 6. 中间遇到的问题与修复

这次最大的坑不是合约编译或部署，而是 **callback proxy reserve**。

### 问题现象

最开始我已经做到：

- pair `Sync` 已发生
- Reactive Contract 已发出 `Callback`

但是 Sepolia callback 合约一直没有 `Stop` 日志。

### 根因

继续排查后发现：

- callback proxy 对应的 `reserves(CALLBACK_ADDR)` 一开始是 `0`
- 也就是说，虽然 callback 合约自己部署时带了 `0.02 ETH`
  ，但 **callback proxy 并没有为这个目标合约持有可用于 relayer 派发的 reserve**

### 修复方法

我向 Sepolia callback proxy 额外执行了：

- `depositTo(CALLBACK_ADDR)`，充值 `0.01 ETH`

对应交易：

- `0x8d89169e816a9f18ca88464ac20191585ec6001c6e5f4746622809b638832dc8`

充值后：

- `reserves(CALLBACK_ADDR)` 变为正数
- 再重新部署一个新的 Reactive Contract
- 再触发一次 `Sync`
- 最终 callback 成功执行并发出 `Stop`

说明问题确实出在 proxy reserve，而不是 stop-order 核心逻辑本身。

---

## 7. 可直接提交的轻量版说明

我选择的是 **Uniswap V2 Stop Order Demo**。我在 Sepolia 上部署了 callback 合约、两枚 ERC20 demo token，并创建了新的 Uniswap V2 pair，然后加入流动性；随后在 Reactive Network 上部署了 stop-order reactive 合约，并在 Sepolia 上完成 token 授权。最后，我通过向 pair 转入 token 并直接调用 `swap(...)` 人为制造价格变化，触发 `Sync` 事件。

在排查过程中我发现，callback proxy 对目标 callback 合约没有 reserve，导致最初虽然 Reactive 侧已经发出 callback，但 Sepolia 侧没有真正执行。给 callback proxy 充值 reserve 后，我重新部署了一个新的 Reactive Contract 并再次触发价格变化，最终在 Sepolia 上成功观察到了 callback 合约发出的 `Stop(...)` 事件。

最终成功证明：

- 成功 swap 触发交易：
  `0x7ced15420faa662d6b0f81587c3f9d6fc7d1ae6e434e511d9984eb07513e48b4`
- 成功 callback 执行交易：
  `0x59155732aaee11e6a6217c61fa8d024b44087b9fa9c4decb32ddf9b82d9e0dfd`

---

## 8. 相关链接

- Callback 合约：
  <https://sepolia.etherscan.io/address/0x503DE856bd8279cd6E31F49c22bEB81b638e2666>
- Pair 合约：
  <https://sepolia.etherscan.io/address/0x5Fb620511186Abc45De05e28432eC124280E39D6>
- Token 1：
  <https://sepolia.etherscan.io/address/0xefa1ea3e3a651bC970f17E711Ee26468C2501dBc>
- Token 2：
  <https://sepolia.etherscan.io/address/0xAc6586AA3777694d8B10eadf177fF5587207F86D>
- 成功 callback 交易：
  <https://sepolia.etherscan.io/tx/0x59155732aaee11e6a6217c61fa8d024b44087b9fa9c4decb32ddf9b82d9e0dfd>
