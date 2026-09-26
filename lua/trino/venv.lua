local M = {}

function M.build()
  local plugin_root = vim.fn.fnamemodify(
    debug.getinfo(1, "S").source:sub(2),
    ":h:h:h"
  )
  local pydir = plugin_root .. "/python"
  local python = pydir .. "/.venv/bin/python"

  if vim.fn.executable("python3") ~= 1 then
    vim.notify("No python3 in PATH", vim.log.levels.ERROR)
    return
  end

  -- python version should not be an issue
  -- debian python might fail to create venv if python3.xx-venv is not installed
  vim.fn.system({ "python3", "-m", "venv", pydir .. "/.venv" })
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to create venv", vim.log.levels.ERROR)
    return
  end

  vim.fn.system({ python, "-m", "pip", "install", "-r", pydir .. "/requirements.txt" })
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to install requirements in venv", vim.log.levels.ERROR)
    return
  end
end

return M
