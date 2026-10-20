"
I am a text paragraph that measures nothing and only records who was asked to measure
it. Bloc measures a paragraph by sending `measureOn:` to it with the text measurer, so recording
that argument is enough to prove which canvas a measurement would have gone through, without
building a font, a span and a shaped run first.
"
Class {
	#name : 'VGTextParagraphStub',
	#superclass : 'Object',
	#instVars : [
		'measurer'
	],
	#category : 'VectorGraphics-Bloc-Tests',
	#package : 'VectorGraphics-Bloc-Tests'
}

{ #category : 'measuring' }
VGTextParagraphStub >> measureOn: aTextMeasurer [
	measurer := aTextMeasurer
]

{ #category : 'accessing' }
VGTextParagraphStub >> measurer [
	^ measurer
]
