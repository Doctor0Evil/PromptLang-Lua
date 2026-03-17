-- PromptLang-Lua
-- Descriptive art styles catalog and helpers

local ArtStyles = {}

local STYLES = {
  generic = {
    label = "generic",
    adjectives = { "balanced", "clear", "high-detail" },
    mediums = { "digital painting", "concept art" },
    palettes = { "natural", "soft contrast" }
  },
  impressionist = {
    label = "impressionist",
    adjectives = { "loose", "painterly", "light-driven", "textured" },
    mediums = { "oil on canvas", "gouache", "digital oil" },
    palettes = { "sunlit", "pastel", "vibrant" }
  },
  anime = {
    label = "anime",
    adjectives = { "stylized", "clean-line", "cel-shaded", "expressive" },
    mediums = { "digital illustration", "2D animation frame" },
    palettes = { "high contrast", "saturated" }
  },
  cinematic = {
    label = "cinematic",
    adjectives = { "dramatic", "filmic", "depth-of-field", "dynamic lighting" },
    mediums = { "keyframe concept", "digital matte painting" },
    palettes = { "moody", "teal-orange", "neutral film" }
  },
  watercolor = {
    label = "watercolor",
    adjectives = { "soft-edge", "bleeding pigment", "translucent" },
    mediums = { "watercolor on textured paper" },
    palettes = { "muted", "subtle gradients" }
  },
  pixel_art = {
    label = "pixel_art",
    adjectives = { "low-res", "crisp edges", "retro", "tile-based" },
    mediums = { "pixel art spritesheet", "8-bit game mockup" },
    palettes = { "limited palette", "indexed color" }
  },
  line_art = {
    label = "line_art",
    adjectives = { "inked", "contour-focused", "monoline", "clean" },
    mediums = { "comic ink drawing", "technical pen sketch" },
    palettes = { "black and white", "minimal accent color" }
  },
  concept_art = {
    label = "concept_art",
    adjectives = { "exploratory", "ideation-focused", "rough-to-polished" },
    mediums = { "environment concept", "character sheet", "prop design" },
    palettes = { "production-ready", "balanced values" }
  }
}

local function join_words(words)
  local buf = {}
  for _, w in ipairs(words) do
    if w and w ~= "" then
      table.insert(buf, w)
    end
  end
  return table.concat(buf, ", ")
end

function ArtStyles.get_style(key)
  key = tostring(key or "generic")
  local s = STYLES[key]
  if s then
    return s
  end
  return STYLES.generic
end

function ArtStyles.list_styles()
  local keys = {}
  for k, _ in pairs(STYLES) do
    table.insert(keys, k)
  end
  table.sort(keys)
  return keys
end

function ArtStyles.describe_style(key, overrides)
  local cfg = ArtStyles.get_style(key)
  overrides = overrides or {}

  local medium = overrides.medium or cfg.mediums[1]
  local mood = overrides.mood or "neutral"

  local adjectives = cfg.adjectives or {}
  local palettes = cfg.palettes or {}
  local adj_str = join_words(adjectives)
  local pal_str = join_words(palettes)

  local desc = {}
  table.insert(desc, cfg.label)
  table.insert(desc, "style")
  if adj_str ~= "" then
    table.insert(desc, "(" .. adj_str .. ")")
  end
  table.insert(desc, "rendered as")
  table.insert(desc, medium)
  table.insert(desc, "with")
  if pal_str ~= "" then
    table.insert(desc, pal_str)
    table.insert(desc, "palette")
  else
    table.insert(desc, "balanced palette")
  end
  table.insert(desc, "and mood")
  table.insert(desc, mood)

  return table.concat(desc, " ")
end

function ArtStyles.to_bracket_style(key, overrides)
  local text = ArtStyles.describe_style(key, overrides)
  return "[style_desc::" .. text .. "]"
end

return ArtStyles
