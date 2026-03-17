-- art/descriptive/prompt_builder.lua
local utils = require("lib.utils")

local M = {}

function M.build(user_prompt, meta)
  local base_style = "highly detailed, hand‑painted, cinematic lighting"

  local safety_suffix = " safe, non‑violent, no gore, no explicit content"

  local refined = string.format(
    "Create a %s illustration based on: \"%s\".%s",
    base_style,
    user_prompt,
    safety_suffix
  )

  if not utils.has_balanced_brackets(refined) then
    refined = refined .. " (fix malformed markup)"
  end

  return refined
end

return M
