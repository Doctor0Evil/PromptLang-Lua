// src/metrics/engine.rs

use std::collections::{HashMap, HashSet};
use crate::vdom::graph::VirtualGraph;
use crate::metrics::events::{EventStore, EventKind};

pub struct MetricEngine<'a> {
    pub graph: &'a mut VirtualGraph,
    pub events: &'a EventStore,
}

impl<'a> MetricEngine<'a> {
    pub fn new(graph: &'a mut VirtualGraph, events: &'a EventStore) -> Self {
        Self { graph, events }
    }

    pub fn recompute_all(&mut self) {
        // Pre-aggregate per node for efficiency.
        let mut per_node_events: HashMap<String, Vec<&_>> = HashMap::new();
        for ev in &self.events.events {
            per_node_events
                .entry(ev.node_id.clone())
                .or_default()
                .push(ev);
        }

        for (id, node) in self.graph.nodes.iter_mut() {
            let evs = per_node_events.get(id);
            if let Some(evs) = evs {
                let mut kinds: HashSet<&str> = HashSet::new();
                let mut sessions: HashSet<&str> = HashSet::new();
                let mut coordinated = 0u64;
                let mut uncoordinated = 0u64;
                let mut last_ts = 0u64;

                for e in evs {
                    match &e.event_kind {
                        EventKind::Custom(s) => { kinds.insert(s.as_str()); }
                        _ => { kinds.insert(""); } // treat built-ins as one bucket
                    }
                    sessions.insert(e.session_id.as_str());
                    if e.coordinated { coordinated += 1; } else { uncoordinated += 1; }
                    if e.timestamp_ms > last_ts { last_ts = e.timestamp_ms; }
                }

                let total = (coordinated + uncoordinated) as f32;
                let k = kinds.len() as f32;
                let s = sessions.len() as f32;

                // Expressive Interaction Density (EID)
                let eid = if s > 0.0 { k / (1.0 + s.ln()) } else { 0.0 };

                // Prompt Anchoring Ratio (PAR): crude placeholder; rely on annotations length
                let anchors = node.annotations.escape_targets.len() as f32;
                let par = if total > 0.0 { anchors / (1.0 + total) } else { 0.0 };

                // IEI: combine event diversity and volume, normalized to [0, 1]
                let iei_raw = (k / 5.0).min(1.0) * (1.0 - (1.0 / (1.0 + total / 10.0)));
                let iei = iei_raw.max(0.0).min(1.0);

                // TIS: more coordinated use + anchors implies easier transformation
                let tis_raw = if total > 0.0 {
                    (coordinated as f32 / total) * 0.6 + par * 0.4
                } else {
                    0.0
                };
                let tis = tis_raw.max(0.0).min(1.0);

                // Abstractability Coefficient (AC) as a function of TIS and EID.
                let ac = (tis * 0.7 + (eid / 3.0) * 0.3).max(0.0).min(1.0);

                node.metrics.iei = iei;
                node.metrics.tis = tis;
                node.metrics.eid = eid;
                node.metrics.par = par;
                node.metrics.ac = ac;

                node.event_profile.total_events = (coordinated + uncoordinated) as u64;
                node.event_profile.session_touch_count = sessions.len() as u32;
                node.event_profile.coordinated_events = coordinated;
                node.event_profile.uncoordinated_events = uncoordinated;
                node.event_profile.last_event_timestamp_ms = if last_ts > 0 { Some(last_ts) } else { None };
            }
        }
    }
}
