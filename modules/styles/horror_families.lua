-- PromptLang-Lua Repository
-- File: modules/styles/horror_families.lua

local HorrorStyle = require("modules.styles.horror_style")

local FAMILIES = {
  CosmicDecay = {
    id = "horror.cosmic_decay.v1",
    version = 1,
    family = "CosmicDecay",
    metrics = { wmp = 0.9, nsg = 0.4, tdi = 0.8, snf = 0.3, fsm = 0.5 },
    palette = {
      bg     = "#071814", -- near-black teal
      mid    = "#243626",
      accent = "#D2E38F", -- sickly pale yellow star/mist
      ground = "#2B130C",
    },
    art_string = "TerraScape::cosmic_decay",
    seeds = { numeric_seed = nil, engine_style_tag = nil, ref_image_id = nil },
  },
  AnalogGhoul = {
    id = "horror.analog_ghoul.v1",
    version = 1,
    family = "AnalogGhoul",
    metrics = { wmp = 0.6, nsg = 0.5, tdi = 0.4, snf = 0.9, fsm = 0.2 },
    palette = {
      bg     = "#0B0B10",
      mid    = "#30333A",
      accent = "#F5F5F5",
      ground = "#1A1A1F",
    },
    art_string = "VHS_Ghoul::hallway_silhouette",
  },
  WaxMeltUrban = {
    id = "horror.wax_melt_urban.v1",
    version = 1,
    family = "WaxMeltUrban",
    metrics = { wmp = 0.3, nsg = 0.5, tdi = 0.5, snf = 0.5, fsm = 0.9 },
    palette = {
      bg     = "#050509",
      mid    = "#3B2A2A",
      accent = "#FFB44C", -- sodium vapor
      ground = "#1F1414",
    },
    art_string = "MeltCity::dripping_facades",
  },
}

local M = {}

function M.get(id_or_family)
  local raw = FAMILIES[id_or_family] or FAMILIES[id_or_family:gsub("^horror%.", "")] or nil
  if not raw then return nil, "unknown horror family: " .. tostring(id_or_family) end
  return HorrorStyle.decode(raw)
end

return M
