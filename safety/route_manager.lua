-- safety/route_manager.lua
local M = {}

function M.choose_route(prompt, meta, scores)
  if scores.violence > 0.0 then
    return "handpainting"
  end
  if prompt:lower():find("map") or prompt:lower():find("relationships") then
    return "knowledge_graph"
  end
  return "descriptive"
end

return M
