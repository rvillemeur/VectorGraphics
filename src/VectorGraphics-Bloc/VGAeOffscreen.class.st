"
I am the one by one canvas that measures text on the route where Cairo draws the pixels and this
project supplies only the fonts.

Bloc measures a paragraph during layout, which happens before and independently of rendering, so
there has to be a canvas that exists outside any window. `BAOffscreen` is that canvas for
Alexandrie, `VGOffscreen` is it for the all-ours route, and I am it for this one: the single
override builds the canvas through `VGAeCanvas`, and the session handling, the validity check and
the measurer are all inherited.

I keep my own singleton, because a class instance variable gives each subclass its own slot.
"
Class {
	#name : 'VGAeOffscreen',
	#superclass : 'BAOffscreen',
	#category : 'VectorGraphics-Bloc-Text',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Text'
}

{ #category : 'initialization' }
VGAeOffscreen >> ensureReady [
	"The inherited method builds the measuring canvas by naming `AeCanvas`, which is the only
	 backend decision in this class.
	 Every measurement reaches this method through BAOffscreen >> textMeasurer, which is why
	 the manager is checked here: the faces a measurement resolves come from the slot upstream
	 nils at every image start, and a face of upstream's own kind breaks in our scaled font."

	VGFontManager ensureUpstreamHoldsMine.
	(aeCanvas notNil and: [ aeCanvas isValid ]) ifTrue: [ ^ self ].
	aeCanvas := VGAeCanvas extent: 1 asPoint.
	textMeasurer := BATextMeasurer new
		                canvas: aeCanvas;
		                yourself
]
