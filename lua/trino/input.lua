local tl = require("trino.legacy")

local M = {}

function M.get_text()
  local mode = vim.fn.mode()

  local pos1, pos2, regtype
  if mode:match("[vV\22]") then
    pos1, pos2, regtype = vim.fn.getpos("v"), vim.fn.getpos("."), mode
  else
    pos1, pos2, regtype = vim.fn.getpos("'<"), vim.fn.getpos("'>"), vim.fn.visualmode()
  end

  if pos1[2] == 0 or pos2[2] == 0 or regtype == "" then
    return ""
  end

  return table.concat(tl.getregion(pos1, pos2, regtype), "\n")
end

return M
