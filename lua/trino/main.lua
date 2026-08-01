local M = {}

function M.run(sql)
  local result = vim.system(
    { os.getenv("HOME") .. "/.local/opt/custom_lib/.venv/bin/python", "-m", "custom_lib.query" },
    {
      stdin = sql,
      text = true,
    }
  ):wait()

  if result.code ~= 0 then
    error(result.stderr)
  end

  return vim.split(result.stdout, "\n", { plain = true })
end

return M
