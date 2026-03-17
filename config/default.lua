-- config/default.lua
local default = {
  api_endpoints = {
    stable_diffusion = "https://api.stability.ai/v2/generation",
  },
  safety = {
    thresholds = {
      violence_score = 0.8,
      adult_score    = 0.7,
    },
  },
  logging = {
    level = "info",
  },
}

return default
