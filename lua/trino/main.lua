local M = {}

function M.run(sql, config)
  local payload = vim.json.encode({
    config = config,
    sql = sql,
  })

  local plugin_root = vim.fn.fnamemodify(
    debug.getinfo(1, "S").source:sub(2),
    ":h:h:h"
  )

  local result = vim.system(
    {
      "python3",
      plugin_root .. "/python/trino_query.py",
    },
    {
      stdin = payload,
      text = true,
    }
  ):wait()

  if result.code ~= 0 then
    error(result.stderr)
  end

  return vim.split(result.stdout, "\n", { plain = true })
end

return M
