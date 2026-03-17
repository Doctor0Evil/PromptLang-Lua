-- config/schema.lua
local utils = require("lib.utils")

local schema = {}

local function assert_type(path, value, expected)
  if type(value) ~= expected then
    error(("config.%s must be %s, got %s"):format(path, expected, type(value)))
  }
end

function schema.validate(cfg)
  assert_type("api_endpoints", cfg.api_endpoints, "table")
  assert_type("api_endpoints.stable_diffusion",
              cfg.api_endpoints.stable_diffusion, "string")

  assert_type("safety", cfg.safety, "table")
  assert_type("safety.thresholds", cfg.safety.thresholds, "table")

  assert_type("safety.thresholds.violence_score",
              cfg.safety.thresholds.violence_score, "number")
  assert_type("safety.thresholds.adult_score",
              cfg.safety.thresholds.adult_score, "number")

  if cfg.logging then
    assert_type("logging", cfg.logging, "table")
  end

  return true
end

return schema
