-- File: modules/styles/horror_render.lua

local Style = require("modules.styles.horror_style")

local M = {}

--- Build an engine-neutral horror style suffix, with optional hex tokens.
--- engine_caps: { allow_hex = true/false }
function M.to_engine_suffix(style, engine_caps)
  local base = Style.to_prompt_suffix(style)
  local p    = style.palette

  if engine_caps and engine_caps.allow_hex then
    -- Inline explicit hex hints for engines that support color tags.
    return string.format(
      "%s, bg %s, mid %s, accent %s, ground %s",
      base, p.bg, p.mid, p.accent, p.ground
    )
  else
    -- Describe colors textually without raw hex.
    return base .. ", muted teal-black sky, bruised earth tones, sickly pale highlights"
  end
end

return M
