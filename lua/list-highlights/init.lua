local M = {}

local function hl_classic()
  local ls = vim.fn.synID(vim.fn.line("."), vim.fn.col("."), 1)
  return { vim.fn.synIDattr(ls, "name"), vim.fn.synIDattr(vim.fn.synIDtrans(ls), "name") }
end

local function hl_treesitter()
  local result = vim.treesitter.get_captures_at_cursor(0)
  return result
end

M.hl_groups_under_cursor = function()
  local ts_hl = hl_treesitter()
  local cl_hl = hl_classic()

  local Popup = require("nui.popup")
  local autocmd = require("nui.utils.autocmd")
  local event = require("nui.utils.autocmd").event

  local popup = Popup({
    enter = false,
    relative = "cursor",
    focusable = false,
    border = {
      style = "rounded",
    },
    position = 0,
    size = {
      width = 20,
      height = "10%",
    },
  })

  -- unmount component when cursor leaves buffer
  local bufnr = vim.api.nvim_get_current_buf()
  autocmd.buf.define(bufnr, event.CursorMoved, function()
    popup:unmount()
  end, { once = true })

  -- mount/open the component
  popup:mount()

  popup:mount()
  popup:on(event.CursorMoved, function()
    popup:unmount()
  end)

  -- set content
  local lines = {}
  table.insert(lines, "# Treesitter")
  for _, hl in ipairs(ts_hl) do
    table.insert(lines, "- @" .. hl)
  end
  table.insert(lines, "# Classic")
  for _, hl in ipairs(cl_hl) do
    if hl ~= "" then
      table.insert(lines, "- " .. hl)
    end
  end
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, lines)
end

return M
