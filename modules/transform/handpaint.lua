-- File: modules/transform/handpaint.lua

local M = {}

---@param env PromptLangEnvelope
---@param ast table
---@param style string
---@return string
function M.render(env, ast, style)
  if style == "soft_painterly" then
    return "In gentle, layered strokes, the scene unfolds as a tapestry of shifting colors and soft edges, hinting at feeling rather than explicit events."
  end

  return "A scene rendered in expressive, handpainted textures and vivid yet abstract forms."
end

return M
