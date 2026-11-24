"
A span scanner that refuses to read its edges. `anEdgeMeets:` and `isInsideAt:` signal instead of answering, so a test that asks `enclosesWholly:` of a shape whose edges are a device rectangle fails loudly if the short answer from the bounding box is not taken. It answers every other question as a scanner does.
"
Class {
	#name : 'VGRefusingWalkScannerStub',
	#superclass : 'VGSpanScanner',
	#category : 'VectorGraphics-Canvas-Raster-Tests-Fixtures',
	#package : 'VectorGraphics-Canvas-Raster-Tests',
	#tag : 'Fixtures'
}

{ #category : 'private' }
VGRefusingWalkScannerStub >> anEdgeMeets: aRectangle [
	self error: 'the edges were read'
]

{ #category : 'private' }
VGRefusingWalkScannerStub >> isInsideAt: aPoint [
	self error: 'the edges were read'
]
