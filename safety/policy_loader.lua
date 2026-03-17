-- safety/policy_loader.lua
local M = {}

function M.load(cfg)
  -- Could be loaded from external JSON/YAML file.
  return {
    banned_words = {
      "blood", "gore", "torture", "execute", "mutilation",
    },
  }
end

function M.check(policy, prompt)
  local hits = {}
  local lower = prompt:lower()
  for _, word in ipairs(policy.banned_words or {}) do
    if lower:find(word, 1, true) then
      table.insert(hits, word)
    end
  end
  return { has_hits = #hits > 0, words = hits }
end

return M
