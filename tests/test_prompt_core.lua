-- PromptLang-Lua
-- Basic tests for prompt_core

package.path = "./?.lua;./?/init.lua;" .. package.path

local PromptCore = require("prompt_core")

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

local function test_segment_text()
  local seg = PromptCore.segment_text("subject", "a cat")
  assert_eq(seg, "[subject::a cat]", "segment_text basic")
  local empty = PromptCore.segment_text("subject", "   ")
  assert_eq(empty, "", "segment_text empty")
end

local function test_compose_segments()
  local segs = {
    PromptCore.segment_text("a", "one"),
    "",
    PromptCore.segment_text("b", "two")
  }
  local composed = PromptCore.compose_segments(segs)
  assert_eq(composed, "[a::one] [b::two]", "compose_segments skips empty")
end

local function test_wrap_prompt()
  local wrapped = PromptCore.wrap_prompt("[a::one]")
  assert_true(wrapped:find("%[prompt::begin%]") ~= nil, "wrap_prompt has begin")
  assert_true(wrapped:find("%[prompt::end%]") ~= nil, "wrap_prompt has end")
  local empty = PromptCore.wrap_prompt("")
  assert_eq(empty, "[prompt::empty]", "wrap_prompt empty")
end

local function test_escape_user_text()
  local escaped = PromptCore.escape_user_text("user", "[hello]")
  assert_eq(escaped, "[user::\\[hello\\]]", "escape_user_text brackets")
end

local function test_validate_brackets()
  local ok, err = PromptCore.validate_brackets("[a::one] [b::two]")
  assert_true(ok, "validate_brackets balanced")
  local bad, err2 = PromptCore.validate_brackets("[a::one")
  assert_true(not bad, "validate_brackets detects unbalanced")
end

local function test_parse_segments()
  local s = "[a::one] [b::two three]"
  local segs = PromptCore.parse_segments(s)
  assert_eq(#segs, 2, "parse_segments count")
  assert_eq(segs[1].label, "a", "parse_segments label")
  assert_eq(segs[1].body, "one", "parse_segments body")
end

local function run_all()
  test_segment_text()
  test_compose_segments()
  test_wrap_prompt()
  test_escape_user_text()
  test_validate_brackets()
  test_parse_segments()
  print("test_prompt_core.lua: all tests passed")
end

run_all()
