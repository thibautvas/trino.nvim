local input = require("trino.input")
local main = require("trino.main")
local output = require("trino.output")

local M = {}

M.defaults = {
  host = nil,
  port = 8080,
  catalog = nil,
  http_headers = { ["X-Trino-User"] = nil },
  http_scheme = "https",
  auth = {
    type = "basic",
    username = nil,
    password = nil,
  },
  verify = false,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

function M.run_visual()
  local sql = input.get_selection_text()

  if sql == "" then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end

  local ok, result = pcall(main.run, sql, M.options)

  if not ok then
    vim.notify(result, vim.log.levels.ERROR)
    return
  end

  output.show(result)
end

return M
