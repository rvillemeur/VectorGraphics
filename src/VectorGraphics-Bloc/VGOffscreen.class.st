"
I am the one by one canvas that measures text when no frame is being drawn.

Bloc measures a paragraph during layout, which happens before and independently of rendering, so
there has to be a canvas that exists outside any window. `BAOffscreen` is that canvas for
Alexandrie and I am the same thing for this project: the single override builds the canvas through
`VGCanvas`, and the session handling, the validity check and the measurer are all inherited.

I keep my own singleton, because a class instance variable gives each subclass its own slot.
"
Class {
	#name : 'VGOffscreen',
	#superclass : 'BAOffscreen',
	#category : 'VectorGraphics-Bloc-Backend',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Backend'
}

{ #category : 'api' }
VGOffscreen >> ensureReady [
	"The inherited method builds the measuring canvas by naming `AeCanvas`, which is the only
	 backend decision in this class."

	(aeCanvas notNil and: [ aeCanvas isValid ]) ifTrue: [ ^ self ].
	aeCanvas := VGCanvas extent: 1 @ 1.
	textMeasurer := BATextMeasurer new
		                canvas: aeCanvas;
		                yourself
]
