local M = {}

function M.pydir()
  local plugin_root = vim.fn.fnamemodify(
    debug.getinfo(1, "S").source:sub(2),
    ":h:h:h"
  )

  return plugin_root .. "/python"
end

function M.python()
  local venv_python = M.pydir() .. "/.venv/bin/python"

  if vim.fn.executable(venv_python) == 1 then
    return venv_python
  end

  if vim.fn.executable("python3") == 1 then
    return vim.fn.exepath("python3")
  end

  return nil
end

return M
