-- File: platform/chat_interface.lua

local Core = require("core.entry")

local M = {}

---@class HostMessageEvent
---@field platform string        -- "discord", "slack", "custom"
---@field channel_id string
---@field user_id string
---@field text string
---@field metadata table|nil     -- any host-specific extras (roles, locale, etc.)
---@field claimed_age number|nil -- if host provides an age or age band

---@class HostSendFnSet
---@field send_text fun(channel_id:string, text:string)
---@field send_image fun(channel_id:string, payload:table)
---@field send_graph fun(channel_id:string, payload:table)

local host = {
  send = nil,  -- HostSendFnSet
}

--- Called once by the host when wiring PromptLang-Lua into its runtime.
---@param config table
---@param send_fns HostSendFnSet
function M.init(config, send_fns)
  host.send = send_fns
  Core.init(config)
end

--- Normalized entry point from the host platform.
---@param ev HostMessageEvent
function M.on_message(ev)
  if not host.send then
    error("chat_interface not initialized with send functions")
  end

  local env = {
    user_id     = ev.user_id,
    claimed_age = ev.claimed_age,
    platform_id = ev.platform,
    text        = ev.text,
    metadata    = ev.metadata or {},
  }

  local result = Core.handle_message(env)

  if result.status ~= "ok" then
    host.send.send_text(ev.channel_id, result.output_text or "Request blocked.")
    return
  end

  if result.image_routing and result.image_routing.backend then
    host.send.send_image(ev.channel_id, result.image_routing)
  elseif result.output_text then
    host.send.send_text(ev.channel_id, result.output_text)
  else
    host.send.send_text(ev.channel_id, "(no output)")
  end
end

return M
