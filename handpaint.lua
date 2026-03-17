-- PromptLang-Lua
-- Handpainting / brush-stroke oriented prompt features

local Handpaint = {}

local BRUSH_STYLES = {
  expressive = {
    label = "expressive",
    stroke_density = 0.7,
    edge_softness = 0.4,
    texture_strength = 0.8,
    line_variation = 0.9,
    notes = "bold strokes, visible brushwork, dynamic rhythm"
  },
  delicate = {
    label = "delicate",
    stroke_density = 0.4,
    edge_softness = 0.7,
    texture_strength = 0.3,
    line_variation = 0.5,
    notes = "fine strokes, gentle transitions, subtle texture"
  },
  comic_ink = {
    label = "comic_ink",
    stroke_density = 0.6,
    edge_softness = 0.2,
    texture_strength = 0.2,
    line_variation = 0.8,
    notes = "clean ink lines, strong contours, graphic shading"
  },
  painterly = {
    label = "painterly",
    stroke_density = 0.8,
    edge_softness = 0.6,
    texture_strength = 0.9,
    line_variation = 0.7,
    notes = "layered brushwork, mixed edges, rich surface"
  },
  sketch = {
    label = "sketch",
    stroke_density = 0.5,
    edge_softness = 0.5,
    texture_strength = 0.4,
    line_variation = 0.9,
    notes = "loose lines, construction marks, exploratory drawing"
  }
}

local function clamp01(x)
  if x < 0 then return 0 end
  if x > 1 then return 1 end
  return x
end

function Handpaint.default_brush_config(style_key)
  style_key = tostring(style_key or "expressive")
  local base = BRUSH_STYLES[style_key] or BRUSH_STYLES.expressive
  return {
    style = base.label,
    stroke_density = base.stroke_density,
    edge_softness = base.edge_softness,
    texture_strength = base.texture_strength,
    line_variation = base.line_variation,
    notes = base.notes
  }
end

function Handpaint.tune_brush(config, delta)
  config = config or Handpaint.default_brush_config("expressive")
  delta = delta or {}
  local function adj(field, default)
    local v = config[field] or default
    local d = delta[field] or 0
    return clamp01(v + d)
  end
  return {
    style = config.style or "custom",
    stroke_density = adj("stroke_density", 0.5),
    edge_softness = adj("edge_softness", 0.5),
    texture_strength = adj("texture_strength", 0.5),
    line_variation = adj("line_variation", 0.5),
    notes = config.notes or ""
  }
end

function Handpaint.to_bracket_brush_expression(config)
  config = config or Handpaint.default_brush_config("expressive")
  local parts = {
    "style=" .. tostring(config.style or "custom"),
    "stroke_density=" .. tostring(config.stroke_density or 0.5),
    "edge_softness=" .. tostring(config.edge_softness or 0.5),
    "texture_strength=" .. tostring(config.texture_strength or 0.5),
    "line_variation=" .. tostring(config.line_variation or 0.5),
    "notes=" .. tostring(config.notes or "")
  }
  return "[brush::" .. table.concat(parts, ";") .. "]"
end

function Handpaint.list_brush_styles()
  local keys = {}
  for k, _ in pairs(BRUSH_STYLES) do
    table.insert(keys, k)
  end
  table.sort(keys)
  return keys
end

return Handpaint
