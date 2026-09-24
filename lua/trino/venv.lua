local M = {}

function M.build()
  local plugin_root = vim.fn.fnamemodify(
    debug.getinfo(1, "S").source:sub(2),
    ":h:h:h"
  )

  local python_dir = plugin_root .. "/python"
  local python_bin = python_dir .. "/.venv/bin/python"

  vim.fn.system({ "python3", "-m", "venv", python_dir .. "/.venv" })
  if vim.v.shell_error ~= 0 then
    vim.notify("Trino venv failed", vim.log.levels.ERROR)
    return
  end

  vim.fn.system({ python_bin, "-m", "pip", "install", "-r", python_dir .. "/requirements.txt" })
  if vim.v.shell_error ~= 0 then
    vim.notify("Trino pip failed", vim.log.levels.ERROR)
    return
  end
end

return M
