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
