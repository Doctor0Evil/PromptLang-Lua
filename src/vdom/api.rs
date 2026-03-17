// src/vdom/api.rs

use wasm_bindgen::prelude::*;
use serde::{Serialize, Deserialize};
use super::graph::VirtualGraph;
use super::types::*;

static mut GRAPH: Option<VirtualGraph> = None;

#[derive(Serialize, Deserialize)]
pub struct QuerySpec {
    pub tag: Option<String>,
    pub metric: Option<String>,
    pub min: Option<f32>,
    pub max: Option<f32>,
}

#[derive(Serialize, Deserialize)]
pub struct NodeSnapshot {
    pub node: VirtualNode,
}

#[wasm_bindgen]
pub fn vdom_init(json_graph: &str) -> Result<(), JsValue> {
    let graph: VirtualGraph = serde_json::from_str(json_graph)
        .map_err(|e| JsValue::from_str(&format!("parse error: {e}")))?;
    unsafe { GRAPH = Some(graph); }
    Ok(())
}

#[wasm_bindgen]
pub fn vdom_snapshot() -> Result<JsValue, JsValue> {
    unsafe {
        let graph = GRAPH.as_ref().ok_or_else(|| JsValue::from_str("GRAPH not init"))?;
        JsValue::from_serde(&graph).map_err(|e| JsValue::from_str(&format!("{e}")))
    }
}

#[wasm_bindgen]
pub fn vdom_query(spec_json: &str) -> Result<JsValue, JsValue> {
    let spec: QuerySpec = serde_json::from_str(spec_json)
        .map_err(|e| JsValue::from_str(&format!("parse error: {e}")))?;

    unsafe {
        let graph = GRAPH.as_ref().ok_or_else(|| JsValue::from_str("GRAPH not init"))?;
        let mut out: Vec<NodeSnapshot> = Vec::new();

        if let Some(tag) = spec.tag {
            for n in graph.query_by_tag(&tag) {
                out.push(NodeSnapshot { node: (*n).clone() });
            }
        } else if let (Some(metric), Some(min), Some(max)) = (spec.metric, spec.min, spec.max) {
            for n in graph.query_by_metric_range(&metric, min, max) {
                out.push(NodeSnapshot { node: (*n).clone() });
            }
        }

        JsValue::from_serde(&out).map_err(|e| JsValue::from_str(&format!("{e}")))
    }
}

#[wasm_bindgen]
pub fn vdom_annotate(id: &str, annotations_json: &str) -> Result<bool, JsValue> {
    let annotations: PromptAnnotations = serde_json::from_str(annotations_json)
        .map_err(|e| JsValue::from_str(&format!("parse error: {e}")))?;

    unsafe {
        let graph = GRAPH.as_mut().ok_or_else(|| JsValue::from_str("GRAPH not init"))?;
        Ok(graph.annotate_node(id, annotations))
    }
}
