-- File: modules/vdom/virtual.lua

local json = require("dkjson")      -- or any JSON lib
local rust_vdom = require("rust_vdom_bridge") -- host-provided

local VDOM = {}

-- in-memory cache: id -> plain Lua table mirroring Rust VirtualNode
local registry = {}

local VirtualObject = {}
VirtualObject.__index = VirtualObject

-- Internal: wrap a node table with the VirtualObject metatable
local function wrap(node)
  if not node then return nil end
  if getmetatable(node) == VirtualObject then
    return node
  end
  return setmetatable(node, VirtualObject)
end

--- Refresh local snapshot from Rust.
function VDOM.refresh_snapshot()
  local raw = rust_vdom.snapshot_json()
  local graph, _, err = json.decode(raw)
  if not graph then
    error("vdom snapshot decode error: " .. tostring(err))
  end

  registry = {}
  for id, node in pairs(graph.nodes or {}) do
    registry[id] = node
  end
end

--- Generic query wrapper: tag or metric range.
-- spec: { tag = "brush" } or { metric = "IEI", min = 0.7, max = 1.0 }
function VDOM.query(spec)
  local raw_spec = json.encode(spec)
  local raw = rust_vdom.query_json(raw_spec)
  local arr, _, err = json.decode(raw)
  if not arr then error("vdom query decode error: " .. tostring(err)) end

  local out = {}
  for _, snap in ipairs(arr) do
    local node = snap.node
    registry[node.id] = node
    table.insert(out, wrap(node))
  end
  return out
end

--- Direct lookup by id (if present in last snapshot/query).
function VDOM.get(id)
  return wrap(registry[id])
end

--- Annotate node in Rust and update cache.
-- annotations: { escape_targets = {...}, roles = {...} }
function VDOM.annotate(id, annotations)
  local ok = rust_vdom.annotate(id, json.encode(annotations))
  if ok and registry[id] then
    local node = registry[id]
    node.annotations = node.annotations or { escape_targets = {}, roles = {} }
    for _, t in ipairs(annotations.escape_targets or {}) do
      table.insert(node.annotations.escape_targets, t)
    end
    for _, r in ipairs(annotations.roles or {}) do
      table.insert(node.annotations.roles, r)
    end
  end
  return ok
end

VDOM.VirtualObject = VirtualObject

return VDOM
-- continuing modules/vdom/virtual.lua

--- Get node id.
function VirtualObject:id()
  return self.id
end

--- Node kind as string, e.g. "Canvas".
function VirtualObject:kind()
  return self.kind
end

--- Check if node has semantic tag.
function VirtualObject:has_tag(tag)
  for _, t in ipairs(self.semantic_tags or {}) do
    if t == tag then return true end
  end
  return false
end

--- Convenience IEI accessor.
function VirtualObject:iei()
  return (self.metrics and self.metrics.iei) or 0.0
end

--- Convenience TIS accessor.
function VirtualObject:tis()
  return (self.metrics and self.metrics.tis) or 0.0
end

--- Generic metric accessor.
function VirtualObject:metric(name)
  if not self.metrics then return nil end
  return self.metrics[name:lower()] or self.metrics[name] -- flexible
end

--- Event-derived richness.
function VirtualObject:event_density()
  local ep = self.event_profile or {}
  return ep.total_events or 0
end

--- Get roles (PromptLang roles like "brush").
function VirtualObject:roles()
  return (self.annotations and self.annotations.roles) or {}
end

--- Annotate from Lua side; forwards to VDOM.annotate.
function VirtualObject:add_role(role)
  local VDOM = require("modules.vdom.virtual")
  VDOM.annotate(self.id, { roles = { role } })
end

--- Children as VirtualObject list (from registry).
function VirtualObject:children()
  local VDOM = require("modules.vdom.virtual")
  local out = {}
  for _, cid in ipairs(self.children or {}) do
    local child = VDOM.get(cid)
    if child then table.insert(out, child) end
  end
  return out
end
