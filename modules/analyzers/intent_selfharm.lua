-- File: modules/analyzers/intent_selfharm.lua

local M = {}

---@param env PromptLangEnvelope
---@return table|nil
function M.analyze(env)
  local text = env.text:lower()

  if text:find("hurt myself", 1, true) or text:find("end my life", 1, true) then
    return {
      tag         = "selfharm",
      score       = 0.95,
      spans       = {},
      recommended = "block_or_transform",
    }
  end

  return nil
end

return M
