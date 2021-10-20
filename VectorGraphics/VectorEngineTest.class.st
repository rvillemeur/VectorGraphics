Class {
	#name : #VectorEngineTest,
	#superclass : #TestCase,
	#category : #'VectorGraphics-tests'
}

{ #category : #tests }
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

{ #category : #tests }
VectorEngineTest >> testPrimLines [
|engine line|

engine := VectorEngine onForm: (Form extent: 10@10 depth: 32).
line := engine primLineFrom: 5@0 to: 5@10 hops: 10 increment: 0@1.
self assert: (line at: 1) equals: 5@0. 
self assert: (line at: 5) equals: 5@4.
self assert: (line at: 11) equals: 5@10.
]
