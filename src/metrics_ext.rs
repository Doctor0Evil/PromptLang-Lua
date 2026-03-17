// PromptLang-Lua Repository
// File: src/metrics_ext.rs
//
// Extension metrics layered on top of existing VirtualMetrics / MetricEngine.
// These definitions are compatible with the prior vdomtypes.rs / metricsengine.rs
// design and are intended for sidecar / lab-style recomputation.

use serde::{Deserialize, Serialize};

/// Aggregate analyzer-style scores for a single prompt.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct AnalyzerScores {
    pub violence: f32,
    pub selfharm: f32,
    pub sexual: f32,
    pub hate: f32,
    pub adult: f32,
    pub emotional: f32,
    pub motion: f32,
    pub extreme: f32,
}

/// Summary of how the sanitizer rewrote a prompt.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct SanitizerSummary {
    pub original_text: String,
    pub sanitized_text: String,
    pub trigger_tokens: u32,
    pub replaced_tokens: u32,
    pub metaphor_tokens: u32,
    pub calm_tokens_added: u32,
    pub impact_tokens_removed: u32,
    pub safe_segments: u32,
    pub total_segments: u32,
}

/// Event-level summary for a node or session.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct EventSummary {
    pub total_events: u64,
    pub coordinated_events: u64,
    pub uncoordinated_events: u64,
    pub distinct_kinds: u32,
    pub distinct_sessions: u32,
    pub last_timestamp_ms: Option<u64>,
}

/// Long-horizon history used by some metrics (RIY, ESE, CPH).
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct HistorySummary {
    pub sanitized_prompts: u64,
    pub total_prompts: u64,
    pub abstract_successes: u64,
    pub kg_neighbors: u32,
    pub floodrouted_prompts: u64,
    pub flagged_prompts: u64,
    pub redirected_prompts: u64,
}

/// Node-level metrics beyond IEI/TIS/EID/PAR/AC.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct NodeExtendedMetrics {
    /// Existing core metrics, if you want to carry them.
    pub iei: f32,
    pub tis: f32,
    pub eid: f32,
    pub par: f32,
    pub ac: f32,
    /// Safety Transform Saturation (STS) – used by CPH.
    pub sts: f32,
    /// Pixel Knowledge Connectivity (PKC) – graph centrality or similar.
    pub pkc: f32,
}

/// Extended art-behavior metrics; one instance per prompt or node.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ArtBehaviorMetrics {
    /// Expressive Destruction Flux
    pub edf: f32,
    /// Harm-to-Color Divergence
    pub hcd: f32,
    /// Narrative Safety Gradient
    pub nsg: f32,
    /// Abstract Fireball Index
    pub afi: f32,
    /// Scene Fragmentation Ratio
    pub sfr: f32,
    /// Calm Recomposition Score
    pub crs: f32,
    /// Metaphor Saturation Coefficient
    pub msc: f32,
    /// Redirected Intent Yield
    pub riy: f32,
    /// Expressive Safety Envelope
    pub ese: f32,
    /// Colony Pattern Harmony
    pub cph: f32,
}

fn clamp01(x: f32) -> f32 {
    if x < 0.0 {
        0.0
    } else if x > 1.0 {
        1.0
    } else {
        x
    }
}

impl ArtBehaviorMetrics {
    /// Compute metrics for a single prompt or node using the
    /// provided analyzer, sanitizer, events, history, age band, and node metrics.
    pub fn compute(
        analyzer_before: &AnalyzerScores,
        analyzer_after: &AnalyzerScores,
        sanitizer: &SanitizerSummary,
        events: &EventSummary,
        history: &HistorySummary,
        age_band: Option<&str>,
        node_metrics: &NodeExtendedMetrics,
    ) -> Self {
        let analyzer = analyzer_after;

        let edf = {
            let emotional = analyzer.emotional;
            let destructive =
                (analyzer.violence.max(analyzer.selfharm)).max(analyzer.extreme);
            let amplitude = emotional;
            let flux = amplitude * destructive;

            let density_factor = if events.total_events > 0 {
                (events.total_events as f32 / 20.0).min(1.0)
            } else {
                1.0
            };

            clamp01(flux * density_factor)
        };

        let hcd = {
            let triggers = sanitizer.trigger_tokens as f32;
            if triggers <= 0.0 {
                0.0
            } else {
                let replaced = sanitizer.replaced_tokens as f32;
                let metaphors = sanitizer.metaphor_tokens as f32;
                let calm_added = sanitizer.calm_tokens_added as f32;

                let base_ratio = replaced / triggers;
                let metaphor_boost = metaphors / triggers.max(1.0);
                let calm_boost = calm_added / replaced.max(1.0);

                clamp01(0.6 * base_ratio + 0.25 * metaphor_boost + 0.15 * calm_boost)
            }
        };

        let nsg = {
            let danger = |a: &AnalyzerScores| {
                a.violence
                    .max(a.selfharm)
                    .max(a.sexual)
                    .max(a.hate)
            };

            let d0 = danger(analyzer_before);
            let d1 = danger(analyzer_after);

            if d0 <= 0.0 {
                0.0
            } else {
                let gradient = (d0 - d1) / d0.max(1e-6);
                clamp01(gradient)
            }
        };

        let afi = {
            let destructive = analyzer.violence.max(analyzer.selfharm);
            let motion = analyzer.motion;
            let amplitude = analyzer.emotional;

            let triggers = sanitizer.trigger_tokens as f32;
            let conversion = if triggers > 0.0 {
                sanitizer.replaced_tokens as f32 / triggers
            } else {
                0.0
            };

            let diversity = (events.distinct_kinds as f32 / 4.0).min(1.0);

            let score = 0.35 * destructive
                + 0.25 * motion
                + 0.20 * amplitude
                + 0.10 * conversion
                + 0.10 * diversity;

            clamp01(score)
        };

        let sfr = {
            let total = sanitizer.total_segments as f32;
            if total <= 0.0 {
                0.0
            } else {
                clamp01(sanitizer.safe_segments as f32 / total)
            }
        };

        let crs = {
            let calm_added = sanitizer.calm_tokens_added as f32;
            let impact_removed = sanitizer.impact_tokens_removed as f32;
            let total_delta = calm_added + impact_removed;

            if total_delta <= 0.0 {
                0.0
            } else {
                let calm_ratio = calm_added / total_delta;

                let emo_before = analyzer_before.emotional;
                let emo_after = analyzer_after.emotional;

                let preserved = if emo_before > 0.0 {
                    (emo_after / emo_before).min(1.0)
                } else {
                    emo_after
                };

                clamp01(0.7 * calm_ratio + 0.3 * preserved)
            }
        };

        let msc = {
            let triggers = sanitizer.trigger_tokens as f32;
            if triggers <= 0.0 {
                0.0
            } else {
                let metaphors = sanitizer.metaphor_tokens as f32;
                clamp01(metaphors / triggers)
            }
        };

        let riy = {
            let flagged = history.flagged_prompts as f32;
            if flagged <= 0.0 {
                0.0
            } else {
                clamp01(history.redirected_prompts as f32 / flagged)
            }
        };

        let ese = {
            let destructive = analyzer.violence.max(analyzer.selfharm);
            let emo = analyzer.emotional;

            let band_factor = match age_band.unwrap_or("ADULT") {
                "CHILD" => 0.25,
                "YOUNGTEEN" => 0.4,
                "TEEN" => 0.6,
                _ => 1.0,
            };

            let interactive_scale =
                (events.total_events as f32 / 50.0).min(1.0);

            let totalp = history.total_prompts as f32;
            let safety_history = if totalp > 0.0 {
                let floods = history.floodrouted_prompts as f32;
                1.0 - (floods / totalp).min(1.0)
            } else {
                1.0
            };

            let mut raw = (1.0 - destructive) * 0.5 + emo * 0.3 + interactive_scale * 0.2;
            raw *= band_factor * safety_history;

            clamp01(raw)
        };

        let cph = {
            let iei = node_metrics.iei;
            let tis = node_metrics.tis;
            let eid = node_metrics.eid;
            let sts = node_metrics.sts;
            let pkc = node_metrics.pkc;

            let stability = 1.0 - sts;
            let cohesion = (iei + eid + pkc) / 3.0;

            let score = 0.4 * cohesion + 0.4 * stability + 0.2 * tis;
            clamp01(score)
        };

        Self {
            edf,
            hcd,
            nsg,
            afi,
            sfr,
            crs,
            msc,
            riy,
            ese,
            cph,
        }
    }
}
