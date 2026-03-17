-- File: core/schema.lua

local M = {}

---@class PromptLangEnvelope
---@field user_id string
---@field claimed_age number|nil
---@field age_band string|nil
---@field age_evidence string|nil
---@field platform_id string
---@field text string
---@field metadata table
---@field context table

function M.make_envelope(env)
  return {
    user_id      = env.user_id,
    claimed_age  = env.claimed_age,
    age_band     = nil,
    age_evidence = nil,
    platform_id  = env.platform_id,
    text         = env.text or "",
    metadata     = env.metadata or {},
    context      = {},
  }
end

return M
