Class {
	#name : #VectorEngineTest,
	#superclass : #TestCase,
	#category : #'VectorGraphics-tests'
}

{ #category : #tests }
VectorEngineTest >> testPrimLines [
|engine line|

engine := VectorEngineWholePixel onForm: (Form extent: 10@10 depth: 32).
line := engine primLineFrom: 5@0 to: 5@10 hops: 10 increment: 0@1.
self assert: (line at: 1) equals: 5@0. 
self assert: (line at: 5) equals: 5@4.
self assert: (line at: 11) equals: 5@10.
]
