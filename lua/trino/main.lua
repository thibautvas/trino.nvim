local client = require("trino.client")
local csv = require("trino.csv")
local input = require("trino.input")
local output = require("trino.output")
local progress = require("trino.progress")

local M = {}

local current

function M.run_sql(config, query)
  if current then
    vim.notify("Trino query already running", vim.log.levels.WARN)
    return
  end

  progress.start()

  local conn = config.connection
  current = client.run(conn, query, progress.update, function(err, columns, rows, update_type)
    current = nil

    if err then
      progress.finish(false)
      vim.notify(err, vim.log.levels.ERROR)
      return
    end

    progress.finish(true)

    if #columns == 0 then
      vim.notify("Trino " .. (update_type or "query") .. " done")
      return
    end

    output.show(csv.encode(columns, rows), {
      filetype = "csv",
      open_cmd = config.output.open_cmd,
    })
  end)
end

function M.run_visual(config)
  local query = input.get_text()

  if vim.fn.mode():match("[vV\22]") then
    vim.cmd("normal! \27")
  end

  if query == "" then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end

  M.run_sql(config, query)
end

function M.run_input(config)
  vim.ui.input({ prompt = "Trino: " }, function(query)
    if not query or query == "" then return end
    M.run_sql(config, query)
  end)
end

function M.cancel()
  if not current then
    vim.notify("No Trino query running", vim.log.levels.WARN)
    return
  end

  current.cancel()
  current = nil
  progress.finish(false, "cancelled")
  vim.notify("Trino query cancelled")
end

progress.on_cancel(M.cancel)

return M
