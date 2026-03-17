// src/metrics/api.rs

use wasm_bindgen::prelude::*;
use crate::vdom::graph::VirtualGraph;
use crate::metrics::events::EventStore;
use crate::metrics::engine::MetricEngine;

static mut GRAPH: Option<VirtualGraph> = None;
static mut EVENTS: Option<EventStore> = None;

#[wasm_bindgen]
pub fn lab_record_event(ev_json: &str) -> Result<(), JsValue> {
    let ev: crate::metrics::events::VirtualEvent =
        serde_json::from_str(ev_json).map_err(|e| JsValue::from_str(&format!("{e}")))?;
    unsafe {
        if EVENTS.is_none() {
            EVENTS = Some(EventStore::default());
        }
        if let Some(store) = EVENTS.as_mut() {
            store.record(ev);
        }
    }
    Ok(())
}

#[wasm_bindgen]
pub fn lab_recompute_metrics() -> Result<(), JsValue> {
    unsafe {
        let graph = GRAPH.as_mut().ok_or_else(|| JsValue::from_str("GRAPH not init"))?;
        let events = EVENTS.as_ref().ok_or_else(|| JsValue::from_str("EVENTS not init"))?;
        let mut engine = MetricEngine::new(graph, events);
        engine.recompute_all();
    }
    Ok(())
}
