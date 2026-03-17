// src/metrics/types.rs
#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct SafetySignals {
    pub emotional_intensity: f32,   // 0–1
    pub danger_violence: f32,       // 0–1
    pub danger_self_harm: f32,      // 0–1
    pub danger_sexual: f32,         // 0–1
    pub danger_hate: f32,           // 0–1
    pub metaphor_ratio: f32,        // 0–1
    pub scene_fragments_total: u32,
    pub scene_fragments_danger: u32,
    pub colony_harmony_raw: f32,    // 0–1, game/colony analyzer
}

#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct AgeBandCaps {
    pub max_edf: f32,
    pub max_afi: f32,
    pub max_overall_danger: f32,
}

#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct VirtualMetrics2 {
    pub edf: f32,
    pub hcd: f32,
    pub nsg: f32,
    pub afi: f32,
    pub sfr: f32,
    pub crs: f32,
    pub msc: f32,
    pub riy: f32,
    pub ese: f32,
    pub cph: f32,
}
