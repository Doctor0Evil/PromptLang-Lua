// PromptLang-Lua Repository
// File: src/art_metrics.rs

use serde::{Deserialize, Serialize};

/// High-level age bands, parallel to Lua's modules/agegate/agegate.lua
#[derive(Clone, Copy, Debug, Serialize, Deserialize)]
pub enum AgeBand {
    Child,
    YoungTeen,
    Teen,
    Adult,
}

/// Summarized analyzer scores for a single prompt.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct AnalyzerScores {
    pub emotional_intensity: f32,
    pub destructive_intent: f32,
    pub danger_violence: f32,
    pub danger_self_harm: f32,
    pub danger_hate: f32,
    pub danger_other: f32,
    pub pre_safety_danger: f32,
    pub post_safety_danger: f32,
}

/// Summarized sanitizer statistics for a single prompt.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct SanitizerSummary {
    pub replaced_tokens: u32,
    pub metaphor_tokens: u32,
    pub calm_tokens: u32,
    pub impact_tokens: u32,
    pub safe_segments: u32,
    pub total_segments: u32,
    pub trigger_tokens: u32,
}

/// Session-level history and context.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct SessionSummary {
    pub flagged_prompts: u32,
    pub redirected_prompts: u32,
    pub floodrouted_prompts: u32,
    pub total_prompts: u32,
    pub total_events: u32,
    pub age_band: AgeBand,
}

/// Aggregate “colony” inputs from the virtual graph.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ColonyInputs {
    pub node_iei: f32,
    pub node_sts: f32,
    pub node_pkc: f32,
    pub conflict_ratio: f32,
}

/// Art behavior metrics, serialized into the VirtualNode / VirtualObject snapshots.
#[derive(Clone, Copy, Debug, Default, Serialize, Deserialize)]
pub struct ArtBehaviorMetrics {
    pub edf: f32, // Expressive Destruction Flux
    pub afi: f32, // Abstract Fireball Index
    pub hcd: f32, // Harm-to-Color Divergence
    pub nsg: f32, // Narrative Safety Gradient
    pub sfr: f32, // Scene Fragmentation Ratio
    pub crs: f32, // Calm Recomposition Score
    pub msc: f32, // Metaphor Saturation Coefficient
    pub riy: f32, // Redirected Intent Yield
    pub ese: f32, // Expressive Safety Envelope
    pub cph: f32, // Colony Pattern Harmony
}

/// Helper: clamp to [0, 1].
fn clamp01(x: f32) -> f32 {
    if x < 0.0 {
        0.0
    } else if x > 1.0 {
        1.0
    } else {
        x
    }
}

/// Helper: ratio in [0, 1] with safe division.
fn safe_ratio(num: u32, denom: u32) -> f32 {
    if denom == 0 {
        0.0
    } else {
        clamp01(num as f32 / denom as f32)
    }
}

fn any_danger_saturated(a: &AnalyzerScores) -> bool {
    let m = a
        .danger_violence
        .max(a.danger_self_harm)
        .max(a.danger_hate)
        .max(a.danger_other);
    m >= 0.9
}

fn boosted_emotion(e: f32) -> f32 {
    if e >= 0.7 {
        clamp01(e * e)
    } else {
        clamp01(e)
    }
}

/// EDF: nonlinear product of boosted emotion and destructive intent,
/// hard-saturated if any danger channel crosses 0.9.
fn compute_edf(a: &AnalyzerScores) -> f32 {
    if any_danger_saturated(a) {
        return 0.95;
    }
    let e = boosted_emotion(a.emotional_intensity);
    let d = clamp01(a.destructive_intent);
    clamp01(e * d)
}

/// AFI: abstract fireball index; like EDF but biased slightly higher
/// to favor abstract, high-energy scenes when safe.
fn compute_afi(a: &AnalyzerScores) -> f32 {
    if any_danger_saturated(a) {
        return 0.95;
    }
    let e = boosted_emotion(a.emotional_intensity);
    let d = clamp01(a.destructive_intent);
    let base = clamp01(e * d);
    clamp01(base * 1.1)
}

/// HCD: lexical harm converted into metaphor / color / motion.
fn compute_hcd(s: &SanitizerSummary) -> f32 {
    let useful = s.metaphor_tokens + s.replaced_tokens;
    let denom = s.trigger_tokens.saturating_add(1);
    safe_ratio(useful, denom)
}

/// NSG: drop in danger score between original and sanitized prompt, normalized to [0,1].
fn compute_nsg(a: &AnalyzerScores) -> f32 {
    let before = clamp01(a.pre_safety_danger);
    let after = clamp01(a.post_safety_danger);

    if before <= 0.0 {
        // No initial risk: neutral gradient.
        0.5
    } else {
        let delta = (before - after).max(-1.0).min(1.0);
        // Map “no change” to 0.5, full reduction to 1.0, increase to 0.0.
        let normalized = ((delta / before) + 1.0) * 0.5;
        clamp01(normalized)
    }
}

/// SFR: fraction of prompt that is safe, independently visualizable segments.
fn compute_sfr(s: &SanitizerSummary) -> f32 {
    safe_ratio(s.safe_segments, s.total_segments.saturating_add(0))
}

/// CRS: calm recomposition; prefers calm-heavy but not impact-free prompts.
fn compute_crs(s: &SanitizerSummary) -> f32 {
    let calm = s.calm_tokens as f32;
    let impact = s.impact_tokens as f32;

    if calm <= 0.0 {
        return 0.0;
    }

    let balance = if impact <= 0.0 {
        0.5
    } else {
        clamp01(calm / (calm + impact))
    };

    clamp01(balance + 0.25)
}

/// MSC: metaphor density vs explicit harmful triggers.
fn compute_msc(s: &SanitizerSummary) -> f32 {
    let denom = s.metaphor_tokens + s.trigger_tokens;
    safe_ratio(s.metaphor_tokens, denom)
}

/// RIY: proportion of flagged prompts redirected into art instead of denied.
fn compute_riy(sess: &SessionSummary) -> f32 {
    safe_ratio(sess.redirected_prompts, sess.flagged_prompts.saturating_add(0))
}

fn age_scale(age_band: AgeBand) -> f32 {
    match age_band {
        AgeBand::Child => 0.25,
        AgeBand::YoungTeen => 0.40,
        AgeBand::Teen => 0.60,
        AgeBand::Adult => 1.00,
    }
}

/// ESE: per-session safety envelope scalar in [0,1], where 1 is generous and 0 is tight.
fn compute_ese(a: &AnalyzerScores, sess: &SessionSummary) -> f32 {
    let base_intent = clamp01(a.destructive_intent);
    let age_factor = age_scale(sess.age_band);

    let events = sess.total_events as f32;
    let event_factor = if events <= 1.0 {
        1.0
    } else {
        // Log-style compression; clamp between 0.4 and 1.0.
        let v = 1.0 / (1.0 + (events / 50.0).ln());
        v.max(0.4).min(1.0)
    };

    let total_prompts = sess.total_prompts.max(1) as f32;
    let flood_ratio = sess.floodrouted_prompts as f32 / total_prompts;
    let history_factor = (1.0 - flood_ratio).max(0.2);

    let raw_risk = base_intent * age_factor * event_factor * history_factor;
    clamp01(1.0 - raw_risk)
}

/// CPH: colony pattern harmony; combines expressiveness, safety, and saturation.
fn compute_cph(c: &ColonyInputs) -> f32 {
    let iei = clamp01(c.node_iei);
    let sts = clamp01(c.node_sts);
    let pkc = clamp01(c.node_pkc);
    let conflict = clamp01(c.conflict_ratio);

    let expressiveness = (iei + pkc) * 0.5;
    let safety = 1.0 - conflict;

    // Mild penalty if STS extreme (too low or too high).
    let centered = (sts - 0.5).abs() * 2.0; // 0 at 0.5, 1 at 0 or 1
    let saturation_penalty = clamp01(centered);
    let saturation_factor = 1.0 - 0.3 * saturation_penalty;

    clamp01(expressiveness * safety * saturation_factor)
}

impl ArtBehaviorMetrics {
    /// Pure, allocation-light computation for a single prompt + session + colony snapshot.
    pub fn compute(
        analyzer: &AnalyzerScores,
        sanitizer: &SanitizerSummary,
        session: &SessionSummary,
        colony: &ColonyInputs,
    ) -> ArtBehaviorMetrics {
        ArtBehaviorMetrics {
            edf: compute_edf(analyzer),
            afi: compute_afi(analyzer),
            hcd: compute_hcd(sanitizer),
            nsg: compute_nsg(analyzer),
            sfr: compute_sfr(sanitizer),
            crs: compute_crs(sanitizer),
            msc: compute_msc(sanitizer),
            riy: compute_riy(session),
            ese: compute_ese(analyzer, session),
            cph: compute_cph(colony),
        }
    }
}
