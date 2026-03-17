-- File: modules/metrics/runtime.lua

local json       = require("dkjson")
local rust_metrics = require("rust_metrics_bridge")
local ArtInputs = require("modules.metrics.art_inputs")

local Runtime = {}

function Runtime.compute_sync(analyzer_before, analyzer_after, sanitizer, events, history, age_band, node_metrics)
  local payload = ArtInputs.build(analyzer_before, analyzer_after, sanitizer, events, history, age_band, node_metrics)
  local raw = rust_metrics.compute_sync(json.encode(payload))
  return json.decode(raw) -- table with edf/nsg/afi/ese, others zeroed
end

return Runtime
