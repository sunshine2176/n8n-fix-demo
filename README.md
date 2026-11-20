# n8n Webhook Fix Demo — "坏 → 修" 全过程

> Upwork 能力证明 demo。复现场景:客户报障 *"webhook workflow fails at the payload transformation step — the Code node JSON mapping is wrong and the downstream API never receives the record"*（对应靶子 T1 的原话症状）。

<!-- TODO: 录屏 gif 放这里 -->

## What it did

一条典型的订单同步链路:

```
Webhook (POST /order-sync)
   └─> Code node "Transform Payload"   ← 两个 bug 埋在这里
         └─> HTTP Request → CRM API (webhook.site 作为下游接收端)
```

上游系统真实发来的 payload:

```json
{
  "orderId": "SO-10241",
  "customer": { "id": "C-772", "name": "Acme Corp" },
  "items": [
    { "sku": "WID-100", "qty": 2 },
    { "sku": "BRK-40",  "qty": 1 }
  ],
  "total": "49.90"
}
```

下游 CRM 期望收到: `customerId`(string)· `itemCount`(number)· `total`(string,两位小数)。

## Symptom(第一幕)

点击执行 → workflow 红色失败:

```
TypeError: payload.total.toFixed is not a function
```

测试请求:

```bash
curl -X POST http://localhost:5678/webhook-test/order-sync \
  -H "Content-Type: application/json" \
  -d @payload.json
```

## Root cause(第二幕,两个 bug)

打开 `Transform Payload` Code 节点:

| # | 错误类型 | 坏代码 | 问题 |
|---|---|---|---|
| 1 | **string vs number** | `payload.total.toFixed(2)` | 上游发的是字符串 `"49.90"`,代码当数字用 → 直接 TypeError |
| 2 | **引用不存在的字段** | `payload.customer_id` | 真实字段在 `payload.customer.id`,这行读到 `undefined` → 下游收到 `customerId: null`,**静默丢数据**(比报错更危险) |

## Fix(第三幕,改两行)

```js
const total = Number(payload.total).toFixed(2);   // 显式转型
const customerId = payload.customer.id;            // 按真实结构映射
```

再跑同一请求 → 绿色成功,webhook.site 收到:

```json
{
  "customerId": "C-772",
  "itemCount": 2,
  "total": "49.90",
  "status": "processed"
}
```

## How to reproduce

```bash
docker run -d --name n8n-demo -p 5678:5678 n8nio/n8n
# 打开 http://localhost:5678 → Import from File → workflow-broken.json
# 在 webhook.site 建一个 endpoint,替换 Send to CRM 节点里的 URL
```

## Files

- `workflow-broken.json` — 带两个 bug 的原始 workflow(可直接导入 n8n)
- `workflow-fixed.json` — 修复后的最终版
- `payload.json` — 测试请求体

---

Built by David Sun. Two intentional bugs, one real fix, sixty seconds.
