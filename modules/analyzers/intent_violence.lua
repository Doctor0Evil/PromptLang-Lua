-- File: modules/analyzers/intent_violence.lua

local M = {}

---@param env PromptLangEnvelope
---@return table|nil
function M.analyze(env)
  local text = env.text:lower()

  if text:find("kill", 1, true) or text:find("attack", 1, true) then
    return {
      tag         = "violence",
      score       = 0.9,
      spans       = {},
      recommended = "block_or_transform",
    }
  end

  return nil
end

return M
