-- modules/routing/metric_aware_policy.lua
local Metrics = require("modules.metrics")
local Policy  = require("modules.policy.policymatrix")

local M = {}

function M.decide(env, signals, history, rust_metrics)
  local plan = Policy.decide(env, signals)
  if plan.decision == "DENY" then
    return plan
  end

  local analyzer = -- fold signals into a simple record e.g. max destructive_intent
  local ese = rust_metrics and rust_metrics.ese
             or Metrics.compute_ese_local(env, analyzer, history)

  if ese < 0.3 then
    -- Envelope too tight: prefer abstractify or deny instead of rich art.
    if plan.decision == "TRANSFORMTOART" then
      plan.decision = "ABSTRACTIFY"
    end
    plan.imageallowed = false
  end

  return plan
end

return M
