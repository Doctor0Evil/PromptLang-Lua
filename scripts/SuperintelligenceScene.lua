-- scripts/SuperintelligenceScene.lua
local SuperScene = {}

SuperScene.metrics = {
  CLD = 0.82,  -- CognitionLattice Density
  SSC = 0.76,  -- SignalSilence Contrast
  PVI = 0.65,  -- Perspective Vertigo Index
  MKD = 0.88,  -- MythKernel Depth
  -- Cross-style compatibility: keep EDF / AFI / ESE fields available
  EDF = 0.10,
  AFI = 0.20,
  ESE = 0.95,
}
