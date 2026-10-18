"
I am the replacement for AeCairoStatus: the answer to the status message that Cairo puts on every context and surface.

AeCanvas sends `alphaSurface status ensureIsSuccess` after creating a similar surface, so a replacement surface has to answer something that understands ensureIsSuccess. A pure Pharo backend has no C error code to report, so the only interesting case is success; a later unit can add a failure for an allocation that could not be served.
"
Class {
	#name : 'VGCairoStatus',
	#superclass : 'Object',
	#instVars : [
		'code'
	],
	#category : 'VectorGraphics-Cairo-Skeleton',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Skeleton'
}

{ #category : 'instance creation' }
VGCairoStatus class >> success [
	^ self new
		  setCode: self successCode;
		  yourself
]

{ #category : 'constants' }
VGCairoStatus class >> successCode [
	"Cairo reports success as zero, and a caller that prints a status should see the same number."

	^ 0
]

{ #category : 'accessing' }
VGCairoStatus >> code [
	^ code
]

{ #category : 'testing' }
VGCairoStatus >> ensureIsSuccess [
	self isSuccess ifFalse: [ self error: 'Cairo status is not success: ' , code printString ]
]

{ #category : 'testing' }
VGCairoStatus >> isSuccess [
	^ code = self class successCode
]

{ #category : 'printing' }
VGCairoStatus >> printOn: aStream [
	super printOn: aStream.
	self isSuccess
		ifTrue: [ aStream nextPutAll: ' success' ]
		ifFalse: [
			aStream
				nextPutAll: ' code ';
				print: code ]
]

{ #category : 'private' }
VGCairoStatus >> setCode: anInteger [
	code := anInteger
]
