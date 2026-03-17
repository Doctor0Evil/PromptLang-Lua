-- File: modules/escape/escape_sequences.lua

local M = {}

---@class PromptLangSegment
---@field kind string
---@field value string|table

---@class PromptLangParseResult
---@field ast table
---@field errors table

---@param text string
---@return PromptLangParseResult
function M.parse(text)
  -- TODO: Implement real parser.
  return {
    ast = {
      kind     = "root",
      children = {
        { kind = "text", value = text },
      },
    },
    errors = {},
  }
end

---@param ast table
---@return string
function M.render(ast)
  if not ast or ast.kind ~= "root" or not ast.children then
    return ""
  end

  local buffer = {}

  for _, child in ipairs(ast.children) do
    if child.kind == "text" then
      table.insert(buffer, child.value)
    elseif child.kind == "prompt_block" then
      table.insert(buffer, "[PROMPT:" .. (child.value or "") .. "]")
    else
      table.insert(buffer, tostring(child.value))
    end
  end

  return table.concat(buffer)
end

return M
