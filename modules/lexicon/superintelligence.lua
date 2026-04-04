-- modules/lexicon/superintelligence.lua
local utils = require "lib.utils"   -- you already have a utils module.[file:4]
local json  = require "dkjson"      -- or your preferred JSON lib.

local M = {}
local entries_by_id      = {}
local entries_by_cat     = {}
local macro_to_micro_map = {}

local function add_entry(e)
  if not e.id then return end
  entries_by_id[e.id] = e

  local cat = e.category or "misc"
  entries_by_cat[cat] = entries_by_cat[cat] or {}
  table.insert(entries_by_cat[cat], e)

  if e.pair_with then
    macro_to_micro_map[e.pair_with] = macro_to_micro_map[e.pair_with] or {}
    table.insert(macro_to_micro_map[e.pair_with], e.id)
  end
end

local function load_file(path)
  local fh = assert(io.open(path, "r"))
  local text = fh:read("*a")
  fh:close()

  for block in text:gmatch("```lex(.-)```") do
    local trimmed = block:gsub("^%s+", ""):gsub("%s+$", "")
    local obj, pos, err = json.decode(trimmed, 1, nil)
    if obj and type(obj) == "table" then
      add_entry(obj)
    else
      utils.log("warn", "lexicon-superintelligence: JSON decode error: " .. tostring(err))
    end
  end
end

function M.init(cfg)
  -- cfg.lexicon_path can override default if needed.
  local path = (cfg and cfg.lexicon_path) or "docs/lexicon-superintelligence.md"
  load_file(path)
  return true
end

function M.get(id)
  return entries_by_id[id]
end

function M.by_category(cat)
  return entries_by_cat[cat] or {}
end

function M.micros_for_macro(id)
  return macro_to_micro_map[id] or {}
end

-- Simple picker for prompt-building, respecting Scale Balance principle.
function M.pick_pair(cat_macro, rng)
  local macros = entries_by_cat[cat_macro] or {}
  if #macros == 0 then return nil, nil end
  local idx = (rng and rng(#macros)) or math.random(#macros)
  local macro = macros[idx]

  local micro_ids = macro_to_micro_map[macro.id] or {}
  local micro
  if #micro_ids > 0 then
    local midx = (rng and rng(#micro_ids)) or math.random(#micro_ids)
    micro = entries_by_id[micro_ids[midx]]
  end

  return macro, micro
end

return M
