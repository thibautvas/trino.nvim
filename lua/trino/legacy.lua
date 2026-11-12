local M = {}

-- vim.system wrapper built on vim.fn.jobstart
function M.system(cmd, opts, on_exit)
  if vim.system then
    return vim.system(cmd, opts, on_exit)
  end
  local out, err = {}, {}
  local job = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data) out = data end,
    on_stderr = function(_, data) err = data end,
    on_exit = function(_, code)
      if on_exit then
        on_exit({ code = code, stdout = table.concat(out, "\n"), stderr = table.concat(err, "\n") })
      end
    end,
  })
  if job <= 0 then
    if on_exit then
      vim.schedule(function()
        on_exit({ code = 127, stdout = "", stderr = "failed to start " .. cmd[1] })
      end)
    end
    return { kill = function() end }
  end
  if opts and opts.stdin then
    vim.fn.chansend(job, opts.stdin)
  end
  vim.fn.chanclose(job, "stdin")
  return { kill = function() pcall(vim.fn.jobstop, job) end }
end

-- vim.fn.getregion wrapper
function M.getregion(pos1, pos2, regtype)
  if vim.fn.exists("*getregion") == 1 then
    return vim.fn.getregion(pos1, pos2, { type = regtype })
  end

  local buf = pos1[1] == 0 and 0 or pos1[1]
  local s, e = { pos1[2], pos1[3] }, { pos2[2], pos2[3] }
  if s[1] > e[1] or (s[1] == e[1] and s[2] > e[2]) then
    s, e = e, s
  end

  local lines = vim.api.nvim_buf_get_lines(buf, s[1] - 1, e[1], false)

  if regtype == "V" then
    return lines
  end

  if regtype == "v" then
    local last = lines[#lines]
    local ecol = math.min(e[2], #last)
    if ecol > 0 then
      ecol = ecol + vim.str_utf_end(last, ecol)
    end
    lines[#lines] = last:sub(1, ecol)
    lines[1] = lines[1]:sub(s[2])
    return lines
  end

  local function vcol(lnum, col)
    return vim.fn.virtcol({ lnum, col })
  end
  local v1, v2 = vcol(s[1], s[2]), vcol(e[1], e[2])
  if v1 > v2 then
    v1, v2 = v2, v1
  end
  local out = {}
  for i, line in ipairs(lines) do
    local lnum = s[1] + i - 1
    local c1 = vim.fn.virtcol2col(0, lnum, v1)
    local c2 = vim.fn.virtcol2col(0, lnum, v2)
    if c2 > 0 then
      c2 = c2 + vim.str_utf_end(line, c2)
    end
    out[i] = c1 > 0 and line:sub(c1, c2) or ""
  end
  return out
end

return M
