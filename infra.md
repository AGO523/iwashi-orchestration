## 使用技術

- フロントエンド: React Router v7 (Remix, TypeScript)
- バックエンド:

  - Node.js（Cloud Run）
  - Hono（Cloudflare Workers）

- データベース: Cloudflare D1 (SQLite ベース)
- インフラ:

  - GCP API Gateway（認証とルーティング）
  - Cloud Run（要約処理）
  - Cloudflare Workers（送信処理・購読処理）

- 外部 API: Google Gemini API（要約生成）
- 認証:

  - API Key（API Gateway）
  - IAM（Cloud Run）

## システム全体図

```
Client App (React Router)
  URL: https://github.com/AGO523/news-app-react-router
  機能: ユーザーからのニュース配信要求（POST /publish）を送信
  認証: API KEY による認証
      ↓
API Gateway (GCP)
  URL: https://github.com/AGO523/iwashi-orchestration
  機能: 認証（IAM）およびルーティング
      ↓
Cloud Run (Node.js アプリ)
  URL: https://github.com/AGO523/node-news-notification
  機能:
    - Gemini API を使って要約を生成
    - Cloudflare D1 に結果を保存（hono-messaging-worker-db）
      ↓
Cloudflare Workers (Hono)
  URL: https://github.com/AGO523/hono-messaging-worker
  機能:
    - 保存された要約をメール送信
    - Cloudflare D1 に送信処理結果を記録

定期購読の処理:
  Cloudflare Workers (Hono)
    URL: https://github.com/AGO523/news-feed-subscriber
    機能:
      - Cloudflare D1（news-app-react-router の DB）から定期購読データを取得
          ↓
    API Gateway (GCP)
      ↓ IAM認証
    Cloud Run
      ↓ Gemini 要約 + 保存 + メール送信処理（上記と同様）
```

## 各コンポーネントの詳細

### 1. Client App (React Router v7)

- リポジトリ: [news-app-react-router](https://github.com/AGO523/news-app-react-router)
- 使用言語: TypeScript
- 機能:

  - フォーム経由で `/publish` エンドポイントにニュース配信要求を送信
  - 認証付きリクエストを送信

### 2. API Gateway (GCP)

- リポジトリ: [iwashi-orchestration](https://github.com/AGO523/iwashi-orchestration)
- Terraform を使用して GCP 上に構築
- 機能:
  - クライアントからのリクエストに対して API KEY によるアクセス制御
  - Cloud Run へのルーティング
  - IAM による認証実施

### 3. Cloud Run (node-news-notification)

- リポジトリ: [node-news-notification](https://github.com/AGO523/node-news-notification)
- 使用言語: Node.js
- 機能:

  - Gemini API によるニュース要約
  - 要約結果を Cloudflare D1 に保存

### 4. Cloudflare Workers (hono-messaging-worker)

- リポジトリ: [hono-messaging-worker](https://github.com/AGO523/hono-messaging-worker)
- 使用言語: TypeScript（Hono フレームワーク）
- 機能:

  - Cloudflare D1 に保存された要約を取得し、メール送信
  - 処理結果を D1 に記録

### 5. Cloudflare Workers (news-feed-subscriber)

- リポジトリ: [news-feed-subscriber](https://github.com/AGO523/news-feed-subscriber)
- 使用言語: TypeScript（Hono フレームワーク）
- 機能:

  - Cloudflare D1 から定期購読のデータを取得
  - 配信タイミングに応じて GCP API Gateway 経由で配信処理をトリガー

## データベース

- Cloudflare D1

  - ユーザーの購読情報、要約データ、送信結果などを格納

## 認証・セキュリティ

- API Gateway: key によるアクセス制御
- Cloud Run: IAM によるアクセス制御
