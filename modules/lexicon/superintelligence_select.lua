-- modules/lexicon/superintelligence_select.lua
local Lex = require "modules.lexicon.superintelligence"

local M = {}

local function parse_metric_tag(tag)
  -- "CLD:0.7" -> "CLD", 0.7
  local name, val = tag:match("^(%u+):([%d%.]+)$")
  return name, tonumber(val)
end

local function score_entry(e, targets)
  if not e.metrics then return 0 end
  local score = 0
  for _, tag in ipairs(e.metrics) do
    local name, val = parse_metric_tag(tag)
    local target = targets[name]
    if target and val then
      -- simple similarity: 1 - |val - target|
      score = score + (1 - math.abs(val - target))
    end
  end
  return score
end

function M.pick_by_metrics(category, targets)
  local candidates = Lex.by_category(category)
  local best, best_score
  for _, e in ipairs(candidates) do
    local s = score_entry(e, targets)
    if not best or s > best_score then
      best, best_score = e, s
    end
  end
  return best
end

return M
