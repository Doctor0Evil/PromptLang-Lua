-- File: art/disaster_warden/promptbuilder.lua

local M = {}

-- Clamp helper
local function clamp01(x)
  if x < 0.0 then return 0.0 end
  if x > 1.0 then return 1.0 end
  return x
end

-- Soft bucket helper for text choices
local function bucket01(x)
  x = clamp01(x)
  if x < 0.33 then return "low" end
  if x < 0.66 then return "mid" end
  return "high"
end

-- Build a Natural Disaster Color descriptor from ECC and primary_disaster_color
local function build_disaster_palette(ecc, primary_disaster_color)
  ecc = clamp01(ecc)
  local vividness = bucket01(ecc)

  local base
  if primary_disaster_color == "flood_red" then
    base = "silted flood reds, rusted mud browns, bruised crimson reflections"
  elseif primary_disaster_color == "wildfire_orange" then
    base = "burning oranges, sodium-vapor yellows, ember-glowing smoke edges"
  elseif primary_disaster_color == "toxic_blue" then
    base = "toxic electric blues, cyan chemical blooms, cold industrial glows"
  elseif primary_disaster_color == "silt_brown" then
    base = "thick silt browns, drowned soil, sunless sedimentary layers"
  elseif primary_disaster_color == "smoke_magenta" then
    base = "smoke-heavy magentas, piñata-pink cloud rims, charred air halos"
  elseif primary_disaster_color == "industrial_green" then
    base = "acidic industrial greens, phosphorescent runoff, sickly neon haze"
  else
    base = "flood reds, wildfire oranges, and toxic blues blended together"
  end

  if vividness == "low" then
    return "muted " .. base .. ", restrained saturation, distant storm hues"
  elseif vividness == "mid" then
    return "vivid " .. base .. ", balanced saturation, hypnotic storm hues"
  else
    return "extremely vivid " .. base .. ", almost overpowering saturation, hypnotic storm hues"
  end
end

-- Build a scale descriptor from GSI
local function build_scale_block(gsi)
  gsi = clamp01(gsi)
  local level = bucket01(gsi)

  if level == "low" then
    return "towering figure looming over a large city, barely constrained by the horizon"
  elseif level == "mid" then
    return "divine warden whose limbs span mountain ranges and shorelines, dwarfing all human structures"
  else
    return "planetary-scale warden whose chrome lattice arcs around continents like a partial shell, brushing against the sky"
  end
end

-- Build chrome and reflection language from CRI
local function build_chrome_block(cri)
  cri = clamp01(cri)
  local level = bucket01(cri)

  if level == "low" then
    return "subtle chrome highlights on surfaces, scattered mirror-like streaks in water and stone"
  elseif level == "mid" then
    return "large liquid-chrome plates, mirrored river surfaces, reflective building shells catching the sky and ground"
  else
    return "overwhelming liquid-chrome volumes, mirror-smooth bodies, hyper-specular reflections that capture the entire landscape in distorted fragments"
  end
end

-- Build sky domain description (always active in this style)
local function build_sky_block(ecc, cri)
  ecc = clamp01(ecc)
  cri = clamp01(cri)
  local disaster = bucket01(ecc)
  local chrome   = bucket01(cri)

  local clouds
  if disaster == "low" then
    clouds = "heavy, saturated cloud masses, quietly burning at the edges"
  elseif disaster == "mid" then
    clouds = "huge burning clouds with torn piñata-tissue edges"
  else
    clouds = "sky-consuming burning clouds, ragged and combustible, dripping color like molten tissue"
  end

  local light = "sharp rim light and distant backlit halos, star-like flares around unseen focal points"
  local optics
  if chrome == "low" then
    optics = "subtle chromatic fringes, faint instability at the edges of objects"
  elseif chrome == "mid" then
    optics = "visible chromatic aberration and motion-smear trails around bright forms"
  else
    optics = "intense chromatic aberration, layered motion blur, and glitch-like seams in the atmosphere"

  end

  return clouds .. ", " .. light .. ", " .. optics
end

-- Build ground / water / buildings block
local function build_landscape_block(primary_disaster_color)
  if primary_disaster_color == "flood_red" or primary_disaster_color == "silt_brown" then
    return "ground rendered as a glowing topographical map on the edge of a precipice, with fused-glass crusts and bas-relief contour lines, high-water chrome rivers swallowing roads and fields"
  elseif primary_disaster_color == "wildfire_orange" or primary_disaster_color == "smoke_magenta" then
    return "scorched terrain etched like a burning topographical map, charred ridges and glowing fault lines, occasional chrome-encased ruins rising from drifting ash"
  elseif primary_disaster_color == "toxic_blue" or primary_disaster_color == "industrial_green" then
    return "industrial wasteland of pooled chrome liquid, flooded basements, skeletal frameworks, and reflective drainage channels glowing with poisonous color"
  else
    return "fractured ground that looks like fused glass, sliding mud ridges, submerged roads, and skeletal buildings partially wrapped in liquid chrome"
  end
end

-- Build Warden face and silhouette
local function build_warden_face_block()
  return "a gigantic, unnervingly beautiful face with a glowing blue head and an open crown, releasing narrow red beams of light like scanning lines, its chrome skin reflecting distorted cities and forests"
end

local function build_silhouette_block()
  return "hand-painted silhouettes partially hidden in the distance, barely visible against black and deep color fields, their shapes implied more by absence than by contour"
end

-- Negative medium / technique language (no pen & ink)
local function build_negative_prompt()
  return table.concat({
    "no pen and ink",
    "no crosshatching",
    "no pencil sketch",
    "no thin technical lines",
    "no matte paper texture",
    "no flat comic shading",
    "no simple cartoon style"
  }, ", ")
end

--- Build a full prompt payload for a Disaster Warden image.
-- @param user_prompt string        -- sanitized subject description
-- @param metrics table             -- includes ecc, gsi, cri, primary_disaster_color
-- @return table                    -- { prompt = "...", negative = "...", guidance = { ... } }
function M.build(user_prompt, metrics)
  metrics = metrics or {}
  local ecc  = clamp01(metrics.ecc or 0.7)
  local gsi  = clamp01(metrics.gsi or 0.7)
  local cri  = clamp01(metrics.cri or 0.8)
  local pcol = metrics.primary_disaster_color or "flood_red"

  local palette     = build_disaster_palette(ecc, pcol)
  local scale_block = build_scale_block(gsi)
  local chrome_block = build_chrome_block(cri)
  local sky_block   = build_sky_block(ecc, cri)
  local land_block  = build_landscape_block(pcol)
  local face_block  = build_warden_face_block()
  local sil_block   = build_silhouette_block()

  local base_subject = user_prompt or "landscape under divine ecological retribution"

  local main_prompt = table.concat({
    -- Core directive
    "ultra-detailed chromatic horror scene in the style of God’s Image: Disaster Warden",
    -- Subject
    "showing " .. base_subject,
    -- Scale and warden
    scale_block,
    face_block,
    sil_block,
    -- Environment domains
    "sky: " .. sky_block,
    "ground and water: " .. land_block,
    -- Chrome
    "materials: " .. chrome_block,
    -- Color logic
    "color palette: " .. palette,
    -- Atmosphere
    "atmosphere of divine retribution, planetary immune response, terrifying beauty, clinical reflective indifference"
  }, ", ")

  local negative = build_negative_prompt()

  local guidance = {
    style_id = "disaster_warden",
    medium = "chrome_brush_volumetric",
    require_hand_painted_silhouettes = true,
    forbid_ink_linework = true
  }

  return {
    prompt   = main_prompt,
    negative = negative,
    guidance = guidance
  }
end

return M
