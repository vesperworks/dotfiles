local ensure_installed = {
  "json",
  "javascript",
  "typescript",
  "tsx",
  "yaml",
  "html",
  "css",
  "prisma",
  "markdown",
  "markdown_inline",
  "svelte",
  "graphql",
  "bash",
  "lua",
  "vim",
  "dockerfile",
  "gitignore",
  "query",
  "vimdoc",
  "c",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      -- 新旧API両対応: main ブランチ（新）か master ブランチ（旧）かを判定
      local has_new_api, ts_config = pcall(require, "nvim-treesitter.config")
      if has_new_api and ts_config.get_installed then
        -- 新API (main branch)
        local installed = ts_config.get_installed()
        local to_install = vim.iter(ensure_installed)
          :filter(function(lang)
            return not vim.tbl_contains(installed, lang)
          end)
          :totable()
        if #to_install > 0 then
          require("nvim-treesitter").install(to_install)
        end

        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("vw_treesitter", { clear = true }),
          callback = function()
            pcall(vim.treesitter.start)
            if vim.bo.indentexpr == "" then
              vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          end,
        })
      else
        -- 旧API (master branch) — Lazy sync 後に自動移行される
        local ok, configs = pcall(require, "nvim-treesitter.configs")
        if ok then
          configs.setup({
            highlight = { enable = true, additional_vim_regex_highlighting = false },
            indent = { enable = true },
            ensure_installed = ensure_installed,
          })
        end
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      -- 新旧API両対応
      local has_new, ts_textobjects = pcall(require, "nvim-treesitter-textobjects")
      if not has_new or not ts_textobjects.setup then
        -- 旧API: nvim-treesitter.configs で既に設定済み（master branch）
        local ok, configs = pcall(require, "nvim-treesitter.configs")
        if ok then
          configs.setup({
            textobjects = {
              select = {
                enable = true,
                lookahead = true,
                keymaps = {
                  ["af"] = "@function.outer", ["if"] = "@function.inner",
                  ["ac"] = "@class.outer", ["ic"] = "@class.inner",
                  ["aa"] = "@parameter.outer", ["ia"] = "@parameter.inner",
                  ["al"] = "@loop.outer", ["il"] = "@loop.inner",
                  ["ai"] = "@conditional.outer", ["ii"] = "@conditional.inner",
                  ["a/"] = "@comment.outer", ["i/"] = "@comment.inner",
                  ["ab"] = "@block.outer", ["ib"] = "@block.inner",
                  ["as"] = "@statement.outer", ["is"] = "@scopename.inner",
                  ["aA"] = "@attribute.outer", ["iA"] = "@attribute.inner",
                  ["aF"] = "@frame.outer", ["iF"] = "@frame.inner",
                },
              },
              move = {
                enable = true,
                set_jumps = true,
                goto_next_start = {
                  ["]m"] = "@function.outer", ["]]"] = "@class.outer",
                  ["]l"] = "@loop.*", ["]s"] = "@statement.outer",
                  ["]i"] = "@conditional.outer", ["]a"] = "@parameter.inner",
                },
                goto_next_end = {
                  ["]M"] = "@function.outer", ["]["] = "@class.outer",
                  ["]L"] = "@loop.*", ["]S"] = "@statement.outer",
                  ["]I"] = "@conditional.outer", ["]A"] = "@parameter.inner",
                },
                goto_previous_start = {
                  ["[m"] = "@function.outer", ["[["] = "@class.outer",
                  ["[l"] = "@loop.*", ["[s"] = "@statement.outer",
                  ["[i"] = "@conditional.outer", ["[a"] = "@parameter.inner",
                },
                goto_previous_end = {
                  ["[M"] = "@function.outer", ["[]"] = "@class.outer",
                  ["[L"] = "@loop.*", ["[S"] = "@statement.outer",
                  ["[I"] = "@conditional.outer", ["[A"] = "@parameter.inner",
                },
              },
            },
          })
        end
        return
      end

      -- 新API (main branch)
      ts_textobjects.setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local select_obj = function(query)
        return function()
          require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
        end
      end

      local goto_next_start = function(query)
        return function()
          require("nvim-treesitter-textobjects.move").goto_next_start(query, "textobjects")
        end
      end

      local goto_next_end = function(query)
        return function()
          require("nvim-treesitter-textobjects.move").goto_next_end(query, "textobjects")
        end
      end

      local goto_prev_start = function(query)
        return function()
          require("nvim-treesitter-textobjects.move").goto_previous_start(query, "textobjects")
        end
      end

      local goto_prev_end = function(query)
        return function()
          require("nvim-treesitter-textobjects.move").goto_previous_end(query, "textobjects")
        end
      end

      -- select keymaps
      local select_maps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
        ["ai"] = "@conditional.outer",
        ["ii"] = "@conditional.inner",
        ["a/"] = "@comment.outer",
        ["i/"] = "@comment.inner",
        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",
        ["as"] = "@statement.outer",
        ["is"] = "@scopename.inner",
        ["aA"] = "@attribute.outer",
        ["iA"] = "@attribute.inner",
        ["aF"] = "@frame.outer",
        ["iF"] = "@frame.inner",
      }
      for key, query in pairs(select_maps) do
        vim.keymap.set({ "x", "o" }, key, select_obj(query), { desc = "TS: " .. query })
      end

      -- move keymaps: next start
      local next_start = {
        ["]m"] = "@function.outer",
        ["]]"] = "@class.outer",
        ["]l"] = "@loop.*",
        ["]s"] = "@statement.outer",
        ["]i"] = "@conditional.outer",
        ["]a"] = "@parameter.inner",
      }
      for key, query in pairs(next_start) do
        vim.keymap.set({ "n", "x", "o" }, key, goto_next_start(query), { desc = "TS next: " .. query })
      end

      -- move keymaps: next end
      local next_end = {
        ["]M"] = "@function.outer",
        ["]["] = "@class.outer",
        ["]L"] = "@loop.*",
        ["]S"] = "@statement.outer",
        ["]I"] = "@conditional.outer",
        ["]A"] = "@parameter.inner",
      }
      for key, query in pairs(next_end) do
        vim.keymap.set({ "n", "x", "o" }, key, goto_next_end(query), { desc = "TS next end: " .. query })
      end

      -- move keymaps: prev start
      local prev_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
        ["[l"] = "@loop.*",
        ["[s"] = "@statement.outer",
        ["[i"] = "@conditional.outer",
        ["[a"] = "@parameter.inner",
      }
      for key, query in pairs(prev_start) do
        vim.keymap.set({ "n", "x", "o" }, key, goto_prev_start(query), { desc = "TS prev: " .. query })
      end

      -- move keymaps: prev end
      local prev_end = {
        ["[M"] = "@function.outer",
        ["[]"] = "@class.outer",
        ["[L"] = "@loop.*",
        ["[S"] = "@statement.outer",
        ["[I"] = "@conditional.outer",
        ["[A"] = "@parameter.inner",
      }
      for key, query in pairs(prev_end) do
        vim.keymap.set({ "n", "x", "o" }, key, goto_prev_end(query), { desc = "TS prev end: " .. query })
      end
    end,
  },
}
