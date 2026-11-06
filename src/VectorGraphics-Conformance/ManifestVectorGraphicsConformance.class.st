"
The corpus the backends of this project are compared against, and the cases that describe it.

A conformance case is one drawing, named and reproducible: `VGConformanceCase` holds the
drawing and what it should look like, `VGConformanceCorpus` holds the whole set, and
`VGFormComparison` answers how far two renderings of a case are apart. `VGAlexandrieCase`,
`VGAlexandrieCorpus` and `VGAlexandriePortedExperiments` are the same thing for the drawings
ported from Alexandrie, and `VGAlexandrieFontLifetime` is the one case about the lifetime of a
font face rather than about pixels.

Nothing here is a `TestCase`. Until the review of 2026-11 this corpus lived in
`VectorGraphics-Cairo-Tests`, which made every examples package that opens a drawing depend on
a test package; `VGConformanceTest` stayed behind, in that package, because it is the gate that
reads the corpus. The corpus names `VectorGraphics-Cairo` alone, so it loads with no test
package and no device backend: group `conformance` in `BaselineOfVectorGraphics`.

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
	#name : 'ManifestVectorGraphicsConformance',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Conformance-Manifest',
	#package : 'VectorGraphics-Conformance',
	#tag : 'Manifest'
}
