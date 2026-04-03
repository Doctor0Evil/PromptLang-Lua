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
