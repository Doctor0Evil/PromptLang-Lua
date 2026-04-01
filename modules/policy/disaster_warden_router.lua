-- modules/policy/disaster_warden_router.lua
local AgeGate = require("modules.agegate.agegate")

local M = {}

--- Decide whether to route this prompt into God’s Image: Disaster Warden.
-- @param env table  -- PromptLang envelope; must include ageband
-- @param artmetrics table -- Rust ArtBehaviorMetrics snapshot for this node/session
-- @return string|nil style_id
function M.pick_style(env, artmetrics)
  if not artmetrics then
    return nil
  end

  local ageband = env.ageband or AgeGate.BANDS.ADULT
  local dwf = artmetrics.dwf or 0.0
  local gsi = artmetrics.gsi or 0.0
  local ecc = artmetrics.ecc or 0.0
  local cri = artmetrics.cri or 0.0
  local edf = artmetrics.edf or 0.0
  local ese = artmetrics.ese or 1.0

  -- Hard age-gate: never use Disaster Warden for children / young teens.
  if ageband == AgeGate.BANDS.CHILD or ageband == AgeGate.BANDS.YOUNGTEEN then
    return nil
  end

  -- Require meaningful ecological and chrome signals.
  if dwf < 0.6 then
    return nil
  end
  if gsi < 0.4 then
    return nil
  end
  if ecc < 0.5 then
    return nil
  end
  if cri < 0.5 then
    return nil
  end

  -- Respect the Expressive Safety Envelope: only if envelope is reasonably open.
  if ese < 0.4 then
    return nil
  end

  -- Avoid pairing extreme destructive flux with this style for borderline users.
  if edf > 0.9 and ese < 0.7 then
    return nil
  end

  return "disaster_warden"
end

return M
