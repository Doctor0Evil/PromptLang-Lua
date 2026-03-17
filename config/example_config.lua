-- e.g. File: config/example_config.lua

local violence = require("modules.analyzers.intent_violence")
local selfharm = require("modules.analyzers.intent_selfharm")

return {
  analyzers = {
    violence,
    selfharm,
    -- add more analyzers here
  },
  logging = {
    enabled = true,
  },
}
