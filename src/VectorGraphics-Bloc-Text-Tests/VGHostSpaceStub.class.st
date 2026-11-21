"
I am the least a host space has to answer for a renderer to initialise itself: a
physical size in device pixels and a scale factor. A real host space needs a window, and the tests
that only check what the renderer built around those two numbers should not need one.
"
Class {
	#name : 'VGHostSpaceStub',
	#superclass : 'Object',
	#instVars : [
		'physicalSize',
		'scaleFactor'
	],
	#category : 'VectorGraphics-Bloc-Text-Tests-Fixtures',
	#package : 'VectorGraphics-Bloc-Text-Tests',
	#tag : 'Fixtures'
}

{ #category : 'initialization' }
VGHostSpaceStub >> initialize [
	super initialize.
	physicalSize := 100 @ 100.
	scaleFactor := 1
]

{ #category : 'accessing' }
VGHostSpaceStub >> physicalSize [
	^ physicalSize
]

{ #category : 'accessing' }
VGHostSpaceStub >> physicalSize: aPoint [
	physicalSize := aPoint
]

{ #category : 'accessing' }
VGHostSpaceStub >> scaleFactor [
	^ scaleFactor
]

{ #category : 'accessing' }
VGHostSpaceStub >> scaleFactor: aNumber [
	scaleFactor := aNumber
]
