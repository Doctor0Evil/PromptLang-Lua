-- File: modules/escape/vo_select.lua

local VDOM = require("modules.vdom.virtual")

local M = {}

--- Resolve a vo selector AST node to a list of VirtualObject.
-- node: { kind = "vo_selector", tag = "brush", metric = "IEI", min = 0.7 }
function M.resolve(node)
  local spec = {}

  if node.tag then
    spec.tag = node.tag
  elseif node.metric and node.min then
    spec.metric = node.metric
    spec.min = node.min
    spec.max = node.max or 1.0
  end

  return VDOM.query(spec)
end

return M
