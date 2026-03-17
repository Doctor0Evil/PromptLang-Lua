-- lib/utils.lua
local utils = {}

function utils.deep_merge(a, b)
  if type(b) ~= "table" then return a end
  local res = {}
  for k, v in pairs(a or {}) do res[k] = v end
  for k, v in pairs(b) do
    if type(v) == "table" and type(res[k]) == "table" then
      res[k] = utils.deep_merge(res[k], v)
    else
      res[k] = v
    end
  end
  return res
end

function utils.log(level, msg)
  -- plug in host logger here if needed
  io.stderr:write("[" .. level .. "] " .. msg .. "\n")
end

function utils.contains_word(str, word)
  local pattern = "%f[%w]" .. word .. "%f[%W]"
  return str:lower():match(pattern:lower()) ~= nil
end

-- example “balanced brackets” check for prompt sanity
function utils.has_balanced_brackets(str)
  local stack = {}
  for c in str:gmatch(".") do
    if c == "[" or c == "(" or c == "{" then
      table.insert(stack, c)
    elseif c == "]" or c == ")" or c == "}" then
      local last = table.remove(stack)
      if not last then return false end
    end
  end
  return #stack == 0
end

return utils
