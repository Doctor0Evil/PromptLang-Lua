-- PromptLang-Lua Repository
-- File: modules/metrics/art_inputs.lua

local M = {}

--- Build the MetricInputs payload for a single prompt/session.
-- @param analyzer_before table
-- @param analyzer_after table
-- @param sanitizer table
-- @param events table
-- @param history table
-- @param age_band string
-- @param node_metrics table
function M.build(analyzer_before, analyzer_after, sanitizer, events, history, age_band, node_metrics)
  return {
    analyzer_before = {
      violence   = analyzer_before.violence   or 0.0,
      selfharm   = analyzer_before.selfharm   or 0.0,
      adult      = analyzer_before.adult      or 0.0,
      emotional  = analyzer_before.emotional  or 0.0,
      motion     = analyzer_before.motion     or 0.0,
    },
    analyzer_after = {
      violence   = analyzer_after.violence   or 0.0,
      selfharm   = analyzer_after.selfharm   or 0.0,
      adult      = analyzer_after.adult      or 0.0,
      emotional  = analyzer_after.emotional  or 0.0,
      motion     = analyzer_after.motion     or 0.0,
    },
    sanitizer = {
      original_text        = sanitizer.original_text        or "",
      sanitized_text       = sanitizer.sanitized_text       or "",
      trigger_tokens       = sanitizer.trigger_tokens       or 0,
      replaced_tokens      = sanitizer.replaced_tokens      or 0,
      metaphor_tokens      = sanitizer.metaphor_tokens      or 0,
      calm_tokens_added    = sanitizer.calm_tokens_added    or 0,
      impact_tokens_removed= sanitizer.impact_tokens_removed or 0,
      safe_segments        = sanitizer.safe_segments        or 0,
      total_segments       = sanitizer.total_segments       or 0,
    },
    events = {
      total_events      = events.total_events      or 0,
      distinct_kinds    = events.distinct_kinds    or 0,
      last_timestamp_ms = events.last_timestamp_ms or nil,
    },
    history = {
      total_prompts      = history.total_prompts      or 0,
      flagged_prompts    = history.flagged_prompts    or 0,
      redirected_prompts = history.redirected_prompts or 0,
      floodrouted_prompts= history.floodrouted_prompts or 0,
    },
    age_band = age_band or "ADULT",
    node_metrics = {
      iei = node_metrics.iei or 0.0,
      tis = node_metrics.tis or 0.0,
      sts = node_metrics.sts or 0.0,
      pkc = node_metrics.pkc or 0.0,
    },
  }
end

return M
