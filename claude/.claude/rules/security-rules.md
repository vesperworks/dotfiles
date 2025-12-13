# セキュリティルール

## 禁止事項
- eval()使用禁止
- パスワードハードコーディング禁止
- Path Traversal禁止
- Command Injection禁止
- XSS (Cross-Site Scripting)禁止

## 必須事項
- ユーザー入力: サニタイズ・バリデーション
- SQLインジェクション対策: パラメータ化クエリ
- 機密情報: 環境変数で管理、ログ出力禁止
