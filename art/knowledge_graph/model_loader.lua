-- art/knowledge_graph/model_loader.lua
local M = {}

local GraphModel = {}
GraphModel.__index = GraphModel

function GraphModel:build_graph(prompt, meta)
  -- Placeholder: convert textual scene to minimal graph
  return {
    nodes = {
      { id = "scene", label = prompt },
    },
    edges = {},
  }
end

function M.load(cfg)
  local self = setmetatable({}, GraphModel)
  return self
end

return M
