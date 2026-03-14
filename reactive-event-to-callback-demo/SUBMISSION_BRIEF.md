# Reactive Homework Submission

## 部署地址
- OriginEventSource: `0x57A372A1C2cfCEf2C5be589c95f4aF1Ccd5412Ae`
- ValueSetListenerReactive: `0xbC2592E0686b6900AD382CA6Ae9A01Dc3b412498`
- DestinationCallbackReceiver: `0x32Bf10b95fE7bd489b3255E7839153E281d40Ee9`

## 交易哈希
- OriginEventSource 部署交易: `0xb72b24f97d0364e7002b37f29e76604e54fe7311f69227be69ba62568facec08`
- ValueSetListenerReactive 部署交易: `0xffdb679427fdd1d5458311aaa2b97056ad36bfef628ac65566d6c04921841a7d`
- DestinationCallbackReceiver 部署交易: `0xbb26252ac43f3fb35de2aa3cdb9da1794d8bdedb0076f802fd7249843593a893`
- 目标链充值交易: `0x2bf4b49968c90ed3c6861cc0881425a7e800a3976be15fb0de1f00d040a25555`
- 源链触发 `setValue(uint256)` 交易: `0x76ae56b3a913a8ebfc3282c9e6bc17420079b9769aedfa148cd4e455406c6491`

## 触发成功证明
- 源链 `ValueSet` 事件浏览器链接: `https://sepolia.basescan.org/tx/0x76ae56b3a913a8ebfc3282c9e6bc17420079b9769aedfa148cd4e455406c6491`
- 目标链 `CallbackReceived` 事件浏览器链接: `https://sepolia.etherscan.io/tx/0x454f7b323c3855b411896968b044ac8287506d53179d5ea9f7be2fba5ee1f77e`
- 目标链 `mirroredValue()` 查询结果: `44`
- 日志摘要:
  - `lastOriginalSender = 0x791DdA64Ce022269244647699C071dea2cf0fa82`
  - `lastOriginChainId = 84532`
  - `lastOriginContract = 0x57A372A1C2cfCEf2C5be589c95f4aF1Ccd5412Ae`
  - `lastOriginTimestamp = 1773111520`

## 补充信息
- Origin chain: `Base Sepolia (84532)`
- Reactive chain: `Reactive Lasna (5318007)`
- Destination chain: `Ethereum Sepolia (11155111)`
- System contract: `0x0000000000000000000000000000000000fffFfF`
- Callback proxy: `0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA`
- Authorized RVM ID: `0x791DdA64Ce022269244647699C071dea2cf0fa82`
- 同步的 value: `44`
