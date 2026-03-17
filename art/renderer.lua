-- art/renderer.lua
local M = {}
local _cfg

function M.init(cfg)
  _cfg = cfg
end

function M.render_image(chatSessionId, art_obj)
  -- Host decides how to interpret this; here we return a neutral payload.
  return {
    chatSessionId = chatSessionId,
    kind = "image",
    url = art_obj.url,
    meta = art_obj.meta or {},
  }
end

function M.render_graph(chatSessionId, graph_obj)
  return {
    chatSessionId = chatSessionId,
    kind = "graph",
    nodes = graph_obj.nodes,
    edges = graph_obj.edges,
  }
end

function M.render_text(chatSessionId, text)
  return {
    chatSessionId = chatSessionId,
    kind = "text",
    text = text,
  }
end

return M
