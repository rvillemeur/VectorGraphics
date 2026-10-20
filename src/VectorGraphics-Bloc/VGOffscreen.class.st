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

{ #category : 'inspector' }
VGOffscreen >> inspectorMeasuring: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Measuring'>
	"Text is measured before anything is drawn, and through a canvas of one pixel that exists only
	 to answer scaled fonts. Both the canvas and the measurer have to be ours, and the fonts it
	 has answered so far are counted rather than described."

	^ aBuilder newTable
		  items: {
				  ('Canvas' -> aeCanvas class).
				  ('Canvas is valid' -> (aeCanvas notNil and: [ aeCanvas isValid ])).
				  ('Text measurer' -> textMeasurer class).
				  ('Measurer canvas' -> (textMeasurer
					    ifNil: [ nil ]
					    ifNotNil: [ :measurer | measurer canvas class ])) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGOffscreen >> inspectorMeasuringContext: aContext [
	"An offscreen built but never made ready holds neither canvas nor measurer."

	aContext active: aeCanvas notNil
]
