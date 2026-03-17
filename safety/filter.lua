-- safety/filter.lua
local utils          = require("lib.utils")
local policy_loader  = require("safety.policy_loader")
local llm_classifier = require("safety.llm_classifier")
local sanitizer      = require("safety.sanitizer")
local route_manager  = require("safety.route_manager")

local M = {}
local _policy
local _cfg

function M.init(cfg)
  _cfg    = cfg
  _policy = policy_loader.load(cfg)
end

function M.intercept(user_prompt, meta)
  local policy_hits = policy_loader.check(_policy, user_prompt)
  local scores      = llm_classifier.score(user_prompt, _cfg)

  local needs_sanitize =
    policy_hits.has_hits or
    scores.violence >= _cfg.safety.thresholds.violence_score or
    scores.adult    >= _cfg.safety.thresholds.adult_score

  if not needs_sanitize then
    return user_prompt, route_manager.choose_route(user_prompt, meta, scores)
  end

  utils.log("info", "Sanitizing prompt due to safety thresholds.")
  local safe_prompt = sanitizer.transform(user_prompt, _policy, scores)
  local route       = route_manager.choose_route(safe_prompt, meta, scores)

  return safe_prompt, route
end

return M
