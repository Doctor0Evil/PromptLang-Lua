local DisasterWardenRouter = require("modules.policy.disaster_warden_router")

local M = {}

--- Decide final art mode and style.
-- @param env table
-- @param plan table   -- existing decision from PolicyMatrix (TRANSFORMTOART, etc.)
-- @param artmetrics table -- Rust ArtBehaviorMetrics for this prompt
-- @return table plan  -- augmented with style_id if applicable
function M.apply_style(env, plan, artmetrics)
  if plan.decision ~= "TRANSFORM_TO_ART" then
    return plan
  end

  -- Try Disaster Warden first.
  local style = DisasterWardenRouter.pick_style(env, artmetrics)
  if style == "disaster_warden" then
    plan.style_id = "disaster_warden"
    plan.art_engine = "arthandpainting"  -- or a dedicated chrome movie engine later
    return plan
  end

  -- Fallback to existing styles (machine-canyon, calm-abstract, etc.).
  -- ...
  return plan
end

return M
