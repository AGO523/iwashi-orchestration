# アプリケーションの構成

## クライアントアプリ

ユーザーが購読するニュースを登録するアプリケーション

- repository: news-app-react-router
  - React Router v7(Remix)
  - Cloudflare Workers: news-app-react-router
  - Cloudflare D1: news-app-react-router

## API Gateway

API Gateway を使用して、クライアントアプリケーションからのリクエストを中継する
key.md に API Gateway の認証情報を記載(gitignore)
/publish に POST することで、Pub/Sub にニュースを publish する

<!-- ## 中継アプリケーション

クライアントからのリクエストを受け取り、ニュースを取得して Pub/Sub に publish するアプリケーション

- repository: node-via-google-publisher
  - Node.js
  - Cloudrun
    - デプロイは git リポジトリ連携
      - https://cloud.google.com/run/docs/quickstarts/deploy-continuously?hl=ja#cloudrun_deploy_continuous_code-nodejs -->

## Pub/Sub (Terraform)

ニュースを受け取り、トピックに保管する
API Gateway を使用して認証

- name: client-message-topic

## サーバーアプリケーション

Pub/Sub からニュースを取得して、Gemini API を使用してニュースの要約を取得、通知を行うアプリケーション

- repository: node-news-notification
  - Node.js
  - Cloudrun(terraform)
