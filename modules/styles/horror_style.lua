-- PromptLang-Lua Repository
-- File: modules/styles/horror_style.lua

local M = {}

local function clamp01(x)
  if x < 0.0 then return 0.0 end
  if x > 1.0 then return 1.0 end
  return x
end

local function validate_palette(p)
  if type(p) ~= "table" then return nil, "palette must be table" end
  -- Simple hex sanity: "#RRGGBB"
  local function ok_hex(s)
    return type(s) == "string" and s:match("^#%x%x%x%x%x%x$")
  end
  if not ok_hex(p.bg) then return nil, "invalid bg hex" end
  if not ok_hex(p.mid) then return nil, "invalid mid hex" end
  if not ok_hex(p.accent) then return nil, "invalid accent hex" end
  if not ok_hex(p.ground) then return nil, "invalid ground hex" end
  return {
    bg = p.bg,
    mid = p.mid,
    accent = p.accent,
    ground = p.ground,
  }
end

--- Decode a HorrorStyleDef from a plain Lua table (e.g. JSON-decoded).
--- Returns style, err.
function M.decode(tbl)
  if type(tbl) ~= "table" then
    return nil, "style must be table"
  end
  local metrics = tbl.metrics or {}
  local palette_raw = tbl.palette or {}
  local palette, perr = validate_palette(palette_raw)
  if not palette then return nil, perr end

  local style = {
    id      = tbl.id or "unknown",
    version = tbl.version or 1,
    family  = tbl.family or "Other",
    metrics = {
      wmp = clamp01(metrics.wmp or 0.0),
      nsg = clamp01(metrics.nsg or 0.5),
      tdi = clamp01(metrics.tdi or 0.0),
      snf = clamp01(metrics.snf or 0.0),
      fsm = clamp01(metrics.fsm or 0.0),
    },
    palette   = palette,
    art_string = tbl.art_string or "",
    seeds = {
      numeric_seed   = tbl.seeds and tbl.seeds.numeric_seed or nil,
      engine_style_tag = tbl.seeds and tbl.seeds.engine_style_tag or nil,
      ref_image_id   = tbl.seeds and tbl.seeds.ref_image_id or nil,
    },
  }

  return style, nil
end

--- Project the style into a minimal PromptLang-Lua art token string
--- suitable for use inside escape sequences.
function M.to_token(style)
  local m  = style.metrics
  local fam = style.family
  -- Example compressed token: HORROR:CosmicDecay:wmp0.8:tdi0.6:snf0.7
  return string.format(
    "HORROR:%s:wmp%.2f:tdi%.2f:snf%.2f:fsm%.2f",
    tostring(fam),
    m.wmp, m.tdi, m.snf, m.fsm
  )
end

--- Return an approximate, engine-agnostic language description for the style.
function M.to_prompt_suffix(style)
  local fam = style.family
  local m   = style.metrics
  local p   = style.palette

  if fam == "CosmicDecay" then
    return string.format(
      "cosmic horror, eroded planets, %s mist, %s sky, granular starlight haze, time-warped perspective, subtle analog noise",
      p.ground, p.bg
    )
  elseif fam == "AnalogGhoul" then
    return "grainy analog videotape, desaturated hallway, silhouetted figure, scanlines, ghostly bloom, off-kilter framing"
  elseif fam == "WaxMeltUrban" then
    return string.format(
      "urban night alley, sodium-vapor %s highlights, buildings sagging like melting wax, reflective puddles, dripping signage",
      p.accent
    )
  else
    return "moody horror atmosphere, deep shadows, restrained palette, slow-building dread"
  end
end

return M
