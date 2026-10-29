local M = {}

local SOURCE = "trino.nvim"
local has_progress = vim.fn.has("nvim-0.12") == 1

local state = { active = false, id = nil, text = "", pct = nil }

local function human(n, suffix)
  local units = { "", "K", "M", "G", "T" }
  local i = 1
  while n >= 1000 and i < #units do
    n = n / 1000
    i = i + 1
  end
  return (i == 1 and "%d%s%s" or "%.1f%s%s"):format(n, units[i], suffix or "")
end

local function percent(stats)
  if not stats.scheduled then return nil end
  if stats.progressPercentage then
    return math.floor(stats.progressPercentage)
  end
  local total = stats.totalSplits or 0
  if total > 0 then
    return math.floor(100 * (stats.completedSplits or 0) / total)
  end
end

local function format(stats)
  local parts = { stats.state or "?" }

  if (stats.totalSplits or 0) > 0 then
    table.insert(parts, ("%d/%d splits"):format(stats.completedSplits or 0, stats.totalSplits))
  end
  if (stats.processedRows or 0) > 0 then
    table.insert(parts, human(stats.processedRows) .. " rows")
    table.insert(parts, human(stats.processedBytes or 0, "B"))
  end
  if stats.elapsedTimeMillis then
    table.insert(parts, ("%.1fs"):format(stats.elapsedTimeMillis / 1000))
  end

  return table.concat(parts, " · ")
end

local function echo(text, status, pct)
  state.text = text
  state.pct = pct
  vim.cmd.redrawstatus()
  if has_progress then
    local id = vim.api.nvim_echo({ { text } }, false, {
      id = state.id,
      kind = "progress",
      source = SOURCE,
      title = "Trino",
      status = status,
      percent = pct,
    })
    state.id = id ~= -1 and id or nil
  end
end

function M.start()
  state.active = true
  state.id = nil
  echo("QUEUED", "running")
end

function M.update(stats)
  if not state.active then return end
  echo(format(stats), "running", percent(stats))
end

function M.finish(ok, text)
  if not state.active then return end
  state.active = false
  echo(text or (ok and "done" or "failed"), ok and "success" or "failed", ok and 100 or nil)
end

function M.on_cancel(fn)
  if not has_progress then return end
  vim.api.nvim_create_autocmd("Progress", {
    group = vim.api.nvim_create_augroup("trino.progress", { clear = true }),
    pattern = SOURCE,
    callback = function(ev)
      if state.active and ev.data.status == "cancel" and ev.data.id == state.id then
        fn()
      end
    end,
  })
end

function M.status()
  if not state.active then return "" end
  return "Trino " .. (state.pct and (state.pct .. "% ") or "") .. state.text
end

return M
