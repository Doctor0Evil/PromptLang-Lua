// File: src/metrics/art_behavior.rs

impl ArtBehaviorMetrics {
    pub fn compute_sync(inputs: &MetricInputs) -> ArtBehaviorMetrics {
        let danger_max = inputs.analyzer_before.violence
            .max(inputs.analyzer_before.selfharm)
            .max(inputs.analyzer_before.adult);

        // Hard saturation guardrail
        if danger_max >= 0.9 {
            return ArtBehaviorMetrics {
                edf: 1.0,
                nsg: 0.0,
                afi: 0.0,
                ese: 0.0,
                ..Default::default()
            };
        }

        // Non-linear emotional boost
        let emo = inputs.analyzer_before.emotional;
        let emo_boost = if emo >= 0.7 { emo * emo } else { emo };

        let edf = (inputs.analyzer_before.emotional
            + inputs.analyzer_before.violence
            + inputs.analyzer_before.selfharm) / 3.0;

        let edf = ((edf * 0.7) + (emo_boost * 0.3)).clamp(0.0, 1.0);

        // AFI with same emotional non-linearity
        let afi_base = (inputs.analyzer_before.violence
            + inputs.analyzer_before.selfharm
            + inputs.analyzer_before.motion) / 3.0;
        let afi = ((afi_base * 0.6) + (emo_boost * 0.4)).clamp(0.0, 1.0);

        // NSG from before/after analyzer deltas
        let danger_before = inputs.analyzer_before.violence
            + inputs.analyzer_before.selfharm
            + inputs.analyzer_before.adult;
        let danger_after = inputs.analyzer_after.violence
            + inputs.analyzer_after.selfharm
            + inputs.analyzer_after.adult;
        let nsg = ((danger_before - danger_after + 3.0) / 6.0).clamp(0.0, 1.0);

        let ese = compute_ese_inline(inputs, danger_max);

        ArtBehaviorMetrics {
            edf,
            nsg,
            afi,
            ese,
            ..Default::default() // async metrics zeroed until lab fills them
        }
    }

    pub fn compute_async(inputs: &MetricInputs, base: &mut ArtBehaviorMetrics) {
        base.hcd = compute_hcd(inputs);
        base.sfr = compute_sfr(inputs);
        base.crs = compute_crs(inputs);
        base.msc = compute_msc(inputs);
        base.riy = compute_riy(inputs);
        base.cph = compute_cph(inputs);
    }
}

fn compute_ese_inline(inputs: &MetricInputs, danger_max: f32) -> f32 {
    let age = inputs.age_band.as_str();
    let base = 1.0 - danger_max;
    let clamped = match age {
        "CHILD" => base.clamp(0.6, 1.0),
        "YOUNGTEEN" => base.clamp(0.4, 1.0),
        "TEEN" => base.clamp(0.2, 1.0),
        _ => base.clamp(0.0, 1.0),
    };
    clamped
}
