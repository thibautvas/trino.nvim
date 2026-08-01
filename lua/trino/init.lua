local input = require("trino.input")
local main = require("trino.main")
local output = require("trino.output")

local M = {}

function M.run_visual()
  local sql = input.get_selection_text()

  if sql == "" then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end

  local ok, result = pcall(main.run, sql)

  if not ok then
    vim.notify(result, vim.log.levels.ERROR)
    return
  end

  output.show(result)
end

return M
