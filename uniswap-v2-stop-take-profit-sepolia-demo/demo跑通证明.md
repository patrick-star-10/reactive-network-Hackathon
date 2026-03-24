# Demo 3 跑通证明

## Demo 名称

`Uniswap V2 Stop-Loss & Take-Profit Orders`

## 可直接提交格式

```text
Demo 3: Uniswap V2 Stop-Loss & Take-Profit Orders / 0x565ec6b790ded5b615c37a7b2602503bcf72f1accc6d0c192f986000ed526cc2 / 0xc70996d9d085c3466fe497aacf0a52f548616b946bffec6d754e2f1e4bebc155 / 0xe15496acc49fa1d1ebd2514dd433f76342d2906c9e19fc418de2df1f683e22fa
```

## 部署地址

- Token 1: `0xC2E1d170D11D7F4Bb5D9e7577c647446568e0162`
- Token 2: `0xeC1abcdF4825e122c89c56AF7b0A672B636a1133`
- Origin pair: `0x437192927863E11456634f4212845fD60ef17E16`
- Destination callback: `0x397aebEcB95454A6482e6136641b886eF293F8c3`
- Reactive contract: `0xea795B0cb4e4068f44304A27B8a455EF66B223DF`

## 关键交易

- Token 1 部署: `0x9538cf1464d88d0109b388af6c556057785597eb34e2c2bcf66a40d17c43a564`
- Token 2 部署: `0x207da88ccf7336d3edd57f0a572512888cf13c9efd4294d7d5c1fe4bd451e42b`
- Pair 创建: `0x241a014fafa8f5d5a6c072e2d73cf8120b52acfe1df9af4d7a1766be01c57811`
- LP mint: `0xf2e4429396c0d638b6ba25a058f4963094aad77f7d61188e2c2d08789c680da8`
- Callback 部署: `0x717b5133896751262729e96e1990d7f1d20cf1e3ae03c60eddea51057c469800`
- Callback proxy reserve 充值: `0xb0b3f6fc633c47b81525333c784a25e1d8d4526c18d30fac43fc4f4dd05f771e`
- Reactive 部署: `0x68b275e9428e867b0202aa4fdbd180d183203c737a2f417cc0a5960ab3d8604a`
- Token approve: `0x2627e9dbd53a331b2cdffb64c9aa1839791d8ffd15c2e119677b53f13efbbdd9`
- Stop order 创建: `0x8a9081af026b4439189e06074d7102ad86f5db8e3cb64ce4b12d3502a9343687`
- 触发前转账: `0x64e8567d1d3a1074798035c805f092dc0125468785a34bc2b5dd5b4faeb2914e`

## Workflow 证明

- Origin tx:
  `0x565ec6b790ded5b615c37a7b2602503bcf72f1accc6d0c192f986000ed526cc2`
  这笔 Sepolia pair `swap(...)` 交易发出了 `Sync` 事件，是本次 workflow 的 origin transaction。

- Reactive tx:
  `0xc70996d9d085c3466fe497aacf0a52f548616b946bffec6d754e2f1e4bebc155`
  这笔 Lasna RVM 交易通过 `refTx = 0x565ec6b790ded5b615c37a7b2602503bcf72f1accc6d0c192f986000ed526cc2` 匹配得到，是本次 workflow 的 reactive transaction。

- Destination tx:
  `0xe15496acc49fa1d1ebd2514dd433f76342d2906c9e19fc418de2df1f683e22fa`
  这笔 Sepolia 交易在 callback 合约上发出了 `StopOrderExecuted(...)` 事件，是本次 workflow 的 destination transaction。
