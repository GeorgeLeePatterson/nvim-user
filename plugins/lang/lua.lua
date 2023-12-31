local linters = require("user.config").get_config "linters.lua"

return {
  -- [[ LSP ]]
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed =
        require("user.utils").list_insert_unique(opts.ensure_installed, {
          "lua_ls",
        })
      return opts
    end,
  },

  -- [[ Treesitter ]]
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "lua" })
      end
      return opts
    end,
  },

  -- [[ Linting / Formatting ]]

  -- Mason-null-ls
  {
    "jay-babu/mason-null-ls.nvim",
    opts = function(_, opts)
      local install = { "stylua" }
      install = require("user.utils").list_insert_unique(install, linters or {})
      opts.ensure_installed =
        require("user.utils").list_insert_unique(opts.ensure_installed, install)
      return opts
    end,
  },

  -- None-ls
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local nls = require "null-ls"
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.diagnostics.selene,
      })
      return opts
    end,
  },

  -- Conform
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.formatters_by_ft =
        vim.tbl_deep_extend("force", opts.formatters_by_ft, {
          ["lua"] = { "stylua" },
        })
      return opts
    end,
  },

  -- Nvim-lint
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts = opts or {}
      opts.linters_by_ft = vim.tbl_deep_extend("force", opts.linters_by_ft, {
        ["lua"] = linters,
      })
      return opts
    end,
  },
}
