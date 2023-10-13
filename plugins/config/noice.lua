local M = {}

M.config = function()
  require("noice").setup {
    lsp = {
      hover = {
        enabled = true,
      },
      signature = {
        enabled = true,
      },
      -- override markdown rendering so that cmp and other plugins use Treesitter
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    views = {
      cmdline_popup = {
        position = {
          row = "50%",
          col = "50%",
        },
        size = {
          width = 60,
          height = "auto",
        },
      },
      popupmenu = {
        enabled = true,
        backend = "nui",
        relative = "editor",
        -- position = {
        --   row = 8,
        --   col = "50%",
        -- },
        size = {
          width = "auto",
          height = "auto",
        },
        border = {
          style = "rounded",
          padding = { 0, 1 },
        },
        win_options = {
          winhighlight = {
            Normal = "Normal",
            FloatBorder = "DiagnosticInfo",
          },
        },
      },
    },
    presets = {
      bottom_search = false,
      command_palette = true,
      inc_rename = true,
      -- lsp_doc_border = true,
      long_message_to_split = true,
    },
  }
end

return M