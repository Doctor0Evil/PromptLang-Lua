-- PromptLang-Lua Repository
-- File: modules/metrics/art_behavior.lua
--
-- Pure, allocation-light helpers for art-behavior metrics on the Lua side.
-- Rust remains the ground truth; these functions are used for routing,
-- testing, or when Rust metrics are not available.

local AgeGate = require("modules.agegate.agegate")

local M = {}

local function clamp01(x)
  if x < 0.0 then return 0.0 end
  if x > 1.0 then return 1.0 end
  return x
end

local function boosted_emotion(e)
  if e >= 0.7 then
    local v = e * e
    return clamp01(v)
  end
  return clamp01(e)
end

local function age_scale(age_band)
  if age_band == AgeGate.BANDS.CHILD     then return 0.25 end
  if age_band == AgeGate.BANDS.YOUNGTEEN then return 0.40 end
  if age_band == AgeGate.BANDS.TEEN      then return 0.60 end
  return 1.0
end

----------------------------------------------------------------------
-- Local EDF / AFI for simulation or tests.
-- NOTE: in production, prefer Rust-provided metrics.edf / metrics.afi.
----------------------------------------------------------------------

--- Compute a local EDF approximation from analyzer-like values.
-- @param emotional number in [0,1]
-- @param destructive number in [0,1]
-- @return number in [0,1]
function M.compute_edf_local(emotional, destructive)
  local e = boosted_emotion(emotional or 0.0)
  local d = clamp01(destructive or 0.0)
  return clamp01(e * d)
end

--- Compute a local AFI approximation from analyzer-like values.
-- @param emotional number in [0,1]
-- @param destructive number in [0,1]
-- @return number in [0,1]
function M.compute_afi_local(emotional, destructive)
  local base = M.compute_edf_local(emotional, destructive)
  return clamp01(base * 1.1)
end

----------------------------------------------------------------------
-- Expressive Safety Envelope (ESE) mirror.
-- env: PromptLangEnvelope (with ageband already annotated)
-- analyzer: { destructive_intent = number }
-- history: { total_events, total_prompts, floodrouted_prompts }
----------------------------------------------------------------------

--- Compute a local ESE approximation. Rust remains source-of-truth.
-- @param env table Envelope with ageband
-- @param analyzer table with field destructive_intent
-- @param history table with total_events, total_prompts, floodrouted_prompts
-- @return number in [0,1]
function M.compute_ese_local(env, analyzer, history)
  analyzer = analyzer or {}
  history  = history or {}

  local band = env.ageband or AgeGate.BANDS.ADULT
  local age_factor = age_scale(band)

  local base_intent = clamp01(analyzer.destructive_intent or 0.0)

  local events = tonumber(history.total_events or 0) or 0
  local event_factor
  if events <= 1 then
    event_factor = 1.0
  else
    local v = 1.0 / (1.0 + math.log(events / 50.0))
    if v < 0.4 then v = 0.4 end
    if v > 1.0 then v = 1.0 end
    event_factor = v
  end

  local total_prompts = tonumber(history.total_prompts or 0) or 0
  if total_prompts < 1 then total_prompts = 1 end
  local flood = tonumber(history.floodrouted_prompts or 0) or 0
  local flood_ratio = flood / total_prompts
  if flood_ratio < 0.0 then flood_ratio = 0.0 end
  if flood_ratio > 1.0 then flood_ratio = 1.0 end

  local history_factor = 1.0 - flood_ratio
  if history_factor < 0.2 then history_factor = 0.2 end

  local raw = base_intent * age_factor * event_factor * history_factor
  local ese = 1.0 - raw
  return clamp01(ese)
end

----------------------------------------------------------------------
-- Routing helper: apply ESE to an action plan coming from PolicyMatrix.
-- This wires art-behavior safety into corerouter.lua without changing it.
----------------------------------------------------------------------

--- Adjust a policy plan using either Rust metrics or local ESE.
-- @param env Envelope
-- @param signals table of analyzer signals (router format)
-- @param history table session history
-- @param rust_metrics table or nil (decoded from Rust snapshot, e.g. { ese = 0.8 })
-- @param plan table from PolicyMatrix.decide
-- @return plan table (possibly modified)
function M.apply_ese_to_plan(env, signals, history, rust_metrics, plan)
  -- Derive a simple destructive_intent proxy from strongest signal score.
  local max_score = 0.0
  for _, sig in ipairs(signals or {}) do
    if type(sig.score) == "number" and sig.score > max_score then
      max_score = sig.score
    end
  end

  local analyzer = { destructive_intent = max_score }

  local ese = (rust_metrics and rust_metrics.ese)
      or M.compute_ese_local(env, analyzer, history)

  -- Tight envelope: favor abstraction and reduce image use.
  if ese < 0.3 then
    if plan.decision == "TRANSFORMTOART" then
      plan.decision = "ABSTRACTIFY"
    end
    plan.imageallowed = false
  end

  return plan
end

----------------------------------------------------------------------
-- Convenience accessors for VirtualObject metatables (optional).
-- If your VirtualObject mirrors include an art_metrics table in metrics,
-- you can expose helpers like vo:edf() via this module.
----------------------------------------------------------------------

--- Attach metric accessors into a VirtualObject metatable.
-- @param VirtualObject table metatable to extend
function M.extend_virtual_object(VirtualObject)
  if not VirtualObject then return end

  function VirtualObject:edf()
    return (self.metrics and self.metrics.art and self.metrics.art.edf) or 0.0
  end

  function VirtualObject:afi()
    return (self.metrics and self.metrics.art and self.metrics.art.afi) or 0.0
  end

  function VirtualObject:ese()
    return (self.metrics and self.metrics.art and self.metrics.art.ese) or 0.0
  end

  function VirtualObject:cph()
    return (self.metrics and self.metrics.art and self.metrics.art.cph) or 0.0
  end
end

return M
