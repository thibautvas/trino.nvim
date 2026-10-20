local M = {}

-- shortest representation that round-trips, like python's repr
local function format_number(n)
  if n == math.floor(n) and math.abs(n) < 2 ^ 53 then
    return string.format("%d", n)
  end
  for _, precision in ipairs({ 15, 16, 17 }) do
    local s = string.format("%." .. precision .. "g", n)
    if tonumber(s) == n then
      return s
    end
  end
  return tostring(n)
end

local function format_value(value)
  if value == nil or value == vim.NIL then
    return ""
  elseif type(value) == "number" then
    return format_number(value)
  elseif type(value) == "table" then
    -- arrays, maps and rows
    return vim.json.encode(value)
  end
  return tostring(value)
end

local function format_field(value)
  local s = format_value(value)
  if s:find('[,"\r\n]') then
    return '"' .. s:gsub('"', '""') .. '"'
  end
  return s
end

local function format_row(values, ncols)
  local fields = {}
  for i = 1, ncols do
    fields[i] = format_field(values[i])
  end
  return table.concat(fields, ",")
end

-- returns buffer lines; a quoted field with a newline spans several lines
function M.encode(columns, rows)
  local out = { format_row(columns, #columns) }
  for _, row in ipairs(rows) do
    vim.list_extend(out, vim.split(format_row(row, #columns), "\n", { plain = true }))
  end
  return out
end

return M
