-- PromptLang-Lua
-- Minimal HTTP-style integration example (CGI-like)

package.path = "./?.lua;./?/init.lua;" .. package.path

local PromptLang = require("init")

local function url_decode(str)
  str = tostring(str or "")
  str = str:gsub("+", " ")
  str = str:gsub("%%(%x%x)", function(h)
    return string.char(tonumber(h, 16))
  end)
  return str
end

local function parse_query(qs)
  local params = {}
  qs = tostring(qs or "")
  for pair in qs:gmatch("([^&]+)") do
    local k, v = pair:match("([^=]*)=?(.*)")
    if k and k ~= "" then
      k = url_decode(k)
      v = url_decode(v)
      params[k] = v
    end
  end
  return params
end

local function get_env(name, default)
  local v = os.getenv(name)
  if v == nil or v == "" then
    return default
  end
  return v
end

local function read_body()
  local len = tonumber(os.getenv("CONTENT_LENGTH") or "0", 10) or 0
  if len <= 0 then
    return ""
  end
  return io.read(len) or ""
end

local function json_escape(str)
  str = tostring(str or "")
  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\n", "\\n")
  str = str:gsub("\r", "\\r")
  str = str:gsub("\t", "\\t")
  return str
end

local function payload_to_json(payload)
  local buf = {}
  table.insert(buf, "{")
  table.insert(buf, "\"prompt\":\"" .. json_escape(payload.prompt or "") .. "\",")
  table.insert(buf, "\"route\":{")
  table.insert(buf, "\"handler\":\"" .. json_escape(payload.route.handler or "") .. "\",")
  table.insert(buf, "\"mode\":\"" .. json_escape(payload.route.mode or "") .. "\",")
  table.insert(buf, "\"channel\":\"" .. json_escape(payload.route.channel or "") .. "\"")
  table.insert(buf, "},")
  table.insert(buf, "\"meta\":{")
  local i = 0
  for k, v in pairs(payload.meta or {}) do
    i = i + 1
    table.insert(buf, "\"" .. json_escape(k) .. "\":\"" .. json_escape(tostring(v)) .. "\"")
    table.insert(buf, ",")
  end
  if i > 0 then
    buf[#buf] = buf[#buf]:gsub(",$", "")
  end
  table.insert(buf, "}")
  table.insert(buf, "}")
  return table.concat(buf)
end

local function main()
  local method = get_env("REQUEST_METHOD", "GET")
  local qs = get_env("QUERY_STRING", "")
  local params = parse_query(qs)

  local body = ""
  if method == "POST" then
    body = read_body()
    if body and body ~= "" then
      local body_params = parse_query(body)
      for k, v in pairs(body_params) do
        if params[k] == nil then
          params[k] = v
        end
      end
    end
  end

  local text = params.text or ""
  local channel = params.channel or "art"

  local user_profile = {
    id = params.user_id or "http_user",
    mood = params.mood or "neutral",
    style = params.style or "generic",
    medium = params.medium or "digital painting"
  }

  local payload = PromptLang.handle_chat_request({
    channel = channel,
    text = text,
    user_profile = user_profile
  })

  local json = payload_to_json(payload)

  io.write("Content-Type: application/json\r\n")
  io.write("Cache-Control: no-store\r\n\r\n")
  io.write(json)
end

main()
