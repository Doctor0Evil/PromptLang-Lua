-- PromptLang-Lua
-- Lightweight ML-style personalization and scoring hooks

local MLPersonalizer = {}

local function count_tokens(str)
  local count = 0
  for _ in string.gmatch(str, "%S+") do
    count = count + 1
  end
  return count
end

local function clamp(x, minv, maxv)
  if x < minv then return minv end
  if x > maxv then return maxv end
  return x
end

local function score_length(prompt)
  local tokens = count_tokens(prompt)
  if tokens < 12 then
    return 0.4
  elseif tokens < 32 then
    return 0.9
  elseif tokens < 80 then
    return 0.7
  else
    return 0.3
  end
end

local function score_mood_alignment(prompt, mood)
  mood = tostring(mood or "neutral")
  prompt = string.lower(prompt)
  if mood == "dark" then
    if prompt:find("moody") or prompt:find("shadow") then
      return 0.9
    end
  elseif mood == "bright" or mood == "uplifting" then
    if prompt:find("sunlit") or prompt:find("vibrant") then
      return 0.9
    end
  end
  return 0.5
end

local function score_style_preference(prompt, style)
  style = tostring(style or "generic")
  prompt = string.lower(prompt)
  if prompt:find(style:lower()) then
    return 0.9
  end
  return 0.6
end

local function aggregate_scores(scores, weights)
  local total_w = 0
  local acc = 0
  for key, value in pairs(scores) do
    local w = weights[key] or 1.0
    acc = acc + value * w
    total_w = total_w + w
  end
  if total_w == 0 then
    return 0.0
  end
  return acc / total_w
end

local function apply_boost(prompt, factor)
  factor = clamp(factor or 1.0, 0.6, 1.4)
  if factor > 1.05 then
    return "[ml_boost::high] " .. prompt
  elseif factor < 0.95 then
    return "[ml_boost::low] " .. prompt
  else
    return "[ml_boost::neutral] " .. prompt
  end
end

function MLPersonalizer.personalize_prompt(prompt, user_profile)
  user_profile = user_profile or {}
  local mood = user_profile.mood or "neutral"
  local style = user_profile.style or "generic"

  local scores = {
    length = score_length(prompt),
    mood = score_mood_alignment(prompt, mood),
    style = score_style_preference(prompt, style)
  }

  local weights = {
    length = 0.6,
    mood = 1.0,
    style = 1.0
  }

  local final_score = aggregate_scores(scores, weights)
  local factor = 0.8 + (final_score * 0.4)

  local annotated = "[ml_score::" .. string.format("%.3f", final_score) .. "] " .. prompt
  local boosted = apply_boost(annotated, factor)

  return boosted
end

return MLPersonalizer
