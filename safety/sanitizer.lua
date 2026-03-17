-- safety/sanitizer.lua
local M = {}

local substitutions = {
  ["blood"]   = "crimson paint",
  ["gore"]    = "abstract splashes of red and black",
  ["torture"] = "intense emotional struggle expressed through color",
  ["kill"]    = "defeat in a symbolic, non‑violent sense",
  ["shoot"]   = "capture with a camera in a peaceful setting",
}

local function replace_words(prompt)
  local out = prompt
  for raw, repl in pairs(substitutions) do
    local pattern = "%f[%w]" .. raw .. "%f[%W]"
    out = out:gsub(pattern, repl)
  end
  return out
end

function M.transform(prompt, policy, scores)
  local sanitized = replace_words(prompt)
  sanitized = sanitized ..
    " (portray ideas symbolically with abstract shapes, light, and color; avoid literal harm or injury.)"
  return sanitized
end

return M
