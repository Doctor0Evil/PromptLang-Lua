-- main.lua
local config_default = require("config.default")
local config_schema  = require("config.schema")
local utils          = require("lib.utils")

local safety_filter  = require("safety.filter")
local age_gate       = require("safety_age_gate")

local art_descriptive     = require("art.descriptive.main")
local art_knowledge_graph = require("art.knowledge_graph.main")
local art_handpainting    = require("art.handpainting.main")
local renderer            = require("art.renderer")

local M = {}

-- internal state
local _cfg = nil

local function load_config(user_cfg)
  local merged = utils.deep_merge(config_default, user_cfg or {})
  config_schema.validate(merged)
  return merged
end

function M.init(user_cfg)
  _cfg = load_config(user_cfg)
  safety_filter.init(_cfg)
  art_descriptive.init(_cfg)
  art_knowledge_graph.init(_cfg)
  art_handpainting.init(_cfg)
  renderer.init(_cfg)
  return true
end

-- high-level routing for the host
function M.processInput(chatSessionId, userInput, meta)
  meta = meta or {}
  if age_gate.is_blocked(meta) then
    return renderer.render_text(chatSessionId,
      "Image generation is not available for this user profile.")
  end

  -- Safety “flood‑routing” interception
  local safe_prompt, route = safety_filter.intercept(userInput, meta)

  if route == "descriptive" then
    local art = art_descriptive.generate(chatSessionId, safe_prompt, meta)
    return renderer.render_image(chatSessionId, art)
  elseif route == "knowledge_graph" then
    local kg = art_knowledge_graph.generate(chatSessionId, safe_prompt, meta)
    return renderer.render_graph(chatSessionId, kg)
  elseif route == "handpainting" then
    local art = art_handpainting.generate(chatSessionId, safe_prompt, meta)
    return renderer.render_image(chatSessionId, art)
  else
    -- Fallback: describe instead of draw
    return renderer.render_text(chatSessionId,
      "Prompt was sanitized to: " .. safe_prompt)
  end
end

-- generic hook for non‑chat actions
function M.handleRequest(requestType, params)
  if requestType == "health_check" then
    return { ok = true, config_loaded = _cfg ~= nil }
  end
  -- extend with more request types as needed
  return { ok = false, error = "Unknown requestType: " .. tostring(requestType) }
end

return M
