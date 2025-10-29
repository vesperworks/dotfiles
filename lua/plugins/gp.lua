-- ~/.config/nvim/lua/plugins/gp.lua
-- gp.nvim: OpenAI GPT integration with custom prompts

return {
  "robitx/gp.nvim",
  config = function()
    require("gp").setup({
      -- 新しいproviders設定形式
      providers = {
        openai = {
          endpoint = "https://api.openai.com/v1/chat/completions",
          secret = os.getenv("OPENAI_API_KEY"),
        },
      },
      
      -- カスタムhooks（専用プロンプト呼び出し）
      hooks = {
        -- ノート整理: 選択範囲を構造化ノートに変換（書き換え）
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
        
        -- 日本語翻訳: 選択範囲の下に日本語訳を追加
        TranslateJP = function(gp, params)
          local template = "Translate the following text to Japanese:\n\n{{selection}}"
          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.append, agent, template)
        end,
        
        -- コード説明: ポップアップでコード説明を表示
        ExplainCode = function(gp, params)
          local template = "Explain this code in Japanese:\n\n```{{filetype}}\n{{selection}}\n```"
          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.popup, agent, template)
        end,
        
        -- 文法修正: 選択範囲を文法修正して書き換え
        FixGrammar = function(gp, params)
          local template = "Fix grammar and improve this text (keep it in the same language):\n\n{{selection}}"
          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.rewrite, agent, template)
        end,
        
        -- リファクタリング: 垂直分割でリファクタリング提案を表示
        RefactorCode = function(gp, params)
          local template = "Suggest refactoring improvements for this code:\n\n```{{filetype}}\n{{selection}}\n```"
          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.vnew, agent, template)
        end,
        
        -- 要約: 選択範囲の下に要約を追加
        Summarize = function(gp, params)
          local template = "Summarize the following text concisely in Japanese:\n\n{{selection}}"
          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.append, agent, template)
        end,
      },
    })
    
    -- GPTプロンプトメニュー関数
    local function show_gpt_prompt_menu()
      local prompt_options = {
        { "CompactNote", "📝 ノート整理 (書き換え)", "n" },
        { "TranslateJP", "🇯🇵 日本語翻訳 (追加)", "t" },
        { "ExplainCode", "💡 コード説明 (ポップアップ)", "e" },
        { "FixGrammar", "✍️  文法修正 (書き換え)", "f" },
        { "RefactorCode", "🔧 リファクタリング (分割)", "r" },
        { "Summarize", "📋 要約 (追加)", "s" },
      }
      
      -- 専用バッファ作成
      local buf = vim.api.nvim_create_buf(false, true)
      local lines = { "🤖 LLM プロンプトメニュー", "" }
      
      -- 選択肢を表示用に整形
      for _, option in ipairs(prompt_options) do
        local key = option[3]
        local display = option[2]
        table.insert(lines, string.format("  %s: %s", key, display))
      end
      
      table.insert(lines, "")
      table.insert(lines, "  Esc: キャンセル")
      table.insert(lines, "")
      table.insert(lines, "  ▶ キーを入力してください...")
      
      -- バッファにコンテンツを設定
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
      vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
      vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
      
      -- ウィンドウサイズを計算
      local width = 0
      for _, line in ipairs(lines) do
        width = math.max(width, vim.fn.strdisplaywidth(line))
      end
      width = math.min(width + 4, vim.o.columns - 10)
      local height = math.min(#lines + 2, vim.o.lines - 10)
      
      -- フローティングウィンドウ作成
      local win = vim.api.nvim_open_win(buf, true, {
        relative = 'cursor',
        width = width,
        height = height,
        row = 1,
        col = 1,
        border = 'rounded',
        style = 'minimal',
        title = ' LLM Prompts ',
        title_pos = 'center'
      })
      
      -- ウィンドウオプション設定
      vim.api.nvim_win_set_option(win, 'wrap', false)
      vim.api.nvim_win_set_option(win, 'cursorline', false)
      
      -- クローズ処理
      local function close_and_execute(command)
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        if command then
          -- Visual modeの範囲を保持して実行
          vim.cmd("'<,'>Gp" .. command)
        end
      end
      
      -- Insert modeでの文字入力受付（LSP風）
      local function setup_input_handler()
        -- Insert modeに切り替え
        vim.cmd('startinsert')
        
        -- InsertCharPre autocmdで文字入力をキャッチ
        local group = vim.api.nvim_create_augroup('LLMPromptInput', { clear = true })
        
        vim.api.nvim_create_autocmd('InsertCharPre', {
          buffer = buf,
          group = group,
          callback = function()
            local char = vim.v.char
            
            -- 改行は処理しない
            if char == '\n' or char == '\r' then
              return
            end
            
            -- 入力をキャンセル（文字を表示させない）
            vim.v.char = ''
            
            -- 非同期で処理（InsertCharPre中の制限を回避）
            vim.schedule(function()
              -- 各選択肢の文字をチェック
              for _, option in ipairs(prompt_options) do
                if option[3] == char then
                  vim.api.nvim_del_augroup_by_id(group)
                  close_and_execute(option[1])
                  return
                end
              end
            end)
          end
        })
        
        -- ESCキーの処理
        vim.keymap.set('i', '<Esc>', function()
          vim.api.nvim_del_augroup_by_id(group)
          close_and_execute(nil)
        end, { buffer = buf, silent = true })
        
        -- ウィンドウが閉じられた時のクリーンアップ
        vim.api.nvim_create_autocmd('WinClosed', {
          pattern = tostring(win),
          group = group,
          callback = function()
            vim.api.nvim_del_augroup_by_id(group)
          end
        })
      end
      
      -- 少し遅延してからInput modeセットアップ（ウィンドウが完全に表示されてから）
      vim.defer_fn(setup_input_handler, 10)
    end
    
    -- キーマップ設定
    local function keymapOptions(desc)
      return {
        noremap = true,
        silent = true,
        nowait = true,
        desc = "GPT prompt " .. desc,
      }
    end
    
    -- Visual modeでGPTプロンプトメニューを開く
    vim.keymap.set("v", "<leader>l", show_gpt_prompt_menu, keymapOptions("LLM Menu"))
    
    -- 個別コマンドも使える（メニュー経由でも直接でも）
    vim.keymap.set("v", "<leader>ln", ":<C-u>'<,'>GpCompactNote<cr>", keymapOptions("Compact Note"))
    vim.keymap.set("v", "<leader>lt", ":<C-u>'<,'>GpTranslateJP<cr>", keymapOptions("Translate JP"))
    vim.keymap.set("v", "<leader>le", ":<C-u>'<,'>GpExplainCode<cr>", keymapOptions("Explain Code"))
    vim.keymap.set("v", "<leader>lf", ":<C-u>'<,'>GpFixGrammar<cr>", keymapOptions("Fix Grammar"))
    vim.keymap.set("v", "<leader>lr", ":<C-u>'<,'>GpRefactorCode<cr>", keymapOptions("Refactor Code"))
    vim.keymap.set("v", "<leader>ls", ":<C-u>'<,'>GpSummarize<cr>", keymapOptions("Summarize"))
  end,
}
