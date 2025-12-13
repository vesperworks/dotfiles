# TypeScript/Node.js プロジェクト

## パッケージマネージャ

- `ni` - パッケージインストール（npm/yarn/pnpm/bun 自動検出）
- `nr` - スクリプト実行

## 品質コマンド

```bash
nr check      # Lint + Format 確認
nr check:fix  # Lint + Format + 自動修正
nr test       # テスト実行
nr build      # ビルド実行
```

## package.json scripts 設定例

```json
{
  "scripts": {
    "check": "biome check . || (eslint . && prettier --check .)",
    "check:fix": "biome check --write . || (eslint --fix . && prettier --write .)",
    "test": "vitest run",
    "build": "tsc"
  }
}
```

## ツール優先順位

**Biome > ESLint/Prettier**

Biome検出条件（いずれかを満たせばBiome使用）:
1. `package.json` に `@biomejs/biome` 依存がある
2. プロジェクトルートに `biome.json` が存在する

## テストフレームワーク

- Vitest（推奨）
- Jest
