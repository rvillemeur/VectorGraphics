"
I am signalled by a skeleton method of the Cairo replacement: the selector exists, so the calling surface is complete, but the behaviour belongs to a later unit of VECTORCANVAS-PLAN.md.

I carry the unit number and the selector, so a failing conformance case names the unit that will fix it instead of reporting an arbitrary error. VGCairoSkeletonTest reads my senders and fails if one names a unit the plan does not declare.
"
Class {
	#name : 'VGNotYetImplemented',
	#superclass : 'Error',
	#instVars : [
		'unit',
		'selectorName'
	],
	#category : 'VectorGraphics-Cairo-Skeleton',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Skeleton'
}

{ #category : 'signalling' }
VGNotYetImplemented class >> signalForSelector: aSymbol unit: aString [
	^ self new
		  selectorName: aSymbol;
		  unit: aString;
		  signal
]

{ #category : 'accessing' }
VGNotYetImplemented >> messageText [
	^ messageText ifNil: [
		  messageText := String streamContents: [ :stream |
				          stream
					          nextPutAll: selectorName;
					          nextPutAll: ' is a skeleton: unit ';
					          nextPutAll: unit;
					          nextPutAll: ' of VECTORCANVAS-PLAN.md implements it' ] ]
]

{ #category : 'accessing' }
VGNotYetImplemented >> selectorName [
	^ selectorName
]

{ #category : 'accessing' }
VGNotYetImplemented >> selectorName: aSymbol [
	selectorName := aSymbol
]

{ #category : 'accessing' }
VGNotYetImplemented >> unit [
	^ unit
]

{ #category : 'accessing' }
VGNotYetImplemented >> unit: aString [
	unit := aString
]
