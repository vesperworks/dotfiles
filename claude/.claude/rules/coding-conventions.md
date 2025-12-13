# コーディング規約

## Bashスクリプト
- `#!/bin/bash` で開始（shebang必須）
- 2スペースインデント
- 関数はスネークケース（`function_name`）
- エラーハンドリング必須（`set -euo pipefail` 推奨）
- shellcheck準拠

## Markdown
- 見出しレベルの一貫性
- コードブロックに言語指定
- リスト形式の統一

## 設計原則
グローバルCLAUDE.mdの原則に従う:
- YAGNI（今必要じゃない機能は作らない）
- DRY（同じコードを繰り返さない）
- KISS（シンプルに保つ）
- SOLID（オブジェクト指向設計の5原則）
