// File: src/pipeline/request.rs

use crate::metrics::art_behavior::{ArtBehaviorMetrics, MetricInputs};

pub struct VirtualObject {
    // ...
    pub art_behavior: ArtBehaviorMetrics,
}

pub fn process_request(inputs: MetricInputs, vo: &mut VirtualObject) {
    // existing analyzer + sanitizer calls already filled `inputs`
    let sync = ArtBehaviorMetrics::compute_sync(&inputs);
    vo.art_behavior = sync;

    // expose vo snapshot to Lua immediately; routing decisions can use EDF/NSG/AFI/ESE
}
