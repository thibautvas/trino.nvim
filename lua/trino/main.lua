local input = require("trino.input")
local output = require("trino.output")

local M = {}

function M.run_payload(sql, config)
  local payload = vim.json.encode({
    config = config,
    sql = sql,
  })

  local plugin_root = vim.fn.fnamemodify(
    debug.getinfo(1, "S").source:sub(2),
    ":h:h:h"
  )

  local venv_python = plugin_root .. "/python/.venv/bin/python"
  local python = vim.fn.executable(venv_python) == 1 and venv_python or "python3"

  local result = vim.system(
    {
      python,
      plugin_root .. "/python/trino_query.py",
    },
    {
      stdin = payload,
      text = true,
    }
  ):wait()

  if result.code ~= 0 then
    error(result.stderr)
  end

  return vim.split(result.stdout, "\n", { plain = true })
end

function M.run_visual(config)
  local sql = input.get_selection_text()

  if vim.fn.mode():match("[vV\22]") then
    vim.cmd("normal! \27")
  end

  if sql == "" then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end

  local ok, result = pcall(M.run_payload, sql, config)

  if not ok then
    vim.notify(result, vim.log.levels.ERROR)
    return
  end

  output.show(result)
end

return M
