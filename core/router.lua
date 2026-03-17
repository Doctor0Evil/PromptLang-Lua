-- File: core/router.lua

local M = {}

local analyzers = {}
local policy
local age_gate
local escape
local art
local pixelkg
local handpaint

function M.init(deps)
  analyzers = deps.analyzers or {}
  policy    = deps.policy
  age_gate  = deps.age_gate
  escape    = deps.escape
  art       = deps.art
  pixelkg   = deps.pixelkg
  handpaint = deps.handpaint
end

---@param env PromptLangEnvelope
---@return table
function M.route(env)
  env = age_gate.annotate_age(env)

  local signals = {}

  for _, analyzer in ipairs(analyzers) do
    local ok, result = pcall(analyzer.analyze, env)
    if ok and result then
      table.insert(signals, result)
    end
  end

  local action_plan = policy.decide(env, signals)

  if action_plan.decision == "DENY" then
    return {
      status       = "blocked",
      reason       = action_plan.reason or "policy_violation",
      output_text  = action_plan.message or "Request cannot be fulfilled.",
      image_routing = nil,
      debug        = { signals = signals, action_plan = action_plan },
    }
  end

  local parsed = escape.parse(env.text)
  local transformed_ast

  if action_plan.decision == "TRANSFORM_TO_ART" then
    transformed_ast = art.to_safe_art(env, signals, parsed)
  elseif action_plan.decision == "ABSTRACTIFY" then
    transformed_ast = art.to_abstract(env, signals, parsed)
  else
    transformed_ast = parsed.ast
  end

  local pixel_graph = nil
  if action_plan.generate_pixel_graph then
    pixel_graph = pixelkg.build(env, transformed_ast, signals)
  end

  local handpainted_text = nil
  if action_plan.handpaint_style then
    handpainted_text = handpaint.render(env, transformed_ast, action_plan.handpaint_style)
  end

  local final_text = handpainted_text or escape.render(transformed_ast)

  local image_routing = nil
  if action_plan.image_backend then
    image_routing = {
      backend = action_plan.image_backend,
      payload = {
        text        = final_text,
        pixel_graph = pixel_graph,
      },
    }
  end

  return {
    status        = "ok",
    output_text   = final_text,
    image_routing = image_routing,
    debug         = { signals = signals, action_plan = action_plan },
  }
end

return M
