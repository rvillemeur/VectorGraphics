"
I hold the one-click examples of the Alexandrie conformance corpus.

The corpus derives one ported copy of every <sampleInstance> experiment on
AlexandrieCairoExperiment by substituting our class names for Alexandrie's, so it is an oracle no
drawing is ever hand-copied into.
My examples answer the corpus after a regeneration, the cases that are still waiting on a unit, and
one such case on its own, which is the object the case inspector view is most useful on.
"
Class {
	#name : 'VGAlexandrieCorpusExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGAlexandrieCorpusExamples class >> casesWaitingOnAUnit [
	<sampleInstance>
	^ VGAlexandrieCorpus cases select: [ :each | each blockingUnit notNil ]
]

{ #category : 'examples' }
VGAlexandrieCorpusExamples class >> corpus [
	"The corpus is a class with class-side behaviour only, so the example regenerates the derived
	 copies and answers the class the inspector views live on."
	<sampleInstance>
	VGAlexandrieCorpus regenerate.
	^ VGAlexandrieCorpus
]

{ #category : 'examples' }
VGAlexandrieCorpusExamples class >> oneCaseWaitingOnAUnit [
	<sampleInstance>
	^ VGAlexandrieCorpus cases
		detect: [ :each | each blockingUnit notNil ]
		ifNone: [ VGAlexandrieCorpus cases first ]
]
