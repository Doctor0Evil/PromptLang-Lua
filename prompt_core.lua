-- PromptLang-Lua
-- Core prompt-building primitives and bracketed-expression handling

local PromptCore = {}

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function PromptCore.segment_text(label, text)
  label = tostring(label or "segment")
  text = tostring(text or "")
  text = trim(text)
  if text == "" then
    return ""
  end
  return "[" .. label .. "::" .. text .. "]"
end

function PromptCore.compose_segments(segments)
  local buf = {}
  for _, seg in ipairs(segments) do
    if seg and seg ~= "" then
      table.insert(buf, seg)
    end
  end
  return table.concat(buf, " ")
end

function PromptCore.wrap_prompt(body)
  body = tostring(body or "")
  if body == "" then
    return "[prompt::empty]"
  end
  return "[prompt::begin] " .. body .. " [prompt::end]"
end

function PromptCore.escape_user_text(label, text)
  label = tostring(label or "user")
  text = tostring(text or "")
  text = text:gsub("%[", "\\["):gsub("%]", "\\]")
  return "[" .. label .. "::" .. text .. "]"
end

function PromptCore.validate_brackets(str)
  if type(str) ~= "string" then
    return false, "not a string"
  end
  local stack = 0
  for i = 1, #str do
    local c = str:sub(i, i)
    if c == "[" then
      if i == 1 or str:sub(i - 1, i - 1) ~= "\\" then
        stack = stack + 1
      end
    elseif c == "]" then
      if i == 1 or str:sub(i - 1, i - 1) ~= "\\" then
        stack = stack - 1
        if stack < 0 then
          return false, "unbalanced closing bracket at position " .. i
        end
      end
    end
  end
  if stack ~= 0 then
    return false, "unbalanced brackets, depth=" .. stack
  end
  return true
end

function PromptCore.parse_segments(str)
  local segments = {}
  if type(str) ~= "string" then
    return segments
  end
  for label, body in str.gmatch(str, "%[(.-)::(.-)%]") do
    table.insert(segments, { label = label, body = body })
  end
  return segments
end

return PromptCore
