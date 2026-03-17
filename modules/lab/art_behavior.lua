-- File: modules/lab/art_behavior.lua

local rustlab = require("rust_lab_bridge")
local VDOM    = require("modules.vdom.virtual")

local Lab = {}

function Lab.recompute()
  rustlab.art_lab_recompute()
  VDOM.refresh_snapshot()
end

return Lab
