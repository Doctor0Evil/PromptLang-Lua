-- File: lib/parser.lua

local M = {}

---@class Token
---@field kind string  -- "LBRACE","RBRACE","IDENT","COLON","COMMA","TEXT","EOF"
---@field lexeme string

---@class ASTNode
---@field kind string
---@field value string|table|nil
---@field children table|nil

local function tokenize(input)
  local tokens = {}
  local i, n = 1, #input

  local function add(kind, lexeme)
    table.insert(tokens, { kind = kind, lexeme = lexeme })
  end

  while i <= n do
    local c = input:sub(i, i)
    if c == "{" then
      add("LBRACE", c); i = i + 1
    elseif c == "}" then
      add("RBRACE", c); i = i + 1
    elseif c == ":" then
      add("COLON", c); i = i + 1
    elseif c == "," then
      add("COMMA", c); i = i + 1
    elseif c:match("%s") then
      i = i + 1
    elseif c:match("[%w_%-]") then
      local j = i
      while j <= n and input:sub(j, j):match("[%w_%-]") do
        j = j + 1
      end
      local word = input:sub(i, j - 1)
      add("IDENT", word)
      i = j
    else
      local j = i
      while j <= n do
        local ch = input:sub(j, j)
        if ch == "{" or ch == "}" or ch == ":" or ch == "," then
          break
        end
        j = j + 1
      end
      add("TEXT", input:sub(i, j - 1))
      i = j
    end
  end

  add("EOF", "")
  return tokens
end

local Parser = {}
Parser.__index = Parser

function Parser:new(tokens)
  return setmetatable({ tokens = tokens, pos = 1 }, self)
end

function Parser:peek()
  return self.tokens[self.pos]
end

function Parser:advance()
  local t = self.tokens[self.pos]
  self.pos = self.pos + 1
  return t
end

function Parser:match(kind)
  local t = self:peek()
  if t.kind == kind then
    self:advance()
    return t
  end
  return nil
end

function Parser:expect(kind, msg)
  local t = self:peek()
  if t.kind ~= kind then
    error(msg .. " (expected " .. kind .. ", got " .. t.kind .. ")")
  end
  return self:advance()
end

-- root := (directive | text_chunk)* EOF
function Parser:parse_root()
  local children = {}

  while self:peek().kind ~= "EOF" do
    local t = self:peek()
    if t.kind == "LBRACE" then
      table.insert(children, self:parse_directive())
    else
      table.insert(children, self:parse_text())
    end
  end

  return { kind = "root", children = children }
end

-- directive := "{" pair_list "}"
-- pair_list := pair ("," pair)*
-- pair := IDENT ":" IDENT
function Parser:parse_directive()
  self:expect("LBRACE", "Expected '{' to start directive")
  local pairs = {}

  local first = self:peek()
  if first.kind ~= "RBRACE" then
    repeat
      local key = self:expect("IDENT", "Expected key identifier in directive")
      self:expect("COLON", "Expected ':' after directive key")
      local val = self:expect("IDENT", "Expected value identifier in directive")
      table.insert(pairs, { kind = "pair", key = key.lexeme, value = val.lexeme })
    until not self:match("COMMA")
  end

  self:expect("RBRACE", "Expected '}' to close directive")

  return { kind = "directive", children = pairs }
end

-- text_chunk := TEXT | IDENT
function Parser:parse_text()
  local t = self:peek()
  if t.kind == "TEXT" or t.kind == "IDENT" then
    self:advance()
    return { kind = "text", value = t.lexeme }
  end
  error("Expected text, found " .. t.kind)
end

---@param input string
---@return table ast, table errors
function M.parse(input)
  local ok, ast_or_err = pcall(function()
    local tokens = tokenize(input)
    local p      = Parser:new(tokens)
    return p:parse_root()
  end)

  if not ok then
    return { kind = "root", children = {} }, { tostring(ast_or_err) }
  end

  return ast_or_err, {}
end

return M
