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


T
a
g
s
:




-
 
`
M
a
n
i
f
e
s
t
`
 
—
 
t
h
i
s
 
c
o
m
m
e
n
t
 
a
n
d
 
t
h
e
 
R
e
n
r
a
k
u
 
r
u
l
e
 
c
o
n
f
i
g
u
r
a
t
i
o
n
.
"
Class {
	#name : 'ManifestVectorGraphicsBenchmarks',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Benchmarks-Manifest',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Manifest'
}
