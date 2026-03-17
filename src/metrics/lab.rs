// File: src/metrics/lab.rs

use crate::metrics::art_behavior::{ArtBehaviorMetrics, MetricInputs};
use crate::vdom::graph::VirtualGraph;

pub struct ArtBehaviorLab<'a> {
    pub graph: &'a mut VirtualGraph,
    pub inputs_by_node: Vec<(String, MetricInputs)>, // or a map
}

impl<'a> ArtBehaviorLab<'a> {
    pub fn recompute_all(&mut self) {
        for (id, inputs) in self.inputs_by_node.iter() {
            if let Some(node) = self.graph.nodes.get_mut(id) {
                let mut ab = node.art_behavior.clone();
                ArtBehaviorMetrics::compute_async(inputs, &mut ab);
                node.art_behavior = ab;
            }
        }
    }
}
