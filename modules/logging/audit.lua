-- File: modules/logging/audit.lua

local M = {}

local current_config = {
  enabled = true,
}

function M.init(cfg)
  current_config.enabled = cfg.enabled ~= false
end

---@param env PromptLangEnvelope
---@param result table
function M.record(env, result)
  if not current_config.enabled then
    return
  end

  -- TODO: Replace with structured logging (file, stdout, remote sink, etc.)
  -- For now this is a stub.
end

return M
