-- PromptLang-Lua Repository
-- File: core/entry.lua

local Router      = require("core.router")
local Schema      = require("core.schema")
local Policy      = require("modules.policy.policy_matrix")
local AgeGate     = require("modules.age_gate.age_gate")
local Escape      = require("modules.escape.escape_sequences")
local ArtRewriter = require("modules.transform.art_rewriter")
local PixelKG     = require("modules.transform.pixel_knowledge")
local Handpaint   = require("modules.transform.handpaint")
local Audit       = require("modules.logging.audit")

local M = {}

---@class PromptLangConfig
---@field policies table
---@field analyzers table
---@field image_backends table
---@field logging table

---@class PromptLangEnv
---@field user_id string
---@field claimed_age number|nil
---@field platform_id string
---@field text string
---@field metadata table|nil

local state = {
  config = nil,
}

function M.init(config)
  state.config = config or {}
  Audit.init(state.config.logging or {})
  Router.init({
    analyzers = state.config.analyzers or {},
    policy    = Policy,
    age_gate  = AgeGate,
    escape    = Escape,
    art       = ArtRewriter,
    pixelkg   = PixelKG,
    handpaint = Handpaint,
  })
end

---@param env PromptLangEnv
---@return table result
function M.handle_message(env)
  assert(state.config, "PromptLang-Lua not initialized. Call init() first.")
  local envelope = Schema.make_envelope(env)
  local result   = Router.route(envelope)

  Audit.record(envelope, result)
  return result
end

return M
