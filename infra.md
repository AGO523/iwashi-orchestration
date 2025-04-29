## システム全体図

```
Client App (インターネット)
  ↓ POST /publish (x-api-key認証)
API Gateway (GCP)
  ↓
Pub/Sub Topic (client-message-topic)
  ↓
Cloud Run Job (pubsub-pull-job)【定期実行】
  ↓
内部VPC経由で処理
```

---

# 【各コンポーネントの役割】

| コンポーネント                                | 説明                                                                                   |
| :-------------------------------------------- | :------------------------------------------------------------------------------------- |
| Client App                                    | インターネット側のクライアント。API Gateway にリクエストを送る。                       |
| API Gateway                                   | GCP 上の API エンドポイント。認証（API キー）を通し、リクエストを Pub/Sub に中継する。 |
| Pub/Sub Topic (`client-message-topic`)        | メッセージキュー。API Gateway から受けたデータをためる。                               |
| Cloud Run Job (`pubsub-pull-job`)             | Pub/Sub から Pull してメッセージを処理するバッチジョブ。                               |
| VPC Network (`private-vpc`)                   | Cloud Run Job がプライベート通信するための VPC ネットワーク。                          |
| VPC Access Connector (`serverless-connector`) | サーバーレス（Cloud Run Job）から VPC に入るための中継。                               |
| Cloud Scheduler (`cloud-run-job-trigger`)     | Cloud Run Job を定期実行するスケジューラ（毎日実行）。                                 |

---

# 【フロー詳細】

1. **クライアントアプリ**が API Gateway のエンドポイントに`POST /publish`リクエストを送る。
   - リクエストには必ず**API キー（x-api-key ヘッダー）**を付与。
2. **API Gateway**がリクエストを受け取る。
   - API キー認証を通過した場合だけ、リクエスト内容を**Pub/Sub Topic**に**Publish**する。
3. **Pub/Sub Topic**にメッセージが溜まる。
4. **Cloud Scheduler**が、毎日定期的に**Cloud Run Job**を起動する。
5. **Cloud Run Job**は起動後、**Pub/Sub から Pull**してメッセージを取得。
6. **取得したメッセージを VPC 内部で処理**できる（必要に応じて DB アクセスなど）。

---

# 【構成図（ビジュアルイメージ）】

```plaintext
[ Client App ]
    |
    v
[ API Gateway ]
    |
    v
[ Pub/Sub Topic ]
    |
(Cloud Scheduler起動)
    |
    v
[ Cloud Run Job ]
    |
    v
[ VPCネットワーク内リソース ]
```

---

# 【構成の特徴】

- **API Gateway で認証管理**しているため、安全に外部からリクエスト受付
- **Pub/Sub で非同期化**しているため、高負荷耐性がある
- **Cloud Run Job でバッチ処理化**しているため、オンデマンドではなくスケジューラ管理
- **VPC Connector を使用**して、Cloud Run Job がプライベート VPC にだけ通信できる（インターネット不要）
- **すべて Terraform 管理**で再現性、構成管理が可能

---

# 【なぜこの構成なのか？（設計思想）】

- クライアントアプリから直接 Pub/Sub に書き込みさせない（API Gateway を経由）
- IAM ポリシーを絞ってセキュリティを強化
- クラウドネイティブ・マネージドサービス中心にして運用コスト削減
- スケール耐性を持たせる（Pub/Sub と Cloud Run Job でスケール可）

---

# 【まとめ】

| 項目         | 内容                                                                     |
| :----------- | :----------------------------------------------------------------------- |
| セキュリティ | API キー認証、IAM 管理、VPC 内限定通信                                   |
| 可用性       | Pub/Sub でメッセージバッファリング                                       |
| マネージド度 | Cloud Run Job / API Gateway / Pub/Sub / Cloud Scheduler で完全マネージド |
| 将来拡張     | メッセージに応じて処理を追加できる                                       |

---
