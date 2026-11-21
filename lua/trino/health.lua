local trino = require("trino")

local M = {}

local function check_nvim()
  vim.health.start("trino.nvim: nvim")

  if vim.fn.has("nvim-0.9") ~= 1 then
    vim.health.error("Neovim 0.9 or newer is required", {
      "vim.fn.jobstart is used to run the curl commands",
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

  local conn = trino.options.connection

  vim.health.info(string.format("url: %s://%s:%s", conn.http_scheme, conn.host, conn.port))
  vim.health.info(string.format("catalog: %s", conn.catalog or "none"))
  vim.health.info(string.format("auth: %s", (conn.auth or {}).type or "none"))
  vim.health.info(string.format("verify: %s", conn.verify))
end

function M.check()
  check_nvim()
  check_curl()
  check_config()
end

return M
