-- PromptLang-Lua
-- Main module entrypoint

local PromptCore = require("prompt_core")
local ArtStyles = require("art_styles")
local PixelKG = require("pixel_kg")
local Handpaint = require("handpaint")
local MLPersonalizer = require("ml_personalizer")
local Router = require("router")

local M = {}

-- High-level facade: construct an art-focused prompt
function M.build_art_prompt(opts)
  local subject = opts.subject or "unspecified subject"
  local mood = opts.mood or "neutral mood"
  local style = opts.style or "generic"
  local medium = opts.medium or "digital painting"
  local user_profile = opts.user_profile or {}
  local extra_tags = opts.extra_tags or {}

  local style_descriptor = ArtStyles.describe_style(style, {
    medium = medium,
    mood = mood
  })

  local base_segments = {
    PromptCore.segment_text("subject", subject),
    PromptCore.segment_text("mood", mood),
    PromptCore.segment_text("medium", medium),
    PromptCore.segment_text("style", style_descriptor)
  }

  for _, tag in ipairs(extra_tags) do
    table.insert(base_segments, PromptCore.segment_text("tag", tag))
  end

  local kg_nodes = PixelKG.derive_basic_nodes(subject, mood, style_descriptor)
  local kg_expr = PixelKG.to_bracket_kg_expression(kg_nodes)

  local prompt_body = PromptCore.compose_segments(base_segments)
  local raw_prompt = prompt_body .. " " .. kg_expr

  local personalized = MLPersonalizer.personalize_prompt(raw_prompt, user_profile)

  return PromptCore.wrap_prompt(personalized)
end

-- High-level facade: construct a handpaint / brush-centric prompt
function M.build_handpaint_prompt(opts)
  local base_prompt = M.build_art_prompt(opts)
  local brush_cfg = Handpaint.default_brush_config(opts.brush_style or "expressive")
  local brush_expr = Handpaint.to_bracket_brush_expression(brush_cfg)
  return base_prompt .. " " .. brush_expr
end

-- Build a full chat-ready payload: with metadata and routing hints
function M.build_chat_payload(opts)
  local channel = opts.channel or "art"
  local user_id = opts.user_id or "anonymous"
  local mode = opts.mode or "art"
  local base_opts = opts or {}
  base_opts.channel = nil
  base_opts.user_id = nil
  base_opts.mode = nil

  local prompt
  if mode == "handpaint" then
    prompt = M.build_handpaint_prompt(base_opts)
  else
    prompt = M.build_art_prompt(base_opts)
  end

  local route = Router.resolve_route(channel, {
    mode = mode,
    user_id = user_id
  })

  return {
    prompt = prompt,
    route = route,
    meta = {
      user_id = user_id,
      mode = mode,
      channel = channel,
      timestamp = os.time()
    }
  }
end

-- Utility: validate that bracketed expressions are syntactically balanced
function M.validate_brackets(prompt_str)
  return PromptCore.validate_brackets(prompt_str)
end

-- Utility: escape user-supplied text into safe bracketed form
function M.escape_user_text(label, text)
  return PromptCore.escape_user_text(label, text)
end

-- Router-exposed processing entry (for external chat systems)
function M.handle_chat_request(req)
  local channel = req.channel or "art"
  local text = req.text or ""
  local user_profile = req.user_profile or {}

  local route = Router.resolve_route(channel, {
    text = text,
    user_profile = user_profile
  })

  if route.handler == "art_prompt" then
    local payload = M.build_chat_payload({
      subject = text,
      mood = user_profile.mood or "neutral",
      style = user_profile.style or "generic",
      medium = user_profile.medium or "digital",
      user_profile = user_profile,
      channel = channel,
      mode = "art"
    })
    return payload
  elseif route.handler == "handpaint_prompt" then
    local payload = M.build_chat_payload({
      subject = text,
      mood = user_profile.mood or "reflective",
      style = user_profile.style or "impressionist",
      medium = user_profile.medium or "canvas",
      user_profile = user_profile,
      channel = channel,
      mode = "handpaint"
    })
    return payload
  else
    local escaped = M.escape_user_text("chat", text)
    return {
      prompt = PromptCore.wrap_prompt(escaped),
      route = route,
      meta = {
        user_id = user_profile.id or "anonymous",
        mode = "raw",
        channel = channel,
        timestamp = os.time()
      }
    }
  end
end

return M
