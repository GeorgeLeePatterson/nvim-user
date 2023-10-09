local icons = require("user.config").icons
local user_utils = require "user.utils"
local longest_kind_type = user_utils.longest_line(vim.tbl_keys(icons.kinds))

local M = {}

M.default_kind_priority = {
  TabNine = 15,
  -- Copilot = 15,
  Module = 14,
  Field = 13,
  Function = 12,
  Method = 12,
  Struct = 11,
  Property = 11,
  Constant = 10,
  Enum = 10,
  Interface = 10,
  EnumMember = 10,
  Event = 10,
  Operator = 10,
  Reference = 10,
  Variable = 9,
  File = 8,
  Folder = 8,
  Class = 5,
  Color = 5,
  Keyword = 2,
  Constructor = 1,
  Text = 1,
  TypeParameter = 1,
  Unit = 1,
  Value = 1,
  Snippet = 0,
}

M.lsp_kind_opts = function(opts)
  opts.mode = "symbol_text"
  opts.symbol_map = icons.kinds
  opts.menu = icons.cmp_sources
  opts.maxwidth = 50
  opts.ellipsis_char = "..."
  return opts
end

M.under = function(entry1, entry2)
  local _, entry1_under = entry1.completion_item.label:find "^_+"
  local _, entry2_under = entry2.completion_item.label:find "^_+"
  entry1_under = entry1_under or 0
  entry2_under = entry2_under or 0
  if entry1_under > entry2_under then
    return false
  elseif entry1_under < entry2_under then
    return true
  end
end

function M.lspkind_comparator(conf)
  conf.kind_priority = vim.tbl_deep_extend("force", M.default_kind_priority, (conf or {}).kind_priority or {})
  local lsp_types = require("cmp.types").lsp
  local compare = require "cmp.config.compare"
  return function(entry1, entry2)
    -- LSPs get priority
    local lsp_list = { "nvim_lsp", "nvim_lua" }
    local entry1_lsp = user_utils.arr_has(lsp_list, entry1.source.name)
    local entry2_lsp = user_utils.arr_has(lsp_list, entry2.source.name)
    if not entry1_lsp and not entry2_lsp then return nil end

    -- Then lsp kind
    local kind1 = lsp_types.CompletionItemKind[entry1:get_kind()]
    local kind2 = lsp_types.CompletionItemKind[entry2:get_kind()]

    local priority1 = conf.kind_priority[kind1] or 0
    local priority2 = conf.kind_priority[kind2] or 0
    if priority1 == priority2 then return compare.order(entry1, entry2) end
    return priority2 < priority1
  end
end

-- Format suggestions
function M.format_suggestion(entry, vim_item)
  local default_lsp_kind_opts = M.lsp_kind_opts {}
  local parts = require("lspkind").cmp_format(default_lsp_kind_opts)(entry, vim_item)
  local original_menu = parts.menu

  -- split `kind` to separate icon and actual `type`
  local strings = vim.split(parts.kind, "%s", { trimempty = true })
  local kind = strings[1] or ""
  parts.kind = " " .. kind .. " "

  local kind_type = (strings[2] or "")
  if entry.source.name == "cmp_tabnine" then
    local detail = (entry.completion_item.labelDetails or {}).detail
    if detail and detail:find ".*%%.*" then kind_type = kind_type .. " " .. detail end
    if (entry.completion_item.data or {}).multiline then kind_type = kind_type .. " " .. " " .. "[ml]" end
  end

  -- Combine Kind `type` and Menu
  parts.menu = "    " .. kind_type .. " "

  local longest_w_tn = longest_kind_type + 4
  parts.menu = user_utils.str_pad_len(parts.menu, longest_w_tn) .. "  "

  if original_menu then parts.menu = parts.menu .. original_menu end

  return parts
end

function M.opts(_, o)
  -- Highlight groups for extras
  vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "CmpItemKindTabNine", { fg = "#6CC644" })

  local has_words_before = function()
    unpack = unpack or table.unpack
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
  end
  local cmp = require "cmp"
  local compare = require "cmp.config.compare"
  local luasnip = require "luasnip"

  local opts = vim.tbl_deep_extend("force", o, {
    -- Sources
    sources = cmp.config.sources {
      { name = "cmp_tabnine", priority = 1000 },
      { name = "nvim_lsp", priority = 800, keyword_length = 1 },
      {
        name = "buffer",
        priority = 600,
        keyword_length = 3,
        options = {
          get_bufnrs = function() -- from all buffers (less than 1MB)
            local bufs = {}
            for _, bufn in ipairs(vim.api.nvim_list_bufs()) do
              local buf_size = vim.api.nvim_buf_get_offset(bufn, vim.api.nvim_buf_line_count(bufn))
              if buf_size < 1024 * 1024 then table.insert(bufs, bufn) end
            end
            return bufs
          end,
        },
      },
      { name = "nvim_lua", keyword_length = 1 },
      { name = "luasnip", keyword_length = 2 },
      { name = "path" },
      { name = "emoji" },
    },

    -- Inside formatting
    formatting = {
      fields = { "kind", "abbr", "menu" },
      format = M.format_suggestion,
    },

    -- Sorting
    sorting = {
      comparators = {
        compare.exact,
        M.under,
        compare.score,
        M.lspkind_comparator {},
        compare.offset,
        compare.recently_used,
        compare.locality,
        compare.order,
      },
    },

    -- Window formatting
    window = {
      completion = {
        border = "rounded",
        winhighlight = "Normal:Pmenu,Search:None,FloatBorder:BorderOnly", --
        col_offset = -4,
        side_padding = 0,
      },
    },

    -- Mapping
    mapping = vim.tbl_extend("force", o.mapping, {
      ["<CR>"] = cmp.mapping.confirm { select = true },
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif require("user.config").ai.copilot and require("copilot.suggestion").is_visible() then
          require("copilot.suggestion").accept()
        elseif luasnip.expand_or_locally_jumpable() then
          luasnip.expand_or_jump()
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end, { "i", "s" }),

      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }),
    preselect = cmp.PreselectMode.None,
    -- Ghost text
    experimental = {
      ghost_text = {
        hl_group = "CmpGhostTest",
      },
    },
  })
  return opts
end

function M.config(_, opts)
  local cmp = require "cmp"
  cmp.setup(opts)

  -- configure `cmp-cmdline` as described in their repo: https://github.com/hrsh7th/cmp-cmdline#setup
  cmp.setup.cmdline("/", {
    mapping = cmp.mapping.preset.cmdline(),
    window = { completion = cmp.config.window.bordered { col_offset = 0 } },
    formatting = { fields = { "abbr" } },
    sources = cmp.config.sources {
      { name = "buffer" },
    },
  })
  cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    window = { completion = cmp.config.window.bordered { col_offset = 0 } },
    formatting = { fields = { "abbr" } },
    sources = cmp.config.sources({
      { name = "path" },
    }, {
      {
        name = "cmdline",
        option = {
          ignore_cmds = { "Man", "!" },
        },
      },
    }),
  })

  -- Configure auto parens
  local cmp_autopairs = require "nvim-autopairs.completion.cmp"
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
end

return M
