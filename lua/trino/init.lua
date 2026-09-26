local main = require("trino.main")

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

function M.run()
  main.run_visual(M.options)
end

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})

  local subcmds = { run = M.run }

  vim.api.nvim_create_user_command("Trino", function(args)
    local sub = args.fargs[1]
    local fn = subcmds[sub]
    if not fn then
      vim.notify("Trino unknown subcommand: " .. sub, vim.log.levels.ERROR)
      return
    end
    fn(args)
  end, {
    nargs = 1,
    range = true,
    force = true,
    complete = function()
      return vim.tbl_keys(subcmds)
    end,
  })
end

return M
