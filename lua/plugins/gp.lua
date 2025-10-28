-- ~/.config/nvim/lua/plugins/gp.lua
-- gp.nvim: OpenAI GPT integration with custom prompts

return {
  "robitx/gp.nvim",
  config = function()
    require("gp").setup({
      -- API key設定（環境変数から取得）
      openai_api_key = os.getenv("OPENAI_API_KEY"),
      
      -- カスタムhooks（専用プロンプト呼び出し）
      hooks = {
        -- ノート整理コマンド: :GpCompactNote
        -- Visual modeで選択したテキストを構造化されたノートに変換
        CompactNote = function(gp, params)
          local template = [[<role>
あなたは「ノート整理アシスタント」。与えられた日本語テキストから、事実・概念・理由・結果を抽出し、「＝（同格/What）」と「→（因果/Why）」で再構成する専門家。
</role>

<context>
- 目的：論点をひと目で把握できる要約ノートを生成する。
- 期待読者：議事録・調査メモ・学習ノートを素早く再確認したい人。
</context>

<data>
{{selection}}
</data>

<analysis_framework>
1) 主要主張/中心事実を特定し先頭に置く。  
2) What関係（定義・言い換え・具体⇆抽象・同義）は「＝」で接続。  
3) Why関係（原因・理由・目的・結果・影響・前提）は「→」で接続。  
4) 1行=1情報単位。冗語・接続詞を削ぎ落とし、短く明確に。  
5) 必要に応じて行頭に「Q:」「A:」を付与可（問いと答えが明確な場合）。  
6) 入力が混在/冗長でも、重複を統合し矛盾は並列表記。推測はしない。  
7) 日本語で、用語は原文優先（初出で簡潔に定義）。固有名詞は統一。  
</analysis_framework>

<output_requirements>
- 出力は「整理後のノート」**のみ**を1つのコードブロックで返す（追加説明・前置き禁止）。
- 先頭に `> [!note]` を置く。
- すべての行を md のハイフン `-` で始める箇条書きにする（ネスト時は4スペースインデント）。
- 主要主張/中心事実を最初の箇条に置く。
- 行内で関係を明示するため `[=]` または `[→]` を必ず含める（両方併用可）。
- 例示や補足は下位の箇条に配置し、出典/引用があれば括弧で短く記す。
</output_requirements>

<output_format>
```md
> [!note]
- 主要主張/要点
    - [→] 原因/理由
    - [→] 結果/影響
    - [=] 定義/言い換え/具体例
    - [=] 関連概念
- Q: 簡潔な問い
    - A: 回答
```
</output_format>]]

          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.rewrite, agent, template)
        end,
      },
    })
    
    -- キーマップ設定
    local function keymapOptions(desc)
      return {
        noremap = true,
        silent = true,
        nowait = true,
        desc = "GPT prompt " .. desc,
      }
    end
    
    -- Visual modeでノート整理を実行
    vim.keymap.set("v", "<leader>an", ":<C-u>'<,'>GpCompactNote<cr>", keymapOptions("Compact Note"))
  end,
}
