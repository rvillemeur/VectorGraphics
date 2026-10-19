"
I hold the examples of VGFormComparison: a verdict on one conformance case rendered twice, once by the replacement and once by Alexandrie, and a verdict on two pictures of different sizes. The Verdict tab reads them.
"
Class {
	#name : 'VGFormComparisonExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGFormComparisonExamples class >> verdictOnAFilledCircle [
	<sampleInstance>
	"The verdict the conformance gate reads: the filled circle drawn by the replacement against
	 the same script drawn by Cairo. The antialiased edge is where the two differ, and the
	 extraneous count is zero because we paint no pixel outside Cairo's shape."

	| case |
	case := VGConformanceCorpus pathCases detect: [ :each |
		        each name = 'path-filled-circle' ].
	^ case comparisonWithCairo
]

{ #category : 'examples' }
VGFormComparisonExamples class >> verdictOnPicturesOfDifferentSizes [
	<sampleInstance>
	"The degenerate verdict: two pictures of different extents cannot be compared at all, and the
	 comparison says so rather than answering a count."

	^ VGFormComparison
		  between: (Form extent: 8 @ 8 depth: 32)
		  and: (Form extent: 9 @ 8 depth: 32)
]
