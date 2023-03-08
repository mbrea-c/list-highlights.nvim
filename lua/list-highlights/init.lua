local M = {}

local function hl_extmarks()
  local function get_extmark_details_at(ns_id)
    local bufnr = vim.api.nvim_get_current_buf()
    local row = vim.fn.line(".") - 1
    local col = vim.fn.col(".") - 1
    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, { details = 1 })
    local extmarks_match = {}
    for _, extmark in ipairs(extmarks) do
      local start_row = extmark[2]
      local start_col = extmark[3]
      local end_row = extmark[4]["end_row"]
      local end_col = extmark[4]["end_col"]
      if
          end_row ~= nil
          and end_col ~= nil
          and start_row <= row
          and start_col <= col
          and row <= end_row
          and col <= end_col
      then
        table.insert(extmarks_match, extmark)
      end
    end
    return extmarks_match
  end
  local namespaces = vim.api.nvim_get_namespaces()
  local hl_groups = {}
  for _, ns_id in pairs(namespaces) do
    local extmarks = get_extmark_details_at(ns_id)
    for _, extmark in ipairs(extmarks) do
      table.insert(hl_groups, extmark[4]["hl_group"])
    end
  end
  return hl_groups
end

local function hl_synstack()
  local ls = vim.fn.synID(vim.fn.line("."), vim.fn.col("."), 1)
  local synstack = { vim.fn.synIDattr(ls, "name"), vim.fn.synIDattr(vim.fn.synIDtrans(ls), "name") }
  return synstack
end

local function hl_treesitter()
  local result = vim.treesitter.get_captures_at_cursor(0)
  return result
end

M.hl_groups_under_cursor = function()
  local ts_hl = hl_treesitter()
  local ss_hl = hl_synstack()
  local ex_hl = hl_extmarks()

  local lines = {}
  table.insert(lines, "# Treesitter")
  for _, hl in ipairs(ts_hl) do
    table.insert(lines, "- @" .. hl)
  end
  table.insert(lines, "# Extmarks")
  for _, hl in ipairs(ex_hl) do
    if hl ~= "" then
      table.insert(lines, "- " .. hl)
    end
  end
  table.insert(lines, "# Synstack")
  for _, hl in ipairs(ss_hl) do
    if hl ~= "" then
      table.insert(lines, "- " .. hl)
    end
  end

  local vsize = #lines
  local hsize = 0
  for _, line in ipairs(lines) do
    if string.len(line) > hsize then
      hsize = string.len(line)
    end
  end

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
      width = hsize,
      height = vsize,
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
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, lines)
end

return M
