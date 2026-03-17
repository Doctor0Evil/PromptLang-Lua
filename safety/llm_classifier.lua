-- safety/llm_classifier.lua
local M = {}

function M.score(prompt, cfg)
  local lower = prompt:lower()
  local violence = 0.0
  local adult    = 0.0

  if lower:find("kill") or lower:find("shoot") then
    violence = 0.9
  end
  if lower:find("nsfw") or lower:find("explicit") then
    adult = 0.9
  end

  return {
    violence = violence,
    adult    = adult,
  }
end

return M
