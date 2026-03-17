-- File: modules/age_gate/age_gate.lua

local M = {}

local BANDS = {
  CHILD       = "CHILD",
  YOUNG_TEEN  = "YOUNG_TEEN",
  TEEN        = "TEEN",
  ADULT       = "ADULT",
}

local function band_from_age(age)
  if not age then
    return nil
  end
  if age < 13 then
    return BANDS.CHILD
  elseif age < 16 then
    return BANDS.YOUNG_TEEN
  elseif age < 18 then
    return BANDS.TEEN
  else
    return BANDS.ADULT
  end
end

---@param env PromptLangEnvelope
---@return PromptLangEnvelope
function M.annotate_age(env)
  local age_band = band_from_age(env.claimed_age)
  env.age_band = age_band or env.age_band
  env.age_evidence = env.age_evidence or "self_reported"
  return env
end

M.BANDS = BANDS

return M
