"
I am the host renderer of the route where Cairo rasterises every figure and this project supplies
only the fonts.

Bloc draws a space through the renderer `BlHostRenderer class >> preferableClass` answers, so
naming me there is the whole installation of the route. I differ from Alexandrie's renderer in
two places: the canvas I build for the frame is a `VGAeCanvas`, whose Cairo context answers our
scaled fonts, and the text measured during layout goes through `VGAeOffscreen`. Everything else
is inherited, including how the host's pixels are handed over, because on this route the
surfaces, the paths and the paint are Cairo's own.

`VGRenderer` is my sibling for the route where nothing of Cairo is used at all.
"
Class {
	#name : 'VGAeRenderer',
	#superclass : 'BARenderer',
	#category : 'VectorGraphics-Bloc-Text-Text',
	#package : 'VectorGraphics-Bloc-Text',
	#tag : 'Text'
}

{ #category : 'accessing' }
VGAeRenderer class >> label [
	"What Bloc calls this engine in a window title and in its own tools, told apart from
	 Alexandrie's and from the route where nothing of Cairo is used."

	^ 'VectorGraphics fonts'
]

{ #category : 'host - api' }
VGAeRenderer class >> offscreenMeasureTextParagraph: aBlTextParagraph [
	"Text is measured during layout, before any window exists, so the measurement goes through a
	 singleton canvas. The inherited method uses Alexandrie's singleton; this one uses the
	 offscreen of this route, whose canvas answers our scaled fonts."

	VGAeOffscreen instance measureTextParagraph: aBlTextParagraph
]

{ #category : 'initialization' }
VGAeRenderer >> initializeForHostSpace: aBlHostSpace [
	"The inherited method builds the frame canvas by naming `AeCanvas` and takes its text measurer
	 from `BAOffscreen`, whose canvas is one as well. Both come from this route here. A renderer
	 can be initialised more than once, which is why the inherited method starts with `initialize`."

	self initialize.
	physicalSize := aBlHostSpace physicalSize.
	scaleFactor := aBlHostSpace scaleFactor.
	session := Smalltalk session.
	textMeasurer := VGAeOffscreen instance textMeasurer.
	aeCanvas := VGAeCanvas newWithoutSurface
]
