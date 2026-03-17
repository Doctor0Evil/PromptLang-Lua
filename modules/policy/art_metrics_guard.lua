-- File: modules/policy/art_metrics_guard.lua

local M = {}

function M.should_soft_block(env, artm)
  if env.ageband == "CHILD" and artm.ese < 0.5 then
    return true
  end
  return false
end

function M.pick_art_mode(env, artm)
  if artm.afi >= 0.7 and artm.edf >= 0.6 then
    return "HANDPAINT_HIGH_ENERGY"
  elseif artm.nsg >= 0.8 and artm.ese >= 0.7 then
    return "CALM_ABSTRACT"
  else
    return "DESCRIPTIVE_DEFAULT"
  end
end

return M
