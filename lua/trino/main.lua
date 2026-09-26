local input = require("trino.input")
local output = require("trino.output")
local paths = require("trino.paths")

local M = {}

function M.run_payload(sql, config)
  local payload = vim.json.encode({
    config = config,
    sql = sql,
  })

  local python = paths.python()
  if not python then
    vim.notify("No python in PATH", vim.log.levels.ERROR)
    return
  end

  local result = vim.system(
    {
      python,
      paths.pydir() .. "/trino_query.py",
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
