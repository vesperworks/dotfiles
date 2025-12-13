# Lua/NeoVim プロジェクト

## 品質コマンド

```bash
# Format
stylua --check .  # 確認のみ
stylua .          # 自動修正

# Lint
luacheck .
selene .  # より厳格なLint
```

## テスト

```bash
# plenary.nvim（NeoVim内）
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# vusted（CLI）
vusted tests/
```

## NeoVim プラグイン構成

```
plugin/
├── lua/
│   └── plugin_name/
│       ├── init.lua
│       └── config.lua
├── plugin/
│   └── plugin_name.lua
├── tests/
│   ├── minimal_init.lua
│   └── plugin_name_spec.lua
├── stylua.toml
└── .luacheckrc
```

## プラグインマネージャ

- lazy.nvim（推奨）
- packer.nvim

## 設定ファイル

### stylua.toml
```toml
column_width = 120
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
```

### .luacheckrc
```lua
std = "luajit+nvim"
ignore = { "212" }  -- unused argument
globals = { "vim" }
```
