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
VGCairoStatus class >> invalidDash [
	^ self new
		  setCode: self invalidDashCode;
		  yourself
]

{ #category : 'accessing' }
VGCairoStatus class >> invalidDashCode [
	"CAIRO_STATUS_INVALID_DASH: a dash pattern holds a negative length, or every one of its
	 lengths is zero. The number is read from a live Cairo context, not guessed."

	^ 19
]

{ #category : 'instance creation' }
VGCairoStatus class >> invalidMatrix [
	^ self new setCode: self invalidMatrixCode
]

{ #category : 'constants' }
VGCairoStatus class >> invalidMatrixCode [
	"CAIRO_STATUS_INVALID_MATRIX: the matrix is not invertible."
	^ 5
]

{ #category : 'instance creation' }
VGCairoStatus class >> invalidPopGroup [
	^ self new
		  setCode: self invalidPopGroupCode;
		  yourself
]

{ #category : 'constants' }
VGCairoStatus class >> invalidPopGroupCode [
	"CAIRO_STATUS_INVALID_POP_GROUP: a group was popped that was never pushed. The number is
	 read from the live enumeration, not guessed."
	^ 3
]

{ #category : 'instance creation' }
VGCairoStatus class >> invalidStride [
	^ self new
		  setCode: self invalidStrideCode;
		  yourself
]

{ #category : 'constants' }
VGCairoStatus class >> invalidStrideCode [
	"Cairo's CAIRO_STATUS_INVALID_STRIDE. The number is the enumeration value a caller reading my
	 code would compare against, so it is named rather than written inline."
	^ 24
]

{ #category : 'instance creation' }
VGCairoStatus class >> noCurrentPoint [
	^ self new setCode: self noCurrentPointCode
]

{ #category : 'constants' }
VGCairoStatus class >> noCurrentPointCode [
	"CAIRO_STATUS_NO_CURRENT_POINT: a relative path verb was sent with no current point. The
	 number is read from the live enumeration, not guessed."

	^ 4
]

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
