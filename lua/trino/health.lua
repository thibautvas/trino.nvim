local trino = require("trino")

local M = {}

local function check_nvim()
  vim.health.start("trino.nvim: nvim")

  if vim.fn.has("nvim-0.10") ~= 1 then
    vim.health.error("Neovim 0.10 or newer is required", {
      "vim.system is used to run the curl commands",
    })
    return
  end

  vim.health.ok(string.format("nvim version: %s", vim.version()))
end

local function check_curl()
  vim.health.start("trino.nvim: curl")

  if vim.fn.executable("curl") ~= 1 then
    vim.health.error("curl not found in PATH", {
      "curl is used to send the http requests",
    })
    return
  end

  local curlv = vim.fn.system({ "curl", "--version" }):match("(%d+%.%d+%.%d+)")
  vim.health.ok(string.format("curl version: %s", curlv))
end

local function check_config()
  vim.health.start("trino.nvim: config")

  local config = trino.options

  vim.health.info(string.format("url: %s://%s:%s", config.http_scheme, config.host, config.port))
  vim.health.info(string.format("catalog: %s", config.catalog or "none"))
  vim.health.info(string.format("auth: %s", (config.auth or {}).type or "none"))
  vim.health.info(string.format("verify: %s", config.verify))
end

function M.check()
  check_nvim()
  check_curl()
  check_config()
end

return M
