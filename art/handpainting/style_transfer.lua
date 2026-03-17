-- art/handpainting/style_transfer.lua
local M = {}

function M.apply(user_prompt, meta)
  local style = meta.style or "oil painting with expressive brushstrokes"
  return string.format(
    "Render \"%s\" as a %s, emphasizing color, motion, and abstraction.",
    user_prompt,
    style
  )
end

return M
