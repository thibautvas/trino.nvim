local input = require("trino.input")
local main = require("trino.main")
local output = require("trino.output")

local M = {}

function M.run_visual()
  local sql = input.get_selection_text()

  if vim.fn.mode():match("[vV\22]") then
    vim.cmd("normal! \27")
  end

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

  local subcmds = {}
  subcmds.run = M.run_visual
  subcmds.venv = require("trino.venv").build

  vim.api.nvim_create_user_command("Trino", function(cmd)
    local sub = cmd.args
    if not subcmds[sub] then
      vim.notify("Trino unknown subcommand: " .. sub, vim.log.levels.ERROR)
      return
    end
    subcmds[sub]()
  end, {
    nargs = 1,
    force = true,
    complete = function()
      return vim.tbl_keys(subcmds)
    end,
  })
end

return M
