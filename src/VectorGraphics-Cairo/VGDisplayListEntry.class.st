"
I am one recorded drawing operation, with the state it was recorded under.

Cairo's API is stateful and immediate, so the state at the moment of the call is mine and not the
context's: the source, the clip and the operator are copied into me, and the geometry I hold is a
value no later call can change. That is what makes fillPreservingPath honest, since the path
outlives the operation.
A subclass says what it is by answering replayOn: with one of the three messages the backend
boundary allows.
"
Class {
	#name : 'VGDisplayListEntry',
	#superclass : 'Object',
	#instVars : [
		'paint',
		'clip',
		'operator'
	],
	#category : 'VectorGraphics-Cairo-Display list',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Display list'
}

{ #category : 'draining' }
VGDisplayListEntry >> boundingBox [
	"What I can touch, in device space, or nil when I can touch nothing."
	^ self subclassResponsibility
]

{ #category : 'accessing' }
VGDisplayListEntry >> clip [
	^ clip
]

{ #category : 'accessing' }
VGDisplayListEntry >> operator [
	^ operator
]

{ #category : 'accessing' }
VGDisplayListEntry >> paint [
	^ paint
]

{ #category : 'draining' }
VGDisplayListEntry >> replayOn: aBackend [
	self subclassResponsibility
]

{ #category : 'initialization' }
VGDisplayListEntry >> setPaint: aPaint clip: aRectangle operator: aSymbol [
	paint := aPaint.
	clip := aRectangle.
	operator := aSymbol
]
