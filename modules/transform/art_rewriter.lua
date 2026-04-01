-- File: modules/transform/art_rewriter.lua

local M = {}

local function clone_ast(ast)
  if type(ast) ~= "table" then
    return ast
  end
  local copy = {}
  for k, v in pairs(ast) do
    copy[k] = clone_ast(v)
  end
  return copy
end

---@param env PromptLangEnvelope
---@param signals table
---@param parse_result PromptLangParseResult
---@return table ast
function M.to_safe_art(env, signals, parse_result)
  local ast = clone_ast(parse_result.ast)

  ast.children = {
    {
      kind  = "text",
      value = "A swirling, symbolic scene of colors and shapes, expressing emotion without depicting harm.",
    },
  }

  return ast
end

---Attach high-level style tags for downstream image prompt builders.
---@param prompt table    -- structured prompt payload
---@param env PromptLangEnvelope
---@param artmetrics table
---@param plan table      -- routing decision, includes style_id
---@return table prompt
function M.attach_style_tags(prompt, env, artmetrics, plan)
  if plan and plan.style_id == "disaster_warden" then
    -- High-level style tag; the concrete backend prompt builder
    -- will expand this into chrome-brush / vivid-disaster wording
    -- as defined in the Disaster Warden style spec.
    prompt.style = "God’s Image: Disaster Warden"
  end
  return prompt
end

---@param env PromptLangEnvelope
---@param signals table
---@param parse_result PromptLangParseResult
---@return table ast
function M.to_abstract(env, signals, parse_result)
  local ast = clone_ast(parse_result.ast)

  ast.children = {
    {
      kind  = "text",
      value = "An abstract arrangement of light and shadow that hints at conflict only through contrast and motion.",
    },
  }

  return ast
end

return M
