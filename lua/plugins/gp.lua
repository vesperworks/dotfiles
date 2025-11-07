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
        -- ノート整理: 選択範囲を構造化ノートに変換（追加）
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

          -- 選択範囲の終了位置に絵文字マーカーを即座に挿入
          local buf = vim.api.nvim_get_current_buf()
          local end_line = vim.fn.line("'>")
          
          -- 一意なIDを生成
          local marker_id = "gp-marker-" .. os.time() .. "-" .. math.random(1000, 9999)
          local marker_text = "✨📝 <!-- " .. marker_id .. " -->"
          
          vim.api.nvim_buf_set_lines(buf, end_line, end_line, false, {
            "",
            marker_text
          })
          
          -- 処理完了時にマーカーを削除
          local function remove_marker()
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            for i, line in ipairs(lines) do
              if line:find(marker_id, 1, true) then
                vim.api.nvim_buf_set_lines(buf, i-1, i, false, {})
                break
              end
            end
          end
          
          vim.api.nvim_create_autocmd("User", {
            pattern = "GpDone",
            callback = remove_marker,
            once = true
          })

          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.append, agent, template)
        end,
        
        -- ToDo抽出: 音声文字起こしから実行可能なToDoを抽出（追加）
        ExtractTodo = function(gp, params)
          local template = [[<role>
あなたは音声レコーディングの文字起こしから、実行可能なToDoを抽出・整理する専門家です。
</role>

<instructions>
以下の手順で実行してください：
1. 入力された音声レコーディングの文字起こしを読み取る。
2. 内容の中から「行動が必要な発言」「次にやるべきこと」「決定事項」を抽出する。
3. 同義・重複を統合し、簡潔で実行可能なタスク名にまとめる（動詞始まりを推奨）。
4. 各タスクの進捗が明確な場合のみ、以下の記号を使って表記する：
   - "[ ]" 未着手（デフォルト）
   - "[-]" 着手中
   - "[x]" 完了
   - "[/]" 中止
5. 不明確なタスクや確認が必要な項目には「⚠️」を末尾に付ける。
6. 出力はマークダウンのチェックリスト形式で、発言順（時系列）に並べる。
</instructions>

<user_request>
この音声レコーディングの内容を整理して、ToDoリストを出力してください。
</user_request>

<data>
{{selection}}
</data>

<output_requirements>
- 文脈説明や会話引用は不要。
- シンプルなチェックリスト形式で出力。
- 各項目は1行の行動指示として記述。
- 不明確なものは末尾に「⚠️」を付す。
- 並び順は発言順（時系列）。
</output_requirements>

<output_format>
## TODO一覧
- [ ] タスク内容
- [ ] タスク内容
- [ ] タスク内容 ⚠️
</output_format>]]

          -- 選択範囲の終了位置に絵文字マーカーを即座に挿入
          local buf = vim.api.nvim_get_current_buf()
          local end_line = vim.fn.line("'>")
          
          -- 一意なIDを生成
          local marker_id = "gp-marker-" .. os.time() .. "-" .. math.random(1000, 9999)
          local marker_text = "✅📋 <!-- " .. marker_id .. " -->"
          
          vim.api.nvim_buf_set_lines(buf, end_line, end_line, false, {
            "",
            marker_text
          })
          
          -- 処理完了時にマーカーを削除
          local function remove_marker()
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            for i, line in ipairs(lines) do
              if line:find(marker_id, 1, true) then
                vim.api.nvim_buf_set_lines(buf, i-1, i, false, {})
                break
              end
            end
          end
          
          vim.api.nvim_create_autocmd("User", {
            pattern = "GpDone",
            callback = remove_marker,
            once = true
          })

          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.append, agent, template)
        end,
        
        -- タスク分解: GTDメソッドに基づき25分以内のタスクに分解（追加）
        BreakdownTask = function(gp, params)
          local template = [[<role>
あなたはGTD（Getting Things Done）メソッドの専門家であり、音声レコーディングの文字起こしや会話ログから「すぐ実行可能なタスク」を25分以内（1ポモドーロ）で完了できる粒度にまで分解するプロフェッショナルです。
</role>

<instructions>
以下の手順で実行してください：
1. 入力されたタスクまたは文字起こしを読み取り、「実行が必要なアクション」をすべて抽出する。
2. 各アクションを「25分以内に完了できる単一の行動単位」に分解する。
3. 依存関係や順序がある場合は、上から順に並べて構造化する。
4. 各タスクは動詞で始め、実行内容が具体的にイメージできるようにする。
5. 不明確な要素や確認が必要な箇所には「⚠️」を付す。
6. 出力はマークダウンのチェックリスト形式で、1行1アクションで記述する。
7. 優先度が判断できる場合は、以下の絵文字で示す：
   - 🔴 高：すぐ実行すべき・最重要
   - 🟡 中：なるべく早く着手
   - ⚪️ 低：時間がある時でOK
</instructions>

<user_request>
与えられたToDoをGTDメソッドに基づき、1ポモドーロ（25分）以内で完了できる実行可能タスクに分解してください。
</user_request>

<data>
{{selection}}
</data>

<output_requirements>
- 出力はMarkdown形式のチェックリスト。
- 各項目は1行の具体的アクションとして記述。
- 不明確なものは「⚠️」で明示。
- 優先度がわかる場合は絵文字（🔴 / 🟡 / ⚪️）で示す。
- 並び順は実行順序。
</output_requirements>

<output_format>
## ✅ 25分以内の実行タスクリスト

- [ ] 🔴 タスク内容
- [ ] 🟡 タスク内容
- [ ] ⚪️ タスク内容 ⚠️
</output_format>]]

          -- 選択範囲の終了位置に絵文字マーカーを即座に挿入
          local buf = vim.api.nvim_get_current_buf()
          local end_line = vim.fn.line("'>")
          
          -- 一意なIDを生成
          local marker_id = "gp-marker-" .. os.time() .. "-" .. math.random(1000, 9999)
          local marker_text = "🎯✅ <!-- " .. marker_id .. " -->"
          
          vim.api.nvim_buf_set_lines(buf, end_line, end_line, false, {
            "",
            marker_text
          })
          
          -- 処理完了時にマーカーを削除
          local function remove_marker()
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            for i, line in ipairs(lines) do
              if line:find(marker_id, 1, true) then
                vim.api.nvim_buf_set_lines(buf, i-1, i, false, {})
                break
              end
            end
          end
          
          vim.api.nvim_create_autocmd("User", {
            pattern = "GpDone",
            callback = remove_marker,
            once = true
          })

          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.append, agent, template)
        end,
        
        -- ツリー化: 文章を階層的に分解・整理（追加）
        TreeStructure = function(gp, params)
          local template = [[<role>
あなたは、文章を意味・構造ごとに階層的に分解して整理する専門家です。
</role>

<instructions>
以下の手順で実行してください：
1. ユーザーが入力した文章を読み取る。
2. 内容を「主題」「要素」「補足」「具体例」「条件」「感情」などの意味単位に分ける。
3. 意味の親子関係をもとに、論理的な階層構造を構築する。
4. 階層は抽象→具体の順で並べ、必要に応じて入れ子構造を深める。
5. 出力はMarkdownリスト（`-` とインデント）形式で表現する。
</instructions>

<user_request>
{{selection}}
</user_request>

<output_requirements>
- 出力は必ずMarkdownのリスト形式とする（`-` とインデント）。
- 各階層は1段深くなるごとに2スペースインデントする。
- 各項目は短いフレーズまたは簡潔な文で表す。
- 文脈の意味を崩さず、構造的に整理する。
- 不要な重複は省くが、ニュアンスは保持する。
</output_requirements>

<output_format>
## 構造ツリー出力
```markdown
- [主題]
  - [要素1]
    - [詳細1-1]
    - [詳細1-2]
  - [要素2]
    - [補足説明]
```
</output_format>]]

          -- 選択範囲の終了位置に絵文字マーカーを即座に挿入
          local buf = vim.api.nvim_get_current_buf()
          local end_line = vim.fn.line("'>")
          
          -- 一意なIDを生成
          local marker_id = "gp-marker-" .. os.time() .. "-" .. math.random(1000, 9999)
          local marker_text = "🌳📋 <!-- " .. marker_id .. " -->"
          
          vim.api.nvim_buf_set_lines(buf, end_line, end_line, false, {
            "",
            marker_text
          })
          
          -- 処理完了時にマーカーを削除
          local function remove_marker()
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            for i, line in ipairs(lines) do
              if line:find(marker_id, 1, true) then
                vim.api.nvim_buf_set_lines(buf, i-1, i, false, {})
                break
              end
            end
          end
          
          vim.api.nvim_create_autocmd("User", {
            pattern = "GpDone",
            callback = remove_marker,
            once = true
          })

          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.append, agent, template)
        end,
        
        -- シンプル化: 要約と用語精査（追加）
        SimplifyText = function(gp, params)
          local template = [[<role>
あなたは「要約と用語精査の編集者」です。ユーザーの入力を意図の核心だけに削ぎ落とした結論へ圧縮し、必要に応じて用語を厳密に精査し、最後に"一撃で解決"するための最小限の質問を作成します。
</role>

<instructions>
以下の手順で実行してください（入力のモード切替は不要）：
1. 一行結論の作成
   - ユーザーが「つまり何を言いたいのか」を一文（推奨120字以内）で断定的に述べる
   - 比喩・前置き・不要な婉曲を避け、主語と動詞を明確化
2. 用語精査（必要に応じて）
   - 略語・アクロニム・新語候補を抽出
   - 文脈から意味候補を列挙し、信頼できる一次・公的ソースを優先して検証
   - 同形異義語がある場合は、採用理由を短く明示
3. "検索して解説"（f様式の適用基準）
   - 文中に新語・曖昧語・専門略語が含まれ、理解に影響する場合に実施
   - 主要用語を簡潔に定義し、当該文脈での採用理由を1行で示す
   - 用語整理を踏まえ、結論を1行で再提示
4. "さらに噛み砕く"（m様式の適用基準）
   - 非専門読者向けに、因果・具体例・Next Actionを短く提示したい場合に実施
5. "箇条書き"（t様式の適用基準）
   - 主要ポイントを素早く俯瞰したい場合に実施（最大5点）
6. 一撃解決の質問（必須）
   - 不足している最小限の変数を一つだけ問う
   - 形式はYes/Noまたは択一（上限3～5択）。未指定時のデフォルトも示す
   - 追加質問が不要なほど情報が揃っていれば「（追加質問は不要）」と明記
7. 文体・品質
   - 日本語、簡潔・明快・平叙文
   - 主観推測の濫用を避け、断定は根拠に基づく
</instructions>

<user_request>
{{selection}}
</user_request>

<output_requirements>
- デフォルト出力として「## デフォルト（1行結論）」と「## Q（一撃解決の質問）」を常に含める
- m/t/f様式は、必要時のみ追加で出力（ユーザーが自然文で依頼した場合も可）
- 専門用語・略語は文脈適合の定義で統一
- f様式を出した場合は「用語の整理 → 整理後の結論（1行）」の順
</output_requirements>

<output_format>
## デフォルト（1行結論）
[ユーザーの主張を、最も単純で核心的な一文に要約する]

## m（さらに噛み砕く） ※必要時のみ
- 要点①（具体）
- 要点②（具体）
- 要点③（具体）
- だから何か（So What）
- 取るべき反応（Next Action を一行）

## t（箇条書き） ※必要時のみ
- 主要ポイント（最大5点）
- 背景（任意・1行）
- 前提/制約（任意・1行）

## f（検索して解説） ※必要時のみ
### 用語の整理
- 用語A：定義（出典の種類/要点）｜この文脈での意味採用理由（1行）
- 用語B：定義（出典の種類/要点）｜この文脈での意味採用理由（1行）
- （必要に応じて追加）

### 整理後の結論（1行）
[上記の用語精査を踏まえて再構成した最終結論を1行で記述]

## Q（一撃解決の質問）
[このケースで最短で意思決定/回答に到達する"単一の質問"を、Yes/No か択一で1行提示（必要なら3～5択の選択肢を続けて記載：A) … / B) … / C) …）。十分な情報が揃っている場合は「（追加質問は不要）」と記す]
</output_format>]]

          -- 選択範囲の終了位置に絵文字マーカーを即座に挿入
          local buf = vim.api.nvim_get_current_buf()
          local end_line = vim.fn.line("'>")
          
          -- 一意なIDを生成
          local marker_id = "gp-marker-" .. os.time() .. "-" .. math.random(1000, 9999)
          local marker_text = "🔍📄 <!-- " .. marker_id .. " -->"
          
          vim.api.nvim_buf_set_lines(buf, end_line, end_line, false, {
            "",
            marker_text
          })
          
          -- 処理完了時にマーカーを削除
          local function remove_marker()
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            for i, line in ipairs(lines) do
              if line:find(marker_id, 1, true) then
                vim.api.nvim_buf_set_lines(buf, i-1, i, false, {})
                break
              end
            end
          end
          
          vim.api.nvim_create_autocmd("User", {
            pattern = "GpDone",
            callback = remove_marker,
            once = true
          })

          local agent = gp.get_command_agent()
          gp.Prompt(params, gp.Target.append, agent, template)
        end,
      },
    })
    
    -- GPTプロンプトメニュー関数
    local function show_gpt_prompt_menu()
      local prompt_options = {
        { "CompactNote", "📝 ノート整理 (追加)", "a" },
        { "SimplifyText", "🔍 シンプル化 (追加)", "s" },
        { "BreakdownTask", "✅ タスク分解 (追加)", "d" },
        { "TreeStructure", "🌳 ツリー化 (追加)", "f" },
        { "ExtractTodo", "📋 ToDo抽出 (追加)", "e" },
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
    vim.keymap.set("v", "<leader>la", ":<C-u>'<,'>GpCompactNote<cr>", keymapOptions("Compact Note"))
    vim.keymap.set("v", "<leader>ls", ":<C-u>'<,'>GpSimplifyText<cr>", keymapOptions("Simplify Text"))
    vim.keymap.set("v", "<leader>ld", ":<C-u>'<,'>GpBreakdownTask<cr>", keymapOptions("Breakdown Task"))
    vim.keymap.set("v", "<leader>lf", ":<C-u>'<,'>GpTreeStructure<cr>", keymapOptions("Tree Structure"))
    vim.keymap.set("v", "<leader>le", ":<C-u>'<,'>GpExtractTodo<cr>", keymapOptions("Extract Todo"))
  end,
}
