-- File: modules/routing/metric_aware_routing.lua

local Lab = require("modules.lab.art_behavior_lab")
local VDOM = require("modules.vdom.virtual")
local art_descriptive  = require("art.descriptive.main")
local art_handpainting = require("art.handpainting.main")
local art_kg           = require("art.knowledgegraph.main")
local renderer         = require("art.renderer")

local M = {}

--- Decide art mode for a given PromptLang envelope, using IEI/TIS of target.
-- env: PromptLangEnvelope
-- selector: vo_selector or nil
function M.route_with_metrics(env, selector)
  local target
  if selector then
    local objs = require("modules.escape.vo_select").resolve(selector)
    if #objs > 0 then
      target = objs[1]
    end
  end

  Lab.recompute_metrics()

  if target then
    -- Refresh target from latest snapshot if possible.
    target = VDOM.get(target:id()) or target
    local iei = target:iei()
    local tis = target:tis()

    if iei >= 0.7 and tis >= 0.5 and target:has_tag("brush") then
      local art = art_handpainting.generate(env.chatSessionId, env.text, {
        style = "expressive brushwork, abstract motion",
        virtual_target_id = target:id(),
        metrics = { iei = iei, tis = tis },
      })
      return renderer.renderimage(env.chatSessionId, art)
    elseif iei >= 0.5 and target:has_tag("graphable") then
      local kg = art_kg.generate(env.chatSessionId, env.text, {
        virtual_target_id = target:id(),
        metrics = { iei = iei, tis = tis },
      })
      return renderer.rendergraph(env.chatSessionId, kg)
    end
  end

  local art = art_descriptive.generate(env.chatSessionId, env.text, env.metadata)
  return renderer.renderimage(env.chatSessionId, art)
end

return M
