# Python プロジェクト

## パッケージマネージャ

- `uv`（推奨）- 高速なPythonパッケージマネージャ
- `pip` - 標準

## 品質コマンド

```bash
# Lint
uv run ruff check .
uv run ruff check --fix .  # 自動修正

# Format
uv run ruff format .
uv run ruff format --check .  # 確認のみ

# テスト
uv run pytest
uv run pytest --cov=src --cov-fail-under=80  # カバレッジ付き
```

## 型チェック

```bash
uv run mypy .
uv run pyright
```

## プロジェクト構成

```
project/
├── pyproject.toml
├── src/
│   └── package_name/
├── tests/
└── .python-version
```

## ツール設定（pyproject.toml）

```toml
[tool.ruff]
line-length = 88
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]
```
