-- PromptLang-Lua
-- Pixel knowledge-graph structures and utilities

local PixelKG = {}

local function node(id, kind, label, weight)
  return {
    id = id,
    kind = kind,
    label = label,
    weight = weight or 1.0
  }
end

local function edge(from_id, to_id, relation, weight)
  return {
    from = from_id,
    to = to_id,
    relation = relation,
    weight = weight or 1.0
  }
end

function PixelKG.derive_basic_nodes(subject, mood, style_desc)
  subject = tostring(subject or "subject")
  mood = tostring(mood or "neutral")
  style_desc = tostring(style_desc or "generic style")

  local nodes = {}
  local edges = {}

  local subject_id = "n_subject"
  local mood_id = "n_mood"
  local style_id = "n_style"

  table.insert(nodes, node(subject_id, "subject", subject, 1.5))
  table.insert(nodes, node(mood_id, "mood", mood, 1.0))
  table.insert(nodes, node(style_id, "style", style_desc, 1.0))

  table.insert(edges, edge(subject_id, mood_id, "evokes", 0.8))
  table.insert(edges, edge(subject_id, style_id, "rendered_as", 0.9))
  table.insert(edges, edge(mood_id, style_id, "harmonizes_with", 0.6))

  return {
    nodes = nodes,
    edges = edges
  }
end

function PixelKG.to_bracket_kg_expression(graph)
  if not graph or type(graph) ~= "table" then
    return "[kg::none]"
  end
  local nodes = graph.nodes or {}
  local edges = graph.edges or {}

  local parts = {}

  local node_parts = {}
  for _, n in ipairs(nodes) do
    local id = n.id or "n"
    local kind = n.kind or "k"
    local label = n.label or ""
    local weight = n.weight or 1.0
    table.insert(node_parts, table.concat({ id, kind, label, tostring(weight) }, "|"))
  end
  local nodes_str = table.concat(node_parts, ",")

  local edge_parts = {}
  for _, e in ipairs(edges) do
    local from = e.from or ""
    local to = e.to or ""
    local rel = e.relation or ""
    local weight = e.weight or 1.0
    table.insert(edge_parts, table.concat({ from, to, rel, tostring(weight) }, "|"))
  end
  local edges_str = table.concat(edge_parts, ",")

  table.insert(parts, "nodes=" .. nodes_str)
  table.insert(parts, "edges=" .. edges_str)

  return "[kg::" .. table.concat(parts, ";") .. "]"
end

function PixelKG.merge(graph_a, graph_b)
  local result = { nodes = {}, edges = {} }
  local index_nodes = {}
  local index_edges = {}

  local function add_node(n)
    if n.id and not index_nodes[n.id] then
      index_nodes[n.id] = true
      table.insert(result.nodes, {
        id = n.id,
        kind = n.kind,
        label = n.label,
        weight = n.weight
      })
    end
  end

  local function edge_key(e)
    return (e.from or "") .. ">" .. (e.to or "") .. "|" .. (e.relation or "")
  end

  local function add_edge(e)
    local k = edge_key(e)
    if k ~= ">" and not index_edges[k] then
      index_edges[k] = true
      table.insert(result.edges, {
        from = e.from,
        to = e.to,
        relation = e.relation,
        weight = e.weight
      })
    end
  end

  if graph_a and graph_a.nodes then
    for _, n in ipairs(graph_a.nodes) do
      add_node(n)
    end
  end
  if graph_b and graph_b.nodes then
    for _, n in ipairs(graph_b.nodes) do
      add_node(n)
    end
  end
  if graph_a and graph_a.edges then
    for _, e in ipairs(graph_a.edges) do
      add_edge(e)
    end
  end
  if graph_b and graph_b.edges then
    for _, e in ipairs(graph_b.edges) do
      add_edge(e)
    end
  end

  return result
end

return PixelKG
