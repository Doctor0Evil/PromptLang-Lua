-- PromptLang-Lua
-- Minimal channel-based routing for chat requests

local Router = {}

local DEFAULT_ROUTES = {
  art = {
    handler = "art_prompt",
    mode = "art"
  },
  handpaint = {
    handler = "handpaint_prompt",
    mode = "handpaint"
  },
  raw = {
    handler = "raw_prompt",
    mode = "raw"
  }
}

local function clone_table(t)
  local r = {}
  for k, v in pairs(t or {}) do
    r[k] = v
  end
  return r
end

Router.routes = clone_table(DEFAULT_ROUTES)

function Router.register_channel(name, conf)
  name = tostring(name or "")
  if name == "" then
    return false, "channel name required"
  end
  if type(conf) ~= "table" then
    return false, "config table required"
  end
  Router.routes[name] = {
    handler = conf.handler or "raw_prompt",
    mode = conf.mode or "raw",
    meta = conf.meta or {}
  }
  return true
end

function Router.reset_routes()
  Router.routes = clone_table(DEFAULT_ROUTES)
end

function Router.resolve_route(channel, context)
  channel = tostring(channel or "art")
  context = context or {}
  local route = Router.routes[channel] or DEFAULT_ROUTES.art
  local resolved = {
    handler = route.handler,
    mode = route.mode,
    channel = channel,
    meta = clone_table(route.meta or {})
  }

  if context.mode and not resolved.meta.forced_mode then
    resolved.mode = context.mode
  end

  if context.user_id then
    resolved.meta.user_id = context.user_id
  end

  if context.text then
    local lowered = string.lower(context.text)
    if lowered:find("#handpaint") then
      resolved.handler = "handpaint_prompt"
      resolved.mode = "handpaint"
    elseif lowered:find("#raw") then
      resolved.handler = "raw_prompt"
      resolved.mode = "raw"
    end
  end

  return resolved
end

return Router
