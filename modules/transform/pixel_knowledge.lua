-- File: modules/transform/pixel_knowledge.lua

local M = {}

---@param env PromptLangEnvelope
---@param ast table
---@param signals table
---@return table pixel_graph
function M.build(env, ast, signals)
  return {
    nodes = {
      { id = "scene",    type = "canvas", color = "#202020" },
      { id = "emotion",  type = "cloud",  color = "#ff6699" },
      { id = "contrast", type = "shape",  color = "#3366ff" },
    },
    edges = {
      { from = "scene",   to = "emotion",  relation = "contains" },
      { from = "scene",   to = "contrast", relation = "contains" },
      { from = "emotion", to = "contrast", relation = "blends_with" },
    },
  }
end

return M
