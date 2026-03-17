local AgeGate = require("modules.age_gate.age_gate")

local M = {}

local DEFAULT_POLICY = {
  [AgeGate.BANDS.CHILD] = {
    violence = "TRANSFORM_TO_ART",
    sexual   = "DENY",
    selfharm = "TRANSFORM_TO_ART",
  },
  [AgeGate.BANDS.TEEN] = {
    violence = "ABSTRACTIFY",
    sexual   = "DENY",
    selfharm = "TRANSFORM_TO_ART",
  },
  [AgeGate.BANDS.ADULT] = {
    violence = "ABSTRACTIFY",
    sexual   = "ABSTRACTIFY",
    selfharm = "TRANSFORM_TO_ART",
  },
}

---@param env PromptLangEnvelope
---@param signals table
---@return table
function M.decide(env, signals)
  local band = env.age_band or AgeGate.BANDS.ADULT
  local table_for_band = DEFAULT_POLICY[band] or {}

  local strongest = nil

  for _, sig in ipairs(signals) do
    if not strongest or (sig.score or 0) > (strongest.score or 0) then
      strongest = sig
    end
  end

  if not strongest then
    return {
      decision             = "ALLOW",
      generate_pixel_graph = false,
      handpaint_style      = nil,
      image_backend        = nil,
      reason               = "no_risk_detected",
    }
  end

  local category_policy = table_for_band[strongest.tag]

  if category_policy == "DENY" then
    return {
      decision = "DENY",
      reason   = "policy_violation_" .. strongest.tag,
      message  = "This content is not allowed for your age and settings.",
    }
  end

  local decision = category_policy or "TRANSFORM_TO_ART"

  return {
    decision             = decision,
    generate_pixel_graph = true,
    handpaint_style      = "soft_painterly",
    image_backend        = "default",
    reason               = "intent_detected_" .. strongest.tag,
  }
end

return M
