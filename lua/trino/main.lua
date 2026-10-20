local client = require("trino.client")
local csv = require("trino.csv")
local input = require("trino.input")
local output = require("trino.output")

local M = {}

local current

local function run_sql(sql, config)
  if current then
    vim.notify("Trino query already running (:Trino cancel)", vim.log.levels.WARN)
    return
  end

  current = client.query(sql, config, function(err, columns, rows, update_type)
    current = nil

    if err then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end

    if #columns == 0 then
      vim.notify("Trino " .. (update_type or "query") .. " done")
      return
    end

    output.show(csv.encode(columns, rows))
  end)
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

  run_sql(sql, config)
end

function M.run_input(config)
  vim.ui.input({ prompt = "Trino: " }, function(sql)
    if not sql or sql == "" then return end
    run_sql(sql, config)
  end)
end

function M.cancel()
  if not current then
    vim.notify("No Trino query running", vim.log.levels.WARN)
    return
  end

  current.cancel()
  current = nil
  vim.notify("Trino query cancelled")
end

return M
