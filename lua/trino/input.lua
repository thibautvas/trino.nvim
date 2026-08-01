local M = {}

function M.get_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local lines = vim.fn.getline(start_pos[2], end_pos[2])

  if #lines == 0 then
    return {}
  end

  lines[1] = string.sub(lines[1], start_pos[3])
  lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])

  return lines
end

function M.get_selection_text()
  return table.concat(M.get_selection(), "\n")
end

return M
