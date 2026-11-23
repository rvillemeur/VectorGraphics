"
The harness that measures a frame through each backend of this project.

`VGFrameDrawingKit` builds the frame that is measured, out of the conformance corpus;
`VGFrameStageBenchmark` times it stage by stage through the Bloc renderer, and
`VGFrameDeviceBenchmark` times it through the Vulkan device path. A figure printed here is the
budget the device path is held to.

Nothing here is a `TestCase`, and no suite reads these classes: a benchmark is run by hand,
because a timing measured while a suite runs is a timing of the suite. Until the review of
2026-11 the harness lived in `VectorGraphics-Vulkan-Tests`, so the examples that open a
benchmark named a test package. It now loads from group `benchmarks`, and names the three
backends it drives and the corpus it draws.

`VGArchitectureTest class >> allowedDependencies` states what this package may name.

Tags:
- `Frames` — the frame harness: the kit that draws the corpus and the two benchmarks
that time one frame of it, stage by stage through Bloc and through the Vulkan device path.
- `Present` — the present path: the benchmark of a frame reaching a window, and the
comparison of that path against the readback path.
- `Manifest` — this comment and the Renraku rule configuration.

"
Class {
	#name : 'ManifestVectorGraphicsBenchmarks',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Benchmarks-Manifest',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Manifest'
}
