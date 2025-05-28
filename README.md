# IWASHI Terraform Infrastructure

このリポジトリは、Google Cloud Platform (GCP) 上のインフラストラクチャを Terraform によってコード管理するための構成です。環境ごと（`dev` / `prod`）にモジュールを組み合わせ、再利用性と保守性を高めています。

---

## ディレクトリ構成

```
.
├── command.md                  # Terraform コマンドまとめ
├── envs                        # 環境ごとの構成（dev / prod）
│   ├── dev/
│   └── prod/
│       ├── backend.tf          # GCS バケットによる state 管理
│       ├── main.tf             # モジュールの呼び出し
│       ├── openapi.yaml        # API Gateway 用 OpenAPI 定義
│       ├── terraform.tfvars    # 環境固有の変数
│       └── variables.tf        # 変数定義
├── infra.md                    # インフラ設計の詳細説明
├── key.md                      # 認証情報の使用方法（Git 管理対象外）
├── modules                     # 共通モジュール群
│   ├── api_gateway/
│   ├── artifact_registry/
│   ├── cloud_run/
│   ├── iam/
│   ├── network/
│   └── pubsub/
└── README.md
```

---

## 管理対象リソース

- **API Gateway**: OpenAPI 定義に基づいた API ゲートウェイの構築
- **Artifact Registry**: コンテナイメージ等の保存リポジトリ
- **Cloud Run**: サーバーレスアプリケーションのデプロイ
- **IAM**: サービスアカウントとロールの設定
- **Network**: VPC、サブネットの定義
- **Pub/Sub**: メッセージキューシステムの構築

---

## 初期セットアップ

```bash
# 認証情報の設定
export GOOGLE_APPLICATION_CREDENTIALS=~/your-gcp-key.json
```

---

## 基本コマンド

```bash
terraform init        # 初期化
terraform plan        # 差分確認
terraform apply       # 適用
```

---

## 本番環境での適用手順

```bash
cd envs/prod
terraform init
terraform apply -var-file=terraform.tfvars
```

---

## 補足情報

- `infra.md`: 全体アーキテクチャや構成の背景
- `command.md`: よく使う Terraform コマンド集
- `key.md`: 認証情報ファイル（\*.json）の配置と注意点（`.gitignore` 対象）

---

## 注意点

- ステートファイルは `backend.tf` で指定した GCS バケット上に保存されます。
- `openapi.yaml` の変更は API Gateway の挙動に影響するため、慎重に編集してください。
