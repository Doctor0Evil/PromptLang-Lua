-- art/knowledge_graph/main.lua
local model_loader = require("art.knowledge_graph.model_loader")

local M = {}
local _model

function M.init(cfg)
  _model = model_loader.load(cfg)
end

function M.generate(chatSessionId, user_prompt, meta)
  local graph = _model:build_graph(user_prompt, meta)
  return {
    type = "graph",
    source = "knowledge_graph",
    nodes = graph.nodes,
    edges = graph.edges,
  }
end

return M
