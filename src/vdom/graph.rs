// src/vdom/graph.rs

use super::types::*;
use serde::{Serialize, Deserialize};
use std::collections::HashMap;

#[derive(Serialize, Deserialize, Default)]
pub struct VirtualGraph {
    pub nodes: HashMap<VirtualNodeId, VirtualNode>,
}

impl VirtualGraph {
    pub fn get(&self, id: &str) -> Option<&VirtualNode> {
        self.nodes.get(id)
    }

    pub fn query_by_tag(&self, tag: &str) -> Vec<&VirtualNode> {
        self.nodes
            .values()
            .filter(|n| n.semantic_tags.iter().any(|t| t == tag))
            .collect()
    }

    pub fn query_by_metric_range(
        &self,
        metric: &str,
        min: f32,
        max: f32,
    ) -> Vec<&VirtualNode> {
        self.nodes
            .values()
            .filter(|n| {
                let val = match metric {
                    "IEI" => n.metrics.iei,
                    "TIS" => n.metrics.tis,
                    "EID" => n.metrics.eid,
                    "PAR" => n.metrics.par,
                    "AC"  => n.metrics.ac,
                    _ => return false,
                };
                val >= min && val <= max
            })
            .collect()
    }

    pub fn annotate_node(
        &mut self,
        id: &str,
        annotations: PromptAnnotations,
    ) -> bool {
        if let Some(node) = self.nodes.get_mut(id) {
            node.annotations.escape_targets.extend(annotations.escape_targets);
            node.annotations.roles.extend(annotations.roles);
            true
        } else {
            false
        }
    }
}
