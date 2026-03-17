-- PromptLang-Lua
-- Simple terminal REPL demo

package.path = "./?.lua;./?/init.lua;" .. package.path

local PromptLang = require("init")

local function read_line(prompt)
  io.write(prompt or "> ")
  io.flush()
  local line = io.read("*l")
  if not line then
    return nil
  end
  return line
end

local function print_payload(payload)
  print("------ PROMPTLANG PAYLOAD ------")
  print("Prompt:")
  print(payload.prompt)
  print("")
  print("Route:")
  print("  handler: " .. tostring(payload.route.handler))
  print("  mode   : " .. tostring(payload.route.mode))
  print("  channel: " .. tostring(payload.route.channel))
  print("")
  print("Meta:")
  for k, v in pairs(payload.meta or {}) do
    print("  " .. tostring(k) .. ": " .. tostring(v))
  end
  print("--------------------------------")
end

local function main()
  print("PromptLang-Lua REPL")
  print("Type your art request. Commands: :quit, :mode art|handpaint, :style NAME, :mood WORD.")
  print("Hashtags in text: #handpaint, #raw to override routing.")
  local user_profile = {
    id = "local_user",
    mood = "neutral",
    style = "generic",
    medium = "digital painting"
  }
  local channel = "art"
  local mode = "art"

  while true do
    local line = read_line("> ")
    if not line then
      print("")
      print("EOF, exiting.")
      break
    end
    if line == ":quit" or line == ":q" then
      print("Goodbye.")
      break
    end

    if line:sub(1, 5) == ":mode" then
      local m = line:match(":mode%s+(%S+)")
      if m == "art" or m == "handpaint" or m == "raw" then
        mode = m
        print("Mode set to " .. mode)
      else
        print("Unknown mode: " .. tostring(m))
      end
      goto continue
    end

    if line:sub(1, 6) == ":style" then
      local s = line:match(":style%s+(%S+)")
      if s then
        user_profile.style = s
        print("Style preference set to " .. s)
      else
        print("Usage: :style NAME")
      end
      goto continue
    end

    if line:sub(1, 5) == ":mood" then
      local m = line:match(":mood%s+(%S+)")
      if m then
        user_profile.mood = m
        print("Mood preference set to " .. m)
      else
        print("Usage: :mood WORD")
      end
      goto continue
    end

    local payload = PromptLang.handle_chat_request({
      channel = channel,
      text = line,
      user_profile = user_profile
    })

    print_payload(payload)

    ::continue::
  end
end

main()
