local M = {}

function M.get_selection()
  local mode = vim.fn.mode()

  local pos1, pos2, regtype
  if mode:match("[vV\22]") then
    pos1, pos2, regtype = vim.fn.getpos("v"), vim.fn.getpos("."), mode
  else
    pos1, pos2, regtype = vim.fn.getpos("'<"), vim.fn.getpos("'>"), vim.fn.visualmode()
  end

  if pos1[2] == 0 or pos2[2] == 0 or regtype == "" then
    return {}
  end

  return vim.fn.getregion(pos1, pos2, { type = regtype })
end

function M.get_selection_text()
  return table.concat(M.get_selection(), "\n")
end

return M
