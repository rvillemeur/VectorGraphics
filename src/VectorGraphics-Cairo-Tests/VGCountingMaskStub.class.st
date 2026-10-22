"
A mask that remembers every pixel the backend read from it, so a test can state how wide the backend's walk is rather than only what the surface ends up holding. A pixel where a mask is transparent leaves the destination exactly as it was, so the work spent reading it is invisible in the picture and needs an observer of this kind. `readPixels` answers those pixels as points, in the order they were read.
"
Class {
	#name : 'VGCountingMaskStub',
	#superclass : 'VGCairoSurfaceMask',
	#instVars : [
		'readPixels'
	],
	#category : 'VectorGraphics-Cairo-Tests-Fixtures',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Fixtures'
}

{ #category : 'accessing' }
VGCountingMaskStub >> alphaAtX: anX y: aY [
	self readPixels add: anX @ aY.
	^ super alphaAtX: anX y: aY
]

{ #category : 'accessing' }
VGCountingMaskStub >> readPixels [
	^ readPixels ifNil: [ readPixels := OrderedCollection new ]
]
