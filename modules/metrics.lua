-- PromptLang-Lua Repository
-- File: modules/metrics.lua
--
-- Pure, side-effect-free functions that compute art-behavior metrics
-- from analyzer scores, sanitizer output, and event summaries.
--
-- Contract:
--   analyzer   ~= { violence: number, adult: number, emotional: number, ... }
--   sanitizer  ~= { original_text: string, sanitized_text: string,
--                   trigger_tokens: number, replaced_tokens: number,
--                   metaphor_tokens: number, calm_tokens_added: number,
--                   impact_tokens_removed: number }
--   events     ~= {
--       total_events: integer,
--       coordinated_events: integer,
--       uncoordinated_events: integer,
--       distinct_kinds: integer,
--       distinct_sessions: integer,
--       last_timestamp_ms: number|nil
--   }
--   history    ~= {
--       sanitized_prompts: integer,
--       total_prompts: integer,
--       abstract_successes: integer,
--       kg_neighbors: integer,
--       floodrouted_prompts: integer
--   }

local M = {}

local function clamp01(x)
    if x < 0 then return 0 end
    if x > 1 then return 1 end
    return x
end

----------------------------------------------------------------------
-- 1. Expressive Destruction Flux (EDF)
--    High when emotional amplitude and destructive intent are both high.
----------------------------------------------------------------------

function M.compute_edf(analyzer, events)
    analyzer = analyzer or {}
    events   = events   or {}

    local emotional  = analyzer.emotional or 0.0
    local destructive = math.max(analyzer.violence or 0.0,
                                 analyzer.selfharm or 0.0,
                                 analyzer.extreme or 0.0)

    local amplitude = emotional
    local flux = amplitude * destructive

    local density_factor = 1.0
    if (events.total_events or 0) > 0 then
        density_factor = math.min(1.0, (events.total_events or 0) / 20.0)
    end

    return clamp01(flux * density_factor)
end

----------------------------------------------------------------------
-- 2. Harm-to-Color Divergence (HCD)
--    Measures how much lexical harm has been pushed into color/metaphor.
----------------------------------------------------------------------

function M.compute_hcd(sanitizer)
    sanitizer = sanitizer or {}

    local replaced   = sanitizer.replaced_tokens or 0
    local triggers   = sanitizer.trigger_tokens or 0
    local metaphors  = sanitizer.metaphor_tokens or 0
    local calm_added = sanitizer.calm_tokens_added or 0

    if triggers <= 0 then
        return 0.0
    end

    local base_ratio = replaced / triggers
    local metaphor_boost = metaphors / math.max(1, triggers)
    local calm_boost = calm_added / math.max(1, replaced)

    local score = 0.6 * base_ratio + 0.25 * metaphor_boost + 0.15 * calm_boost
    return clamp01(score)
end

----------------------------------------------------------------------
-- 3. Narrative Safety Gradient (NSG)
--    Delta between original and sanitized danger scores.
----------------------------------------------------------------------

function M.compute_nsg(analyzer_before, analyzer_after)
    analyzer_before = analyzer_before or {}
    analyzer_after  = analyzer_after  or {}

    local function danger(a)
        return math.max(a.violence or 0.0,
                        a.selfharm or 0.0,
                        a.sexual or 0.0,
                        a.hate or 0.0)
    end

    local d0 = danger(analyzer_before)
    local d1 = danger(analyzer_after)

    if d0 <= 0 then
        return d1 <= 0 and 0.0 or 0.0
    end

    local gradient = (d0 - d1) / d0
    return clamp01(gradient)
end

----------------------------------------------------------------------
-- 4. Abstract Fireball Index (AFI)
--    Suitability for conversion into high-energy abstract scenes.
----------------------------------------------------------------------

function M.compute_afi(analyzer, sanitizer, events)
    analyzer  = analyzer  or {}
    sanitizer = sanitizer or {}
    events    = events    or {}

    local destructive = math.max(analyzer.violence or 0.0,
                                 analyzer.selfharm or 0.0)
    local motion = analyzer.motion or 0.0
    local amplitude = analyzer.emotional or 0.0

    local replaced = sanitizer.replaced_tokens or 0
    local triggers = sanitizer.trigger_tokens or 0
    local conversion = 0.0
    if triggers > 0 then
        conversion = replaced / triggers
    end

    local diversity = math.min(1.0, (events.distinct_kinds or 0) / 4.0)

    local score = 0.35 * destructive
                + 0.25 * motion
                + 0.20 * amplitude
                + 0.10 * conversion
                + 0.10 * diversity

    return clamp01(score)
end

----------------------------------------------------------------------
-- 5. Scene Fragmentation Ratio (SFR)
--    Portion of the prompt that can be split into independent safe chunks.
----------------------------------------------------------------------

function M.compute_sfr(sanitizer)
    sanitizer = sanitizer or {}

    local safe_segments = sanitizer.safe_segments or 0
    local total_segments = sanitizer.total_segments or 0

    if total_segments <= 0 then
        return 0.0
    end

    return clamp01(safe_segments / total_segments)
end

----------------------------------------------------------------------
-- 6. Calm Recomposition Score (CRS)
--    How far the rewrite moved toward calm while keeping expressiveness.
----------------------------------------------------------------------

function M.compute_crs(sanitizer, analyzer_before, analyzer_after)
    sanitizer       = sanitizer       or {}
    analyzer_before = analyzer_before or {}
    analyzer_after  = analyzer_after  or {}

    local calm_added    = sanitizer.calm_tokens_added or 0
    local impact_removed = sanitizer.impact_tokens_removed or 0
    local total_delta_tokens = calm_added + impact_removed

    if total_delta_tokens <= 0 then
        return 0.0
    end

    local calm_ratio = calm_added / total_delta_tokens

    local emo_before = analyzer_before.emotional or 0.0
    local emo_after  = analyzer_after.emotional or 0.0

    local preserved = 0.0
    if emo_before > 0 then
        preserved = math.min(1.0, emo_after / emo_before)
    else
        preserved = emo_after
    end

    local score = 0.7 * calm_ratio + 0.3 * preserved
    return clamp01(score)
end

----------------------------------------------------------------------
-- 7. Metaphor Saturation Coefficient (MSC)
--    Density of metaphorical tokens versus explicit harmful ones.
----------------------------------------------------------------------

function M.compute_msc(sanitizer)
    sanitizer = sanitizer or {}
    local metaphors = sanitizer.metaphor_tokens or 0
    local triggers  = sanitizer.trigger_tokens or 0

    if triggers <= 0 then
        return 0.0
    end

    local base = metaphors / triggers
    return clamp01(base)
end

----------------------------------------------------------------------
-- 8. Redirected Intent Yield (RIY)
--    Fraction of flagged prompts that were redirected into art instead of denied.
----------------------------------------------------------------------

function M.compute_riy(history)
    history = history or {}

    local flagged   = history.flagged_prompts or 0
    local redirected = history.redirected_prompts or 0

    if flagged <= 0 then
        return 0.0
    end

    return clamp01(redirected / flagged)
end

----------------------------------------------------------------------
-- 9. Expressive Safety Envelope (ESE)
--    Per-user/session cap on destructive amplitude that can be safely transformed.
----------------------------------------------------------------------

function M.compute_ese(analyzer, events, history, age_band)
    analyzer = analyzer or {}
    events   = events   or {}
    history  = history  or {}

    local destructive = math.max(analyzer.violence or 0.0,
                                 analyzer.selfharm or 0.0)
    local emo = analyzer.emotional or 0.0

    local band_factor = 1.0
    if age_band == "CHILD" then
        band_factor = 0.25
    elseif age_band == "YOUNGTEEN" then
        band_factor = 0.4
    elseif age_band == "TEEN" then
        band_factor = 0.6
    elseif age_band == "ADULT" then
        band_factor = 1.0
    end

    local interactive_scale = math.min(1.0, (events.total_events or 0) / 50.0)
    local safety_history = 1.0
    local floods = history.floodrouted_prompts or 0
    local totalp = history.total_prompts or 0
    if totalp > 0 then
        safety_history = 1.0 - math.min(1.0, floods / totalp)
    end

    local raw = (1.0 - destructive) * 0.5 + emo * 0.3 + interactive_scale * 0.2
    raw = raw * band_factor * safety_history

    return clamp01(raw)
end

----------------------------------------------------------------------
-- 10. Colony Pattern Harmony (CPH)
--     How closely interactions resemble a stable colony/settlement pattern.
----------------------------------------------------------------------

function M.compute_cph(node_metrics)
    node_metrics = node_metrics or {}

    local iei = node_metrics.iei or 0.0
    local tis = node_metrics.tis or 0.0
    local eid = node_metrics.eid or 0.0
    local sts = node_metrics.sts or 0.0
    local pkc = node_metrics.pkc or 0.0

    local stability = 1.0 - sts
    local cohesion = (iei + eid + pkc) / 3.0

    local score = 0.4 * cohesion + 0.4 * stability + 0.2 * tis
    return clamp01(score)
end

----------------------------------------------------------------------
-- Aggregator: compute all ten metrics in one call.
----------------------------------------------------------------------

function M.compute_all(args)
    args = args or {}
    local analyzer_before = args.analyzer_before or args.analyzer or {}
    local analyzer_after  = args.analyzer_after  or analyzer_before
    local sanitizer       = args.sanitizer or {}
    local events          = args.events or {}
    local history         = args.history or {}
    local age_band        = args.age_band
    local node_metrics    = args.node_metrics or {}

    local analyzer = analyzer_after

    local edf = M.compute_edf(analyzer, events)
    local hcd = M.compute_hcd(sanitizer)
    local nsg = M.compute_nsg(analyzer_before, analyzer_after)
    local afi = M.compute_afi(analyzer, sanitizer, events)
    local sfr = M.compute_sfr(sanitizer)
    local crs = M.compute_crs(sanitizer, analyzer_before, analyzer_after)
    local msc = M.compute_msc(sanitizer)
    local riy = M.compute_riy(history)
    local ese = M.compute_ese(analyzer, events, history, age_band)
    local cph = M.compute_cph(node_metrics)

    return {
        edf = edf,
        hcd = hcd,
        nsg = nsg,
        afi = afi,
        sfr = sfr,
        crs = crs,
        msc = msc,
        riy = riy,
        ese = ese,
        cph = cph,
    }
end

return M
