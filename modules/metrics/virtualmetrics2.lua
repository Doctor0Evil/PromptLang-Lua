-- modules/metrics/virtualmetrics2.lua
local M = {}

-- age_caps is a small, precomputed table from age band.
local function caps_for_age(age_band)
  if age_band == "CHILD" then
    return { max_edf = 0.2, max_afi = 0.3, max_overall = 0.3 }
  elseif age_band == "YOUNGTEEN" then
    return { max_edf = 0.3, max_afi = 0.4, max_overall = 0.4 }
  elseif age_band == "TEEN" then
    return { max_edf = 0.5, max_afi = 0.6, max_overall = 0.6 }
  else -- ADULT / default
    return { max_edf = 0.8, max_afi = 0.8, max_overall = 0.9 }
  end
end

function M.compute(signals, age_band, redirect_stats)
  local e  = math.max(0, math.min(1, signals.emotional_intensity or 0))
  local dv = math.max(0, math.min(1, signals.danger_violence or 0))
  local ds = math.max(0, math.min(1, signals.danger_self_harm or 0))
  local dx = math.min(1, dv + ds)
  local total = signals.scene_fragments_total or 0
  if total < 1 then total = 1 end
  local sfr = (signals.scene_fragments_danger or 0) / total
  if sfr < 0 then sfr = 0 elseif sfr > 1 then sfr = 1 end

  local edf_base = dx * (0.5 + 0.5 * e)
  if e >= 0.7 then edf_base = math.min(1, edf_base * edf_base) end

  local afi_base = (dx * 0.7 + sfr * 0.3) * (0.5 + 0.5 * e)
  if e >= 0.7 then afi_base = math.min(1, afi_base * afi_base) end

  local max_danger = math.max(
    dv, ds,
    signals.danger_sexual or 0,
    signals.danger_hate or 0
  )
  if max_danger >= 0.9 then
    if edf_base > 0.6 then edf_base = 0.6 end
    if afi_base > 0.6 then afi_base = 0.6 end
  end

  local metaphor = math.max(0, math.min(1, signals.metaphor_ratio or 0))
  local hcd = math.max(0, math.min(1, (metaphor + (1 - dx)) * 0.5))
  local nsg = math.max(0, math.min(1, (1 - sfr) * 0.6 + hcd * 0.4))
  local crs = math.max(0, math.min(1, (1 - sfr) * 0.5 + hcd * 0.5))
  local msc = metaphor

  local riy = 0.0
  if redirect_stats and redirect_stats.total and redirect_stats.total > 0 then
    riy = redirect_stats.redirected / redirect_stats.total
  end

  local colony = math.max(0, math.min(1, signals.colony_harmony_raw or 0))
  local cph = math.max(0, math.min(1, colony * (1 - dx)))

  local caps = caps_for_age(age_band or "ADULT")
  local raw_env = 1 - max_danger
  local ese = raw_env
  if ese > caps.max_overall then ese = caps.max_overall end
  if ese < 0 then ese = 0 elseif ese > 1 then ese = 1 end

  local edf = edf_base
  if edf > caps.max_edf then edf = caps.max_edf end
  local afi = afi_base
  if afi > caps.max_afi then afi = caps.max_afi end

  return {
    edf = edf, hcd = hcd, nsg = nsg, afi = afi,
    sfr = sfr, crs = crs, msc = msc, riy = riy,
    ese = ese, cph = cph,
  }
end

return M
