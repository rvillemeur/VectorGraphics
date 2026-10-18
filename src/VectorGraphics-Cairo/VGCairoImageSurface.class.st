"
I am the replacement for AeCairoImageSurface: a premultiplied ARGB32 pixel target.

I can own my pixels or borrow them. Borrowing matters because BARenderer >> renderWith:pixels:stride:physicalRectangle:logicalRectangle: hands the renderer a raw host window address and a stride, and draws straight into it; see section 2.2 of VECTORCANVAS-PLAN.md. I also carry the device offset and the device scale that the host sets for a High DPI display.

Unit 1.1 implements me; until then my selectors signal VGNotYetImplemented.
"
Class {
	#name : 'VGCairoImageSurface',
	#superclass : 'VGCairoObject',
	#category : 'VectorGraphics-Cairo-Surface',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Surface'
}

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface class >> extent: arg1 [
	^ self notYetImplementedIn: '1.1' selector: #extent:
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface class >> extent: arg1 format: arg2 [
	^ self notYetImplementedIn: '1.1' selector: #extent:format:
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface class >> extent: arg1 to: arg2 [
	^ self notYetImplementedIn: '1.1' selector: #extent:to:
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface class >> fromForm: arg1 [
	^ self notYetImplementedIn: '1.1' selector: #fromForm:
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface class >> unownedNewForData: arg1 format: arg2 width: arg3 height: arg4 stride: arg5 [
	^ self notYetImplementedIn: '1.1' selector: #unownedNewForData:format:width:height:stride:
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> asForm [
	^ self notYetImplementedIn: '1.1' selector: #asForm
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> colorAt: arg1 [
	^ self notYetImplementedIn: '1.1' selector: #colorAt:
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> data [
	^ self notYetImplementedIn: '1.1' selector: #data
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> deviceOffset: arg1 [
	^ self notYetImplementedIn: '1.1' selector: #deviceOffset:
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> deviceScale [
	^ self notYetImplementedIn: '1.1' selector: #deviceScale
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> deviceScale: arg1 [
	^ self notYetImplementedIn: '1.1' selector: #deviceScale:
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> deviceScaleMatrix [
	^ self notYetImplementedIn: '1.1' selector: #deviceScaleMatrix
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> deviceScaleX: arg1 y: arg2 [
	^ self notYetImplementedIn: '1.1' selector: #deviceScaleX:y:
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> extent [
	^ self notYetImplementedIn: '1.1' selector: #extent
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> finish [
	^ self notYetImplementedIn: '1.1' selector: #finish
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> flush [
	^ self notYetImplementedIn: '1.1' selector: #flush
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> height [
	^ self notYetImplementedIn: '1.1' selector: #height
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> newContext [
	^ self notYetImplementedIn: '1.1' selector: #newContext
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> newSimilarImageFormat: arg1 width: arg2 height: arg3 [
	^ self notYetImplementedIn: '1.1' selector: #newSimilarImageFormat:width:height:
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> stride [
	^ self notYetImplementedIn: '1.1' selector: #stride
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> width [
	^ self notYetImplementedIn: '1.1' selector: #width
]

{ #category : 'skeleton - unit 1.1' }
VGCairoImageSurface >> writePngTo: arg1 [
	^ self notYetImplementedIn: '1.1' selector: #writePngTo:
]
