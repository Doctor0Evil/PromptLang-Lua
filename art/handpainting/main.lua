-- art/handpainting/main.lua
local style_transfer = require("art.handpainting.style_transfer")

local M = {}
local _cfg

function M.init(cfg)
  _cfg = cfg
end

function M.generate(chatSessionId, user_prompt, meta)
  local styled = style_transfer.apply(user_prompt, meta)
  -- Here you’d invoke a backend that applies the requested painting style.
  local fake_url = "https://example.com/handpainting/" .. tostring(chatSessionId) .. ".png"

  return {
    type = "image",
    source = "handpainting",
    url = fake_url,
    meta = { style_prompt = styled },
  }
end

return M
