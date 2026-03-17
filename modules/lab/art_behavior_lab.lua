-- File: modules/lab/art_behavior_lab.lua

local json = require("dkjson")
local rust_lab = require("rust_lab_bridge")   -- host-provided shim to WASM
local VDOM = require("modules.vdom.virtual")

local Lab = {}

--- Record a single virtual event (from platform adapter).
-- ev: { node_id, event_kind, timestamp_ms, session_id, coordinated }
function Lab.record_event(ev)
  local payload = json.encode(ev)
  rust_lab.record_event(payload)
end

--- Recompute IEI/TIS/EID/PAR/AC in Rust and refresh local VDOM snapshot.
function Lab.recompute_metrics()
  rust_lab.recompute_metrics()
  VDOM.refresh_snapshot()
end

--- Convenience: batch record from raw DOM events mapped by adapter.
-- dom_event: { node_virtual_id, kind, session_id, coordinated }
function Lab.record_from_dom(dom_event)
  local ev = {
    node_id = dom_event.node_virtual_id,
    event_kind = dom_event.kind,               -- e.g. "Click"
    timestamp_ms = dom_event.timestamp_ms or os.time() * 1000,
    session_id = dom_event.session_id or "ambient",
    coordinated = dom_event.coordinated or false,
  }
  Lab.record_event(ev)
end

--- High-level: recompute and return sorted top-N expressive virtual objects.
-- returns: { VirtualObject, ... }
function Lab.top_expressive(tag, limit)
  limit = limit or 5
  Lab.recompute_metrics()
  local spec = {}
  if tag then spec.tag = tag end
  local nodes = VDOM.query(spec)

  table.sort(nodes, function(a, b)
    return a:iei() > b:iei()
  end)

  local out = {}
  for i = 1, math.min(limit, #nodes) do
    out[i] = nodes[i]
  end
  return out
end

return Lab
