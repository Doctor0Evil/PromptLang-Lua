## 1. High‑level shape of the horror style system

At the top level, treat “horror style” as a decodable bundle with four synchronized layers: a scalar metric vector (WMP, NSG, TDI, etc.), a compact, ordered hex palette, a minimal style‑token string, and a seed/stylemap reference set. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/aaf55075-0482-42d1-a141-6d7a5107f059/this-research-focuses-on-desig-cE.cn2TIQLCVRTZYZ_ynyQ.md)

In Rust terms, you can define a pure, allocation‑light struct parallel to `ArtBehaviorMetrics`:

```rust
// PromptLang-Lua Repository
// File: srchorror_style.rs

use serde::{Serialize, Deserialize};

/// Horror style family identifiers for taxonomy routing.
#[derive(Clone, Copy, Debug, Serialize, Deserialize)]
pub enum HorrorFamily {
    CosmicDecay,
    AnalogGhoul,
    WaxMeltUrban,
    FolkDread,
    BodySignalNoise,
    Other,
}

/// Style metrics: single, normalized vector per style.
#[derive(Clone, Copy, Debug, Default, Serialize, Deserialize)]
pub struct HorrorStyleMetrics {
    /// Weighted Mist Presence – how much fog, haze, particulate depth.
    pub wmp: f32,
    /// Narrative Safety Gradient – reused from core metrics, but scoped to horror framing.
    pub nsg: f32,
    /// Temporal Distortion Index – how strongly time feels warped, looped, or broken.
    pub tdi: f32,
    /// Signal Noise Factor – analog static, scanlines, film grain, spectral artifacts.
    pub snf: f32,
    /// Flesh/Structure Melt Ratio – degree of sagging, dripping, wax‑like decay.
    pub fsm: f32,
}

/// Compact, ordered palette of measured hex colors for this style.
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct HorrorPalette {
    /// Dominant background hex (e.g. sky/fog).
    pub bg: String,
    /// Primary subject midtone.
    pub mid: String,
    /// Accent/emissive color (eyes, runes, LEDs).
    pub accent: String,
    /// Ground/structural tone (soil, concrete, rot).
    pub ground: String,
}

/// Seed and stylemap references – platform-agnostic, but reproducible.
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct HorrorSeedRefs {
    /// Optional numeric seed for engines that expose it.
    pub numeric_seed: Option<u64>,
    /// Optional engine-native style string, never executed directly.
    pub engine_style_tag: Option<String>,
    /// Opaque, hashed reference to a canonical reference image or tile.
    pub ref_image_id: Option<String>,
}

/// A fully decodable horror style definition.
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct HorrorStyleDef {
    pub id: String,
    pub version: u32,
    pub family: HorrorFamily,
    pub metrics: HorrorStyleMetrics,
    pub palette: HorrorPalette,
    /// Minimal PromptLang-Lua art-string that describes this style.
    pub art_string: String,
    /// Safe, engine-specific hints and seeds.
    pub seeds: HorrorSeedRefs,
}
```

This keeps horror styles as pure data: host engines can serialize `HorrorStyleDef` into JSON, store it in logs, and ship it to Lua in the same snapshot that already carries `ArtBehaviorMetrics` and `VirtualMetrics`. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/5edcf7ac-19b8-449e-bbce-3ae5c6e24dff/how-can-we-research-a-design-m-Qmq1ZM8BTpeUZ1R2xbq6AQ.md)

## 2. Lua‑side decoding and routing surface

On the Lua side, mirror the struct with a small, pure decoding module that accepts only JSON or pre‑trusted tables, never raw code. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/ae2f3889-d777-4fd2-bc59-66093791e04f/this-research-focuses-on-refin-lsKGegvaTReYeZj16ZlzCw.md)

```lua
-- PromptLang-Lua Repository
-- File: modules/styles/horror_style.lua

local M = {}

local function clamp01(x)
  if x < 0.0 then return 0.0 end
  if x > 1.0 then return 1.0 end
  return x
end

local function validate_palette(p)
  if type(p) ~= "table" then return nil, "palette must be table" end
  -- Simple hex sanity: "#RRGGBB"
  local function ok_hex(s)
    return type(s) == "string" and s:match("^#%x%x%x%x%x%x$")
  end
  if not ok_hex(p.bg) then return nil, "invalid bg hex" end
  if not ok_hex(p.mid) then return nil, "invalid mid hex" end
  if not ok_hex(p.accent) then return nil, "invalid accent hex" end
  if not ok_hex(p.ground) then return nil, "invalid ground hex" end
  return {
    bg = p.bg,
    mid = p.mid,
    accent = p.accent,
    ground = p.ground,
  }
end

--- Decode a HorrorStyleDef from a plain Lua table (e.g. JSON-decoded).
--- Returns style, err.
function M.decode(tbl)
  if type(tbl) ~= "table" then
    return nil, "style must be table"
  end
  local metrics = tbl.metrics or {}
  local palette_raw = tbl.palette or {}
  local palette, perr = validate_palette(palette_raw)
  if not palette then return nil, perr end

  local style = {
    id      = tbl.id or "unknown",
    version = tbl.version or 1,
    family  = tbl.family or "Other",
    metrics = {
      wmp = clamp01(metrics.wmp or 0.0),
      nsg = clamp01(metrics.nsg or 0.5),
      tdi = clamp01(metrics.tdi or 0.0),
      snf = clamp01(metrics.snf or 0.0),
      fsm = clamp01(metrics.fsm or 0.0),
    },
    palette   = palette,
    art_string = tbl.art_string or "",
    seeds = {
      numeric_seed   = tbl.seeds and tbl.seeds.numeric_seed or nil,
      engine_style_tag = tbl.seeds and tbl.seeds.engine_style_tag or nil,
      ref_image_id   = tbl.seeds and tbl.seeds.ref_image_id or nil,
    },
  }

  return style, nil
end

--- Project the style into a minimal PromptLang-Lua art token string
--- suitable for use inside escape sequences.
function M.to_token(style)
  local m  = style.metrics
  local fam = style.family
  -- Example compressed token: HORROR:CosmicDecay:wmp0.8:tdi0.6:snf0.7
  return string.format(
    "HORROR:%s:wmp%.2f:tdi%.2f:snf%.2f:fsm%.2f",
    tostring(fam),
    m.wmp, m.tdi, m.snf, m.fsm
  )
end

--- Return an approximate, engine-agnostic language description for the style.
function M.to_prompt_suffix(style)
  local fam = style.family
  local m   = style.metrics
  local p   = style.palette

  if fam == "CosmicDecay" then
    return string.format(
      "cosmic horror, eroded planets, %s mist, %s sky, granular starlight haze, time-warped perspective, subtle analog noise",
      p.ground, p.bg
    )
  elseif fam == "AnalogGhoul" then
    return "grainy analog videotape, desaturated hallway, silhouetted figure, scanlines, ghostly bloom, off-kilter framing"
  elseif fam == "WaxMeltUrban" then
    return string.format(
      "urban night alley, sodium-vapor %s highlights, buildings sagging like melting wax, reflective puddles, dripping signage",
      p.accent
    )
  else
    return "moody horror atmosphere, deep shadows, restrained palette, slow-building dread"
  end
end

return M
```

This gives PromptLang‑Lua a stable horror style interface: decode a style, turn it into a minimal token (`M.to_token`), and generate a cross‑platform, text‑only suffix that approximates the style when explicit hex support is unavailable. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/aaf55075-0482-42d1-a141-6d7a5107f059/this-research-focuses-on-desig-cE.cn2TIQLCVRTZYZ_ynyQ.md)

## 3. Taxonomy: mapping horror families to metrics and palettes

To make the system extensible across “cosmic decay, analog ghoul silhouettes, wax‑melt urban horror, and others,” define canonical family profiles as data only, not code. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/5edcf7ac-19b8-449e-bbce-3ae5c6e24dff/how-can-we-research-a-design-m-Qmq1ZM8BTpeUZ1R2xbq6AQ.md)

```lua
-- PromptLang-Lua Repository
-- File: modules/styles/horror_families.lua

local HorrorStyle = require("modules.styles.horror_style")

local FAMILIES = {
  CosmicDecay = {
    id = "horror.cosmic_decay.v1",
    version = 1,
    family = "CosmicDecay",
    metrics = { wmp = 0.9, nsg = 0.4, tdi = 0.8, snf = 0.3, fsm = 0.5 },
    palette = {
      bg     = "#071814", -- near-black teal
      mid    = "#243626",
      accent = "#D2E38F", -- sickly pale yellow star/mist
      ground = "#2B130C",
    },
    art_string = "TerraScape::cosmic_decay",
    seeds = { numeric_seed = nil, engine_style_tag = nil, ref_image_id = nil },
  },
  AnalogGhoul = {
    id = "horror.analog_ghoul.v1",
    version = 1,
    family = "AnalogGhoul",
    metrics = { wmp = 0.6, nsg = 0.5, tdi = 0.4, snf = 0.9, fsm = 0.2 },
    palette = {
      bg     = "#0B0B10",
      mid    = "#30333A",
      accent = "#F5F5F5",
      ground = "#1A1A1F",
    },
    art_string = "VHS_Ghoul::hallway_silhouette",
  },
  WaxMeltUrban = {
    id = "horror.wax_melt_urban.v1",
    version = 1,
    family = "WaxMeltUrban",
    metrics = { wmp = 0.3, nsg = 0.5, tdi = 0.5, snf = 0.5, fsm = 0.9 },
    palette = {
      bg     = "#050509",
      mid    = "#3B2A2A",
      accent = "#FFB44C", -- sodium vapor
      ground = "#1F1414",
    },
    art_string = "MeltCity::dripping_facades",
  },
}

local M = {}

function M.get(id_or_family)
  local raw = FAMILIES[id_or_family] or FAMILIES[id_or_family:gsub("^horror%.", "")] or nil
  if not raw then return nil, "unknown horror family: " .. tostring(id_or_family) end
  return HorrorStyle.decode(raw)
end

return M
```

Any engine can import these JSON‑equivalent structs, recompute metrics, and override palettes as needed while retaining compatibility through the shared fields. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/ae2f3889-d777-4fd2-bc59-66093791e04f/this-research-focuses-on-refin-lsKGegvaTReYeZj16ZlzCw.md)

## 4. Logging and experiment‑and‑measure loop

To support the “experiment and measure” loop, attach horror style fields to your existing per‑prompt log/metrics types and treat them as first‑class numeric features alongside EDF/AFI/ESE. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/5edcf7ac-19b8-449e-bbce-3ae5c6e24dff/how-can-we-research-a-design-m-Qmq1ZM8BTpeUZ1R2xbq6AQ.md)

Extend the per‑prompt metric input:

```rust
// File: src/metrics/horror_inputs.rs

use serde::{Serialize, Deserialize};
use crate::artmetrics::{AnalyzerScores, SanitizerSummary, SessionSummary};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct HorrorStyleLog {
    pub style_id: String,
    pub family: HorrorFamily,
    pub metrics: HorrorStyleMetrics,
    pub palette: HorrorPalette,
    pub art_token: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct HorrorPromptMetrics {
    pub analyzer: AnalyzerScores,
    pub sanitizer: SanitizerSummary,
    pub session: SessionSummary,
    pub horror_style: Option<HorrorStyleLog>,
}
```

Then your lab engine (which already recomputes IEI/TIS and ArtBehaviorMetrics) can ingest `HorrorPromptMetrics`, correlate horror styles with safety outcomes, and iteratively refine WMP/NSG/TDI ranges and palette selections. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/ae2f3889-d777-4fd2-bc59-66093791e04f/this-research-focuses-on-refin-lsKGegvaTReYeZj16ZlzCw.md)

All artifacts remain plain structs/JSON: nothing is executable, and everything can be audited or replayed without risk.

## 5. Cross‑platform fidelity: hex vs. text approximation

To satisfy both “direct hex specification” and “text‑based approximations backed by reference images,” use a dual‑channel render plan per horror style. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/aaf55075-0482-42d1-a141-6d7a5107f059/this-research-focuses-on-desig-cE.cn2TIQLCVRTZYZ_ynyQ.md)

In Lua, expose a helper that computes a safe, engine‑ready style suffix:

```lua
-- File: modules/styles/horror_render.lua

local Style = require("modules.styles.horror_style")

local M = {}

--- Build an engine-neutral horror style suffix, with optional hex tokens.
--- engine_caps: { allow_hex = true/false }
function M.to_engine_suffix(style, engine_caps)
  local base = Style.to_prompt_suffix(style)
  local p    = style.palette

  if engine_caps and engine_caps.allow_hex then
    -- Inline explicit hex hints for engines that support color tags.
    return string.format(
      "%s, bg %s, mid %s, accent %s, ground %s",
      base, p.bg, p.mid, p.accent, p.ground
    )
  else
    -- Describe colors textually without raw hex.
    return base .. ", muted teal-black sky, bruised earth tones, sickly pale highlights"
  end
end

return M
```

Platforms with strict safety or markup constraints can use only the textual description, while others can consume the measured hex palette directly. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/aaf55075-0482-42d1-a141-6d7a5107f059/this-research-focuses-on-desig-cE.cn2TIQLCVRTZYZ_ynyQ.md)

## 6. Style tokens and seeds as PromptLang‑Lua art‑strings

Finally, encode each horror style as a compact PromptLang‑Lua art‑string that is safe to embed in escape sequences and trivial to decode back into metrics. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/5edcf7ac-19b8-449e-bbce-3ae5c6e24dff/how-can-we-research-a-design-m-Qmq1ZM8BTpeUZ1R2xbq6AQ.md)

For example, `TerraScape` could be represented in a PromptLang block as:

```text
[horror style=TerraScape family=CosmicDecay wmp=0.88 tdi=0.81 snf=0.34 fsm=0.52
 palette_bg=#071814 palette_mid=#243626 palette_accent=#D2E38F palette_ground=#2B130C
 ref=hp://horror.place/terrascape/v1 ]
```

Your existing DSL parser (`libparser.lua`) can read this into a small `HorrorStyleDef`, then surface it through the `horror_style.lua` module so routing, safety, and art modules all see the same numeric vector, palette, and token string. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_93a154a5-dc2a-497e-afd9-cde265053430/5edcf7ac-19b8-449e-bbce-3ae5c6e24dff/how-can-we-research-a-design-m-Qmq1ZM8BTpeUZ1R2xbq6AQ.md)

That gives you a single, unified horror style framework: one struct model across Rust and Lua, normalized scalar metrics aligned with your existing art‑behavior metrics, measured hex palettes that can be used or approximated per platform, and minimal style token strings that log cleanly and route without ever executing untrusted content.
