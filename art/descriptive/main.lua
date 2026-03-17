-- art/descriptive/main.lua
local prompt_builder = require("art.descriptive.prompt_builder")
local utils          = require("lib.utils")

local M = {}
local _cfg

function M.init(cfg)
  _cfg = cfg
end

function M.generate(chatSessionId, user_prompt, meta)
  local refined = prompt_builder.build(user_prompt, meta)
  utils.log("debug", "Descriptive art prompt: " .. refined)

  -- Here you would call the external text‑to‑image API.
  -- Placeholder result: a URL or opaque image handle.
  local fake_url = "https://example.com/generated/" .. tostring(chatSessionId) .. ".png"

  return {
    type = "image",
    source = "descriptive",
    url = fake_url,
    meta = { prompt = refined },
  }
end

return M
