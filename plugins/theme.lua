local theme_config = require "user.plugins.config.theme"
local common_styles = {
  comments = "italic",
  keywords = "bold",
  types = "italic,bold",
}

local _themes = {
  {
    "EdenEast/nightfox.nvim",
    {
      opts = {
        options = {
          dim_inactive = true,
          styles = common_styles,
          inverse = {
            search = true,
            visual = true,
          },
          modules = {
            telescope = {
              TelescopeMatching = { link = "Substitute" },
            },
          },
        },
      },
    },
  },
  { "uloco/bluloco.nvim", { dependencies = { "rktjmp/lush.nvim" } } },
  { "ramojus/mellifluous.nvim", { opts = { dim_inactive = true } } },
  { "nyoom-engineering/oxocarbon.nvim" },
  { "tiagovla/tokyodark.nvim" },
  { "ellisonleao/gruvbox.nvim" },
  { "marko-cerovac/material.nvim" },
  { "dasupradyumna/midnight.nvim" },
  { "akinsho/horizon.nvim", { version = "*", lazy = false, priority = 1000 } },
  { "zootedb0t/citruszest.nvim" },
  { "loctvl842/monokai-pro.nvim" },
  { "navarasu/onedark.nvim", {
    priority = 1000,
    opts = {
      style = "darker",
    },
  } },
  { "folke/tokyonight.nvim", {
    opts = {
      style = "storm",
      light_style = "day",
    },
  } },
  {
    "projekt0n/github-nvim-theme",
    {
      lazy = false,
      priority = 1000,
      config = function()
        require("github-theme").setup {
          dim_inactive = true,
          styles = common_styles,
        }
      end,
    },
  },
}

-- Configure themes
local themes = vim.tbl_map(function(o)
  if not o or #o == 0 then return {} end
  return theme_config.configure_theme(o[1], o[2] or {})
end, _themes)

-- Lush is used to calculate hexes and other helpful things
table.insert(themes, {
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 999,
    config = theme_config.configure_lush,
  },
})

-- TODO Fix error caused when mapping
table.insert(themes, {
  "catppuccin/nvim",
  name = "catppuccin",
  opts = {
    integrations = {
      notify = true,
      aerial = true,
      alpha = true,
      indent_blankline = {
        enabled = true,
        colored_indent_levels = true,
      },
      lsp_saga = true,
      neotree = true,
      noice = true,
      navic = true,
      lsp_trouble = true,
    },
  },
  priority = 1000,
})

-- table.insert(themes, {
--   "f-person/auto-dark-mode.nvim",
--   lazy = false,
--   priority = 999, -- Load after colorschemes
--   enabled = user_config.defaults.background_toggle,
--   config = function(_, opts)
--     opts.update_interval = 1000
--     opts.set_dark_mode = function() user_utils.set_background_and_theme("dark", user_config.defaults.theme.dark) end
--     opts.set_light_mode = function() user_utils.set_background_and_theme("light", user_config.defaults.theme.light) end
--     require("auto-dark-mode").setup(opts)
--   end,
-- })

return themes
