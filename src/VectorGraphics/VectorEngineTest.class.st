Class {
	#name : 'VectorEngineTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-tests',
	#package : 'VectorGraphics',
	#tag : 'tests'
}

{ #category : 'tests' }
VectorEngineTest >> testAlphaMasks [
|engine alphaMask|

engine := VectorEngine onForm: (Form extent: 10@10 depth: 32).
engine antiAliasingWidth: 2.
engine pvtStrokeWidth: 4.

"alpha value decrease as the distance to the center increase, once we go over the opaque section
alphaMask are distributed on a circle centered around the position"

alphaMask := engine updateAlphasFor:5@5.
self assert: (alphaMask  at: 55) equals: 16r7F.
self assert: (alphaMask  at: 36) equals: 16r40.
self assert: (alphaMask  at: 47) equals: 16r65.
self assert: (alphaMask  at: 33) equals: 16r0.
self assert: (alphaMask  at: 79) equals: 16r0.
self assert: (alphaMask  at: 52) equals: 16r0.
self assert: (alphaMask  at: 59) equals: 16r0.

]

{ #category : 'tests' }
VectorEngineTest >> testAlphaValue [
|engine alpha|

engine := VectorEngine onForm: (Form extent: 10@10 depth: 32).
engine antiAliasingWidth: 2.
engine pvtStrokeWidth: 4.

"alpha value decrease as the distance to the center increase, once we go over the opaque section"
alpha := engine alphaValueAtDistance: 0 and:  0.
self assert: alpha equals: 16r7F.

alpha := engine alphaValueAtDistance: 0.5 and:  0.5.
self assert: alpha equals: 16r7f.

alpha := engine alphaValueAtDistance: 0.5 sqrt and:  0.5 sqrt.
self assert: alpha equals: 16r7f.

alpha := engine alphaValueAtDistance: 0.72 and:  0.72.
self assert: alpha equals: 16r7e.

alpha := engine alphaValueAtDistance: 1 and:  1.
self assert: alpha equals: 16r65.

alpha := engine alphaValueAtDistance: 1.5 and:  1.5.
self assert: alpha equals: 16r38.

"alpha are calculated as a circle around the position"
alpha := engine alphaValueAtDistance: 2 and:  2.
self assert: alpha equals: 16rB.

alpha := engine alphaValueAtDistance: -2 and:  2.
self assert: alpha equals: 16rB.

alpha := engine alphaValueAtDistance: 2 and:  -2.
self assert: alpha equals: 16rB.

alpha := engine alphaValueAtDistance: -2 and:  -2.
self assert: alpha equals: 16rB.

alpha := engine alphaValueAtDistance: 2.12 and:  2.12.
self assert: alpha equals: 16r0.

alpha := engine alphaValueAtDistance: 3 and:  -2.
self assert: alpha equals: 16r0.
]

{ #category : 'tests' }
VectorEngineTest >> testDrawingArea [
|engine area|

engine := VectorEngine onForm: (Form extent: 10@10 depth: 32).
engine antiAliasingWidth: 2.
engine pvtStrokeWidth: 4.
"top left corner"
area :=  engine drawingAreaOf: 0@0.
self assert: area closeTo: (Rectangle origin: 0@0 corner: 3@3).

"bottom right corner"
area := engine drawingAreaOf: 10@10.
self assert: area closeTo: (Rectangle origin: 8@8 corner:10@10).

"middle of the form"
area := engine drawingAreaOf: 5@5.
self assert: area closeTo: (Rectangle origin: 3@3 corner: 8@8).

"left center"
area := engine drawingAreaOf: 0@5.
self assert: area closeTo: (Rectangle origin: 0@3 corner:3@8).

"right center"
area := engine drawingAreaOf: 10@5.
self assert: area closeTo: (Rectangle origin: 8@3 corner:10@8).
]

{ #category : 'tests' }
VectorEngineTest >> testPrimLines [
|engine line|

engine := VectorEngine onForm: (Form extent: 10@10 depth: 32).
line := engine primLineFrom: 5@0 to: 5@10 hops: 10 increment: 0@1.
self assert: (line at: 1) equals: 5@0. 
self assert: (line at: 5) equals: 5@4.
self assert: (line at: 11) equals: 5@10.
]
