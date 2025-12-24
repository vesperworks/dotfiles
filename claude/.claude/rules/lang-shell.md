# Shell Script プロジェクト

## ツールインストール

```bash
# macOS (Homebrew)
brew install shellcheck shfmt bats-core

# npm (bats-coreのみ)
npm install -g bats

# Linux (apt)
sudo apt install shellcheck
go install mvdan.cc/sh/v3/cmd/shfmt@latest
```

## 品質コマンド

```bash
# Lint（静的解析）
shellcheck *.sh
shellcheck scripts/**/*.sh

# Format確認
shfmt -d .

# Format自動修正
shfmt -w .

# Lint + Format 確認
shellcheck *.sh && shfmt -d .

# テスト実行
bats tests/          # bats-core使用時
shellspec            # ShellSpec使用時
```

## 推奨スクリプトヘッダー

```bash
#!/bin/bash
set -euo pipefail
```

| オプション | 効果 |
|------------|------|
| `-e` | エラー時即座に終了 |
| `-u` | 未定義変数をエラー |
| `-o pipefail` | パイプ内のエラーを検出 |

## デバッグ手法

```bash
# 部分デバッグ
set -x
# デバッグしたい部分
set +x

# エラー行を表示
trap 'echo "Error at line $LINENO"' ERR

# 実行前に構文チェック
bash -n script.sh
```

## テストフレームワーク選択

| フレームワーク | 推奨度 | 用途 |
|----------------|--------|------|
| bats-core | 70% | Bash専用、シンプル、最も人気 |
| ShellSpec | 25% | POSIX対応、モック・カバレッジ組み込み |
| shUnit2 | 5% | レガシー、新規プロジェクト非推奨 |

### bats-core テスト例

```bash
#!/usr/bin/env bats

@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "function returns success" {
  run my_function "arg"
  [ "$status" -eq 0 ]
  [ "$output" = "expected" ]
}
```

### ShellSpec テスト例

```bash
Describe 'my_function'
  It 'returns success'
    When call my_function "arg"
    The status should be success
    The output should equal "expected"
  End
End
```

## CI/CD設定例

### GitHub Actions

```yaml
name: Shell CI
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: ShellCheck
        uses: ludeeus/action-shellcheck@master
      - name: shfmt
        run: |
          go install mvdan.cc/sh/v3/cmd/shfmt@latest
          shfmt -d .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install bats
        run: npm install -g bats
      - name: Run tests
        run: bats tests/
```

### pre-commit設定

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/koalaman/shellcheck-precommit
    rev: v0.10.0
    hooks:
      - id: shellcheck
  - repo: https://github.com/scop/pre-commit-shfmt
    rev: v3.8.0
    hooks:
      - id: shfmt
```

## shfmt設定

```bash
# .editorconfig または shfmt オプション
shfmt -i 2 -ci -bn  # 2スペースインデント、case indent、バイナリ演算子改行
```

| オプション | 説明 |
|------------|------|
| `-i N` | インデント幅（0=タブ） |
| `-ci` | switch case インデント |
| `-bn` | バイナリ演算子後で改行 |
| `-sr` | リダイレクト後にスペース |

## コーディング規約

- 関数名・変数名: `snake_case`
- 環境変数: `UPPER_SNAKE_CASE`
- 変数展開: 常にダブルクォート `"$var"`
- 条件式: `[[ ]]` を `[ ]` より優先（bash）
- スクリプトサイズ: 50行以下推奨（Google Style Guide）
