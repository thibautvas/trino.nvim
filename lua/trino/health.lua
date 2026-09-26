local trino = require("trino")
local paths = require("trino.paths")

local M = {}

local function check_nvim()
  vim.health.start("trino.nvim: nvim")

  if vim.fn.has("nvim-0.10") ~= 1 then
    vim.health.error("Neovim 0.10 or newer is required", {
      "vim.system is used to run the python client",
    })
    return
  end

  vim.health.ok(string.format("nvim version: %s", vim.version()))
end

local function check_python()
  vim.health.start("trino.nvim: python")

  local python = paths.python()
  if not python then
    vim.health.error("No python3 in PATH or repo venv")
    return
  end

  vim.health.ok(string.format("interpreter: %s", python))

  return python
end

local function check_client(python)
  vim.health.start("trino.nvim: trino client")

  local trino_version = vim.fn.system({ python, "-c", "import trino; print(trino.__version__, end='')" })

  if vim.v.shell_error ~= 0 then
    vim.health.error("No trino in python lib")
    return
  end

  vim.health.ok(string.format("trino %s available", trino_version))
end

local function check_config()
  vim.health.start("trino.nvim: config")

  local config = trino.options
  vim.health.info(string.format(
    "%s://%s:%s, catalog %s, auth %s",
    config.http_scheme,
    config.host,
    config.port,
    config.catalog,
    (config.auth or {}).type or "none"
  ))
end

function M.check()
  check_nvim()
  local python = check_python()
  check_client(python)
  check_config()
end

return M
