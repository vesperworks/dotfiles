# Scoring Rubric

## 採点式（確定）

```
スコア = 100
  − (Critical × 12)
  − (Serious  × 8)
  − (Moderate × 4)
  − (Tip      × 1)
```

- 下限はクリップしない（負値も許容、深刻度の可視化を優先）
- 信頼度 🟡 Medium のときは Serious / Moderate / Tip に **×0.5 修正**（Critical は満額）
- 信頼度 🔴 Low のときは採点しない（観察のみ報告）

## 4 段階の定義

| 段階 | 重み | 定義 | 例 |
|------|------|------|------|
| **Critical** | −12 | HIG 必須違反 / WCAG AA 違反 / アクセシビリティ破綻 / セキュリティ問題 | コントラスト 4.5:1 未満、`outline: none` 単独、touch target 44pt 未満、ダークモード完全未対応、和文フォント完全欠落 |
| **Serious**  | −8 | HIG 強推奨違反 / 規範からの大きな逸脱 / 修正コスト中程度の品質問題 | semantic token 未定義（ハードコード hex 多用）、本文 `line-height < 1.5`（和文）、入力 type 不一致、safe area 未対応、disabled 視覚差なし |
| **Moderate** | −4 | HIG 推奨違反 / スケール逸脱 / 改善余地大 | 8pt grid 逸脱、corner radius 階層崩れ、`palt` 未指定、`text-autospace` 未指定、`tabindex > 0` |
| **Tip**      | −1 | 洗練度・好みの問題 / SF Symbols 揃え / kiso.css の細部 | 純黒 `#000` 背景、`text-wrap: pretty` 未使用、`color-scheme` 未指定、本文 1.65〜1.85 の幅内での好み |

## 20 カテゴリ × 重み付け早見表

| # | カテゴリ | 詳細 | 主な検出ターゲット |
|---|---------|------|--------------------|
| 1 | Typography | `hig-foundations.md` §1 | font-size スケール、Dynamic Type、SF Pro |
| 2 | Color & Contrast | §2 | semantic token、WCAG AA、palette |
| 3 | Spacing & Layout | §3 | 8pt grid、margin/padding、safe area |
| 4 | Touch Target | §3.2 | 44pt 最低、ヒット領域 |
| 5 | Corner Radius | §4 | radius スケール、内外整合 |
| 6 | Elevation / Materials | §5 | shadow 階層、backdrop-filter |
| 7 | Iconography | §6 | aria-label、SF Symbols 整合 |
| 8 | Components | §7 | Button / TextField の一貫性 |
| 9 | States | §8 | hover/focus/active/disabled |
| 10 | Motion | §9 | prefers-reduced-motion、duration |
| 11 | Dark Mode | §2.3 | prefers-color-scheme、tokens swap |
| 12 | Tokens (DTCG) | §10 | 命名、ハードコード残存 |
| 13 | Accessibility (A11y) | §11 | alt、aria、tabindex |
| 14 | Forms | §12 | input type、autocomplete |
| 15 | Navigation | §13 | aria-current、skip link |
| 16 | Responsive | §14 | viewport、ブレークポイント、dvh |
| 17 | Microcopy | §16 | ボタン文言、エラーメッセージ |
| 18 | i18n / RTL | §17 | logical properties、`lang` 属性 |
| 19 | Heuristics / Ethics | §18-19 | dark patterns、現在地表示 |
| 20 | **Japanese Typography** | `wabun-typography.md` | line-height、palt、autospace、行頭禁則、和文フォント |

## カテゴリの取捨選択

- **Quick audit (5 カテゴリ)**: 入力タイプから自動選択（後述）
- **Full audit (全 20)**: 全カテゴリ実行（既定）
- **Custom**: ユーザ指定

Quick audit の自動マップ:

| 入力タイプ | 選択カテゴリ |
|-----------|------------|
| Tailwind config 単体 | 1, 2, 3, 5, 12 |
| 単一 CSS ファイル（小） | 1, 2, 3, 9, 20 |
| DTCG JSON | 1, 2, 5, 6, 12 |
| 和文サイト全体 | 1, 2, 11, 16, 20 |
| 入力タイプ不明 | 2, 3, 9, 13, 20 |

## 信頼度（Step 1.5）

| 入力タイプ | 信頼度 | 修正係数 |
|-----------|--------|---------|
| CSS / SCSS / Tailwind config（コード） | 🟢 High | ×1.0 |
| DTCG JSON | 🟢 High | ×1.0 |
| スクリーンショット / 画像 | 🟡 Medium | ×0.5（Critical は満額） |
| 説明文のみ | 🔴 Low | 採点不可 |

## レポートの最終行（必須）

毎回、以下の 3 行を末尾に置く:

```
Score: 100 − (C×12) − (S×8) − (M×4) − (T×1) = NN/100
Confidence: 🟢/🟡/🔴
Saved to: .brain/thoughts/shared/research/{date}-wabun-hig-audit-{target}.md
```
