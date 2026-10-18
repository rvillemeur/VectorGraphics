"
I hold the one-click examples for the conformance harness. My examples answer a single case and the whole corpus, so that the Blocking and Cases tabs show where the drawing stops today without the test runner being involved.
"
Class {
	#name : 'VGConformanceCorpusExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples',
	#package : 'VectorGraphics-Cairo-Examples'
}

{ #category : 'examples' }
VGConformanceCorpusExamples class >> corpus [
	<sampleInstance>
	"The whole conformance corpus. The Cases tab names the selector each case stops on."

	^ VGConformanceCorpus
]

{ #category : 'examples' }
VGConformanceCorpusExamples class >> filledCircleCase [
	<sampleInstance>
	"One case on its own, rebuilt on every call. The Blocking tab says where it stops."

	^ VGConformanceCorpus pathCases detect: [ :each | each name = 'path-filled-circle' ]
]
