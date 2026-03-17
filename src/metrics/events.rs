// src/metrics/events.rs

use serde::{Serialize, Deserialize};
use std::collections::HashMap;
use crate::vdom::types::VirtualNodeId;

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum EventKind {
    Click,
    Hover,
    Drag,
    Key,
    Scroll,
    Custom(String),
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct VirtualEvent {
    pub node_id: VirtualNodeId,
    pub event_kind: EventKind,
    pub timestamp_ms: u64,
    pub session_id: String,
    pub coordinated: bool, // true if tied to a PromptLang run
}

#[derive(Default)]
pub struct EventStore {
    pub events: Vec<VirtualEvent>,
}

impl EventStore {
    pub fn record(&mut self, ev: VirtualEvent) {
        self.events.push(ev);
    }

    pub fn events_for_node(&self, id: &str) -> impl Iterator<Item = &VirtualEvent> {
        self.events.iter().filter(move |e| e.node_id == id)
    }
}
