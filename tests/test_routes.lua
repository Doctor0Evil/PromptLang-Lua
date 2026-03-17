-- PromptLang-Lua
-- Basic tests for router + high-level chat handling

package.path = "./?.lua;./?/init.lua;" .. package.path

local Router = require("router")
local PromptLang = require("init")

local function assert_eq(a, b, msg)
  if a ~= b then
    error((msg or "assert_eq failed") .. ": [" .. tostring(a) .. "] ~= [" .. tostring(b) .. "]")
  end
end

local function assert_true(v, msg)
  if not v then
    error(msg or "assert_true failed")
  end
end

local function test_default_routes()
  Router.reset_routes()
  local r = Router.resolve_route("art", {})
  assert_eq(r.handler, "art_prompt", "default art handler")
  assert_eq(r.mode, "art", "default art mode")
end

local function test_hashtag_override()
  Router.reset_routes()
  local r = Router.resolve_route("art", { text = "mountains #handpaint" })
  assert_eq(r.handler, "handpaint_prompt", "handpaint hashtag handler")
  assert_eq(r.mode, "handpaint", "handpaint hashtag mode")
  local r2 = Router.resolve_route("art", { text = "just text #raw" })
  assert_eq(r2.handler, "raw_prompt", "raw hashtag handler")
  assert_eq(r2.mode, "raw", "raw hashtag mode")
end

local function test_register_channel()
  Router.reset_routes()
  local ok, err = Router.register_channel("gallery", {
    handler = "art_prompt",
    mode = "art",
    meta = { forced_mode = true }
  })
  assert_true(ok, "register_channel ok")
  local r = Router.resolve_route("gallery", { mode = "raw" })
  assert_eq(r.mode, "art", "forced_mode prevents override")
end

local function test_handle_chat_request_art()
  Router.reset_routes()
  local payload = PromptLang.handle_chat_request({
    channel = "art",
    text = "a castle on a hill at sunset",
    user_profile = {
      id = "user123",
      mood = "bright",
      style = "impressionist",
      medium = "digital painting"
    }
  })
  assert_true(type(payload.prompt) == "string", "payload has prompt")
  assert_true(payload.prompt:find("%[prompt::begin%]") ~= nil, "prompt wrapped")
  assert_eq(payload.route.handler, "art_prompt", "art handler")
end

local function test_handle_chat_request_handpaint()
  Router.reset_routes()
  local payload = PromptLang.handle_chat_request({
    channel = "handpaint",
    text = "portrait with strong brushwork",
    user_profile = {
      id = "user456",
      mood = "neutral",
      style = "painterly",
      medium = "canvas"
    }
  })
  assert_true(payload.prompt:find("%[brush::") ~= nil, "handpaint has brush block")
  assert_eq(payload.route.mode, "handpaint", "handpaint route mode")
end

local function run_all()
  test_default_routes()
  test_hashtag_override()
  test_register_channel()
  test_handle_chat_request_art()
  test_handle_chat_request_handpaint()
  print("test_routes.lua: all tests passed")
end

run_all()
