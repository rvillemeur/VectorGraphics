Extension { #name : 'VGPath' }

{ #category : '*VectorGraphics-Canvas-Raster' }
VGPath >> segmentsWithFillRule: aSymbol [
	^ VGSegments coordinates: self edgeCoordinates fillRule: aSymbol
]

{ #category : '*VectorGraphics-Canvas-Raster' }
VGPath >> segmentsWithFillRule: aSymbol antialias: anotherSymbol [
	^ VGSegments
		  coordinates: self edgeCoordinates
		  fillRule: aSymbol
		  antialias: anotherSymbol
]
