-- File: modules/routing/virtual_art_routing.lua

local VDOM = require("modules.vdom.virtual")
local art_handpainting = require("art.handpainting.main")  -- existing
local art_descriptive  = require("art.descriptive.main")
local renderer         = require("art.renderer")

local M = {}

--- High-level: choose art module for a PromptLang block referencing virtual objects.
-- env: PromptLangEnvelope
-- block: parsed PromptLang block that includes a vo_selector node
function M.route_virtual_block(env, block)
  local selector = block.vo_selector
  local objects = require("modules.escape.vo_select").resolve(selector)

  if #objects == 0 then
    -- Fallback: descriptive art only.
    local art = art_descriptive.generate(env.chatSessionId, env.text, env.metadata)
    return renderer.renderimage(env.chatSessionId, art)
  end

  -- Take the "most expressive" node.
  table.sort(objects, function(a, b)
    return a:iei() > b:iei()
  end)

  local target = objects[1]

  if target:has_tag("brush") and target:iei() >= 0.7 and target:tis() >= 0.5 then
    -- Route to handpainting pipeline.
    local safeprompt = env.text  -- after safety flood-routing
    local art = art_handpainting.generate(env.chatSessionId, safeprompt, {
      style = "oil painting with expressive brushstrokes",
      virtual_target_id = target:id(),
      metrics = {
        iei = target:iei(),
        tis = target:tis(),
      },
    })
    return renderer.renderimage(env.chatSessionId, art)
  else
    local art = art_descriptive.generate(env.chatSessionId, env.text, env.metadata)
    return renderer.renderimage(env.chatSessionId, art)
  end
end

return M
