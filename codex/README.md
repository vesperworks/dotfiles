# codex package

このパッケージは GNU Stow で `~/.codex/` と `~/.agents/skills/` を配るためのもの。

## 目的

- Codex CLI の設定を dotfiles で管理する
- 主要な非破壊コマンドは承認なしで進めやすくする
- 危険操作とリモート影響操作は明示的に止める
- skill は Codex 公式の配置に合わせて `~/.agents/skills/` に置く

## 構成

```text
codex/
├── README.md
├── .codex/
│   ├── AGENTS.md
│   ├── config.toml
│   └── rules/
│       └── default.rules
└── .agents/
    └── skills/
```

## 権限方針

- デフォルトは `workspace-write + on-request`
- `rules/default.rules` で read/search 系を `allow`
- `jj` のローカルな `commit / describe / new` は `allow`
- `git push` と `jj git push` は `forbidden`
- `stow` や履歴書き換え系は `prompt`

## Caveat

- `rules/default.rules` は `codex execpolicy check` では期待どおり判定される
- ただし runtime での enforcement は追加検証が必要で、現時点では過信しない
- 実運用の安全主軸は `AGENTS.md`、`approval_policy`、`sandbox_mode`

## 運用

```bash
stow -t ~ --no-folding codex
```

必要なら高速探索時のみ `fast-explore` profile を使う。

```bash
codex -p fast-explore
```
