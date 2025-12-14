---
date: 2025-12-14T15:30:00+09:00
researcher: Claude Code
topic: "nvimアニメーションプラグインとAlacrittyのアニメーション機能"
tags: [research, nvim, alacritty, animation, ui]
status: complete
iteration: 1
---

# Research: nvim/Alacrittyアニメーション機能

**調査日時**: 2025-12-14 15:30
**依頼内容**: nvimで派手なアニメーションするプラグインとAlacrittyのアニメーション機能について

## サマリー

**Neovim**には多数のアニメーションプラグインが存在し、カーソルアニメーション・スクロール・Matrix風エフェクトなど豊富。
**Alacritty**本体にはアニメーション機能がなく、フォークの「alacritty-smooth-cursor」でカーソルアニメーションのみ対応。

## 詳細な調査結果

### 1. Neovimアニメーションプラグイン

#### 実用的なアニメーション

| プラグイン | 説明 | 特徴 |
|-----------|------|------|
| [smear-cursor.nvim](https://github.com/sphamba/smear-cursor.nvim) | 🌠 Neovide風スミアカーソル | **最もおすすめ**。Alacrittyでも動作 |
| [mini.animate](https://github.com/nvim-mini/mini.animate) | スクロール・カーソル・ウィンドウアニメーション | mini.nvimの一部、安定性◎ |
| [tiny-glimmer.nvim](https://github.com/rachartier/tiny-glimmer.nvim) | yank/paste/undo時の光るエフェクト | Beta版、操作フィードバック向上 |
| [SmoothCursor.nvim](https://github.com/gen740/SmoothCursor.nvim) | signcolumnにサブカーソル表示 | スクロール方向の可視化 |

#### エンタメ系アニメーション（派手なやつ）

| プラグイン | 説明 | 特徴 |
|-----------|------|------|
| [cellular-automaton.nvim](https://github.com/Eandrju/cellular-automaton.nvim) | 🎮 Matrix rain / Game of Life | **超派手**。バッファ内容が崩れ落ちる |
| [screen_saviour.nvim](https://github.com/fazibear/screen_saviour.nvim) | スクリーンセーバー風エフェクト | cellular-automatonベース |

#### 設定例: cellular-automaton.nvim

```lua
-- lazy.nvim
{
  "eandrju/cellular-automaton.nvim",
  keys = {
    { "<leader>fml", "<cmd>CellularAutomaton make_it_rain<CR>", desc = "Make it rain!" },
    { "<leader>gol", "<cmd>CellularAutomaton game_of_life<CR>", desc = "Game of Life" },
  },
}
```

#### 設定例: smear-cursor.nvim

```lua
-- lazy.nvim
{
  "sphamba/smear-cursor.nvim",
  opts = {
    stiffness = 0.8,      -- 硬さ (高いほど反応が速い)
    trailing_stiffness = 0.5,
    damping = 0.75,       -- 減衰 (低いほどオーバーシュート)
  },
}
```

### 2. Alacrittyのアニメーション機能

#### 公式Alacritty

**結論: アニメーション機能は存在しない**

- カーソルブリンク（点滅）のみ対応
- Visual Bell（画面フラッシュ）のみ対応
- スムースカーソル移動は**なし**

#### フォーク: alacritty-smooth-cursor

[alacritty-smooth-cursor](https://github.com/GregTheMadMonk/alacritty-smooth-cursor) というフォークがあり、カーソルアニメーションを追加。

```toml
# alacritty.toml（フォーク版専用）
[cursor]
smooth_motion = true
smooth_motion_factor = 0.2    # 0.0=静止, 1.0=即座
smooth_motion_spring = 0.5
smooth_motion_max_stretch_x = 3.0
smooth_motion_max_stretch_y = 3.0
```

**注意点**:
- 公式Alacrittyではなくフォーク版のインストールが必要
- AUR: `alacritty-smooth-cursor-git`
- Waylandで問題あり（XWayland推奨）
- アイドル時もGPU使用率が若干上がる

### 3. 代替案: ターミナル側のアニメーション

Alacritty以外でアニメーション対応のターミナル：

| ターミナル | アニメーション機能 |
|-----------|-------------------|
| **Kitty** | 一部対応（GPUベース） |
| **Wezterm** | スムースカーソル、アニメーション背景 |
| **Neovide** | 最強のアニメーション（Neovim専用GUI） |

## 結論

1. **派手なアニメーションが欲しい** → `cellular-automaton.nvim`（Neovim側で対応）
2. **実用的なカーソルアニメーション** → `smear-cursor.nvim`（Alacrittyでも動作）
3. **Alacritty自体のアニメーション** → フォーク版のみ対応、公式は未対応

**おすすめ**: Alacrittyはそのままで、Neovim側で`smear-cursor.nvim`と`cellular-automaton.nvim`を導入するのが最もシンプル。

## 追加の検討事項

- Alacrittyの軽量性を維持したいなら、Neovim側のプラグインで対応がベスト
- フォーク版Alacrittyはメンテナンス状況に注意
- Neovide（Neovim専用GUI）は最強だがAlacrittyとは別物

## 次のステップの提案

1. `smear-cursor.nvim`を試す（lazy.nvimで簡単導入）
2. `cellular-automaton.nvim`を入れて`:CellularAutomaton make_it_rain`で遊ぶ
3. 気に入ったら常用設定に追加
