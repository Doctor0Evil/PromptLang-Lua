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
