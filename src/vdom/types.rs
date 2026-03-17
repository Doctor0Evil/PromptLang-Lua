// src/vdom/types.rs

use serde::{Serialize, Deserialize};
use std::collections::HashMap;

pub type VirtualNodeId = String;

#[derive(Serialize, Deserialize, Clone, Copy, Debug, PartialEq, Eq)]
pub enum VirtualNodeKind {
    Canvas,
    Image,
    Control,
    Text,
    Container,
    SemanticGroup,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct VirtualMetrics {
    pub iei: f32,  // Interactive Expressiveness Index
    pub tis: f32,  // Transformable Intent Score
    pub eid: f32,  // Expressive Interaction Density
    pub par: f32,  // Prompt Anchoring Ratio
    pub ac: f32,   // Abstractability Coefficient
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct VirtualEventProfile {
    pub total_events: u64,
    pub session_touch_count: u32,
    pub last_event_timestamp_ms: Option<u64>,
    pub coordinated_events: u64,
    pub uncoordinated_events: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct PromptAnnotations {
    pub escape_targets: Vec<String>, // PromptLang escape ids targeting this node
    pub roles: Vec<String>,          // e.g. "brush", "latent-anchor"
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct VirtualNode {
    pub id: VirtualNodeId,
    pub kind: VirtualNodeKind,
    pub semantic_tags: Vec<String>,
    pub metrics: VirtualMetrics,
    pub event_profile: VirtualEventProfile,
    pub annotations: PromptAnnotations,
    pub children: Vec<VirtualNodeId>,
    pub parent: Option<VirtualNodeId>,
}
