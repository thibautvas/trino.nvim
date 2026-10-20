-- Trino client protocol over curl:
-- POST /v1/statement, then GET nextUri until it disappears.
-- Every request runs async, so the editor never blocks.

local M = {}

-- the protocol asks clients to retry these on any request
local RETRY_CODES = { [502] = true, [503] = true, [504] = true }
local MAX_RETRIES = 5

-- quote a value for a curl config file ("..." accepts \\ \" \n \r \t)
local function quote(s)
  s = tostring(s)
    :gsub("\\", "\\\\")
    :gsub('"', '\\"')
    :gsub("\n", "\\n")
    :gsub("\r", "\\r")
    :gsub("\t", "\\t")
  return '"' .. s .. '"'
end

-- options shared by every request, passed on stdin (curl -K -)
-- so credentials never show up in argv / ps
local function base_options(config)
  for _, key in ipairs({ "host", "port", "catalog" }) do
    if config[key] == nil then
      error("missing config field: " .. key, 0)
    end
  end

  local lines = {
    "silent",
    "show-error",
    'write-out = "\\n%{http_code}"',
  }

  local auth = config.auth or {}
  local auth_type = auth.type or "none"
  if auth_type == "basic" then
    if not auth.username or not auth.password then
      error("auth.basic requires username and password", 0)
    end
    table.insert(lines, "user = " .. quote(auth.username .. ":" .. auth.password))
  elseif auth_type == "jwt" then
    if not auth.jwt_token then
      error("auth.jwt requires jwt_token", 0)
    end
    table.insert(lines, "header = " .. quote("Authorization: Bearer " .. auth.jwt_token))
  elseif auth_type ~= "none" then
    error("unsupported auth.type: " .. tostring(auth_type), 0)
  end

  local verify = config.verify
  if verify == false then
    table.insert(lines, "insecure")
  elseif type(verify) == "string" then
    local path = vim.fn.expand(verify)
    if vim.fn.filereadable(path) ~= 1 then
      error("verify: CA bundle not readable: " .. path, 0)
    end
    table.insert(lines, "cacert = " .. quote(path))
  end

  local headers = vim.deepcopy(config.http_headers or {})
  headers["X-Trino-User"] = headers["X-Trino-User"] or auth.username or vim.env.USER or "trino.nvim"
  for name, value in pairs(headers) do
    table.insert(lines, "header = " .. quote(name .. ": " .. tostring(value)))
  end

  return lines
end

local function request(state, lines, attempt, cb)
  state.proc = vim.system(
    { "curl", "-K", "-" },
    { stdin = table.concat(lines, "\n") .. "\n", text = true },
    vim.schedule_wrap(function(res)
      state.proc = nil
      if state.cancelled then return end

      if res.code ~= 0 then
        return cb("connection error: " .. vim.trim(res.stderr))
      end

      local body, status = res.stdout:match("^(.*)\n(%d+)$")
      status = tonumber(status)

      if RETRY_CODES[status] and attempt < MAX_RETRIES then
        vim.defer_fn(function()
          if not state.cancelled then
            request(state, lines, attempt + 1, cb)
          end
        end, 100 * 2 ^ attempt)
        return
      end

      if status ~= 200 then
        body = vim.trim(body or "")
        return cb(string.format("HTTP %s%s", status or "?", body ~= "" and ": " .. body or ""))
      end

      local ok, resp = pcall(vim.json.decode, body, { luanil = { object = true } })
      if not ok then
        return cb("invalid JSON response: " .. resp)
      end

      cb(nil, resp)
    end)
  )
end

local function with_url(lines, url, extra)
  lines = vim.list_extend(vim.deepcopy(lines), extra or {})
  table.insert(lines, "url = " .. quote(url))
  return lines
end

-- on_done(err) or on_done(nil, columns, rows, update_type)
-- returns a handle with :cancel(), or nil if the query could not start
function M.query(sql, config, on_done)
  local ok, base = pcall(base_options, config)
  if not ok then
    on_done("config error: " .. base)
    return
  end

  local state = { rows = {}, cancelled = false }

  local function step(err, resp)
    if err then return on_done(err) end

    if resp.error then
      return on_done(string.format("query error: %s: %s", resp.error.errorName, resp.error.message))
    end

    if resp.columns and not state.columns then
      state.columns = vim.tbl_map(function(c) return c.name end, resp.columns)
    end
    vim.list_extend(state.rows, resp.data or {})

    state.next_uri = resp.nextUri
    if not state.next_uri then
      return on_done(nil, state.columns or {}, state.rows, resp.updateType)
    end

    request(state, with_url(base, state.next_uri), 0, step)
  end

  local url = string.format("%s://%s:%s/v1/statement", config.http_scheme or "https", config.host, config.port)
  local headers = { "header = " .. quote("X-Trino-Catalog: " .. config.catalog) }
  request(state, with_url(base, url, vim.list_extend(headers, { "data-binary = " .. quote(sql) })), 0, step)

  return {
    cancel = function()
      state.cancelled = true
      if state.proc then
        state.proc:kill("sigterm")
      end
      -- tell the server to stop working on the query
      if state.next_uri then
        vim.system({ "curl", "-K", "-" }, {
          stdin = table.concat(with_url(base, state.next_uri, { "request = DELETE" }), "\n") .. "\n",
        })
      end
    end,
  }
end

return M
