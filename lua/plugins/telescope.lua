return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.5", -- 安定版を指定（または最新版）
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-fzf-native.nvim", -- 高速化（後述）
  },
  build = "make", -- fzf-native用
  config = function()
    require("telescope").setup {
      defaults = {
        sorting_strategy = "ascending",
        -- アイコンと余計な列を非表示
        file_icons = true,
        git_icons = false,
        color_icons = false,
        -- プレビューウィンドウを右側に配置
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            height = 0.8,
            width = 0.9,
            preview_width = 0.6,
            prompt_position = "bottom",
          },
        },
        -- 結果の表示形式をシンプルに
        entry_prefix = "  ",
        selection_caret = "> ",
        multi_icon = "+ ",
        -- path_displayをシンプルに
        path_display = { "tail" },
      },
      pickers = {
        commands = {
          -- コマンド検索で詳細情報も表示
          show_all_commands = true,
          layout_config = {
            horizontal = {
              width = 0.9,
              height = 0.8,
              preview_width = 0.6,
            },
          },
          -- アイコンやマーカーを非表示
          disable_devicons = true,
        },
        find_files = {
          -- ファイル検索もシンプルに
          file_icons = true,
          git_icons = false,
          disable_devicons = false,
        },
        oldfiles = {
          file_icons = true,
          git_icons = false,
          disable_devicons = false,
          -- パス表示をシンプルに
          path_display = { "tail" },
        },
      },
    }
    require("telescope").load_extension("fzf")
    
    -- キーマッピング設定
    local builtin = require('telescope.builtin')
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local entry_display = require('telescope.pickers.entry_display')
    
    -- コマンド検索をカスタマイズ（コマンド名+説明の2列表示）
    local commands_picker = function(opts)
      opts = opts or {}
      
      -- 全コマンドを取得
      local commands = {}
      local command_list = vim.api.nvim_get_commands({})
      for name, details in pairs(command_list) do
        table.insert(commands, {
          name = name,
          definition = details.definition or '',
          desc = details.definition or '',
        })
      end
      
      -- Luaコマンドも追加
      local lua_commands = vim.tbl_keys(require('telescope.builtin'))
      for _, cmd in ipairs(lua_commands) do
        table.insert(commands, {
          name = 'Telescope ' .. cmd,
          definition = 'lua require("telescope.builtin").' .. cmd .. '()',
          desc = '<Lua funct.>',
        })
      end
      
      -- コマンド名の最大幅を計算
      local max_name_width = 0
      for _, cmd in ipairs(commands) do
        if #cmd.name > max_name_width then
          max_name_width = #cmd.name
        end
      end
      
      -- 2列表示用のdisplayerを作成
      local displayer = entry_display.create {
        separator = "  ",
        items = {
          { width = max_name_width + 2 },
          { remaining = true },
        },
      }
      
      pickers.new(opts, {
        prompt_title = 'Commands',
        finder = finders.new_table {
          results = commands,
          entry_maker = function(entry)
            return {
              value = entry,
              display = function(ent)
                return displayer {
                  ent.value.name,
                  { ent.value.desc, "TelescopeResultsComment" },
                }
              end,
              ordinal = entry.name,
            }
          end,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then
              vim.cmd(selection.value.name)
            end
          end)
          return true
        end,
      }):find()
    end
    
    -- キーマッピング設定
    vim.keymap.set('n', '<leader>p', commands_picker, { desc = "コマンド検索 (Leader+P)" })
    vim.keymap.set('n', '<leader>o', builtin.oldfiles, { desc = "最近開いたファイル (Leader+O)" })
    vim.keymap.set('n', '<leader>k', builtin.keymaps, { desc = "キーマップ検索 (Leader+K)" })
    vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = "ファイル検索 (Leader+F)" })
    vim.keymap.set('n', '<leader>g', builtin.live_grep, { desc = "テキスト検索 (Leader+G)" })
  end,
}
