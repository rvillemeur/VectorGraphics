"
I blur the alpha bytes of an a8 surface in place, which is what a Bloc shadow is made of: the geometry of the element is drawn on an alpha-only surface, I soften it, and the result is used as a mask.

I approximate a Gaussian with three passes of a box blur, after the same reference implementation Alexandrie follows (Ivan Kutskir, ""Fastest Gaussian blur"", http://blog.ivank.net/fastest-gaussian-blur.html): three boxes whose radii come from the wanted standard deviation, each pass run once along the rows and once along the columns. Three passes of a box are within a few parts in a thousand of a true Gaussian and cost a constant number of additions per pixel whatever the radius is, which is why nobody convolves a shadow directly.

The arithmetic is integer and deterministic, so VGBlurTest holds me to Alexandrie byte for byte rather than within a tolerance. I walk the stride and not the width, because Alexandrie does and because the bytes a mask is read through are the ones Cairo laid out; on a width whose stride carries padding that bleeds the end of a row into the start of the next, which VGBlurTest states as the behaviour it is.

Send #surface: and then #applyRadius: for a Bloc shadow width, or #applySigma: for a standard deviation.
"
Class {
	#name : 'VGA8GaussianBlurFilter',
	#superclass : 'Object',
	#instVars : [
		'surface',
		'columnCount',
		'rowCount',
		'bufferA',
		'bufferB'
	],
	#category : 'VectorGraphics-Cairo-Blur',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Blur'
}

{ #category : 'computing' }
VGA8GaussianBlurFilter class >> boxRadiiForSigma: aSigma passes: aPassCount [
	"The radius of each box pass, from the boxesForGauss function of the reference implementation.
	 The ideal box width for the wanted standard deviation is rarely an odd whole number, so the
	 nearest odd width below it is used for the first few passes and the next odd width up for the
	 rest, and the count of each is the one that keeps the total variance right."

	| idealWidth lowerWidth upperWidth lowerRadius upperRadius idealCount lowerCount |
	idealWidth := (12 * aSigma squared / aPassCount + 1) sqrt.
	lowerWidth := idealWidth floor.
	lowerWidth even ifTrue: [ lowerWidth := lowerWidth - 1 ].
	upperWidth := lowerWidth + 2.
	lowerRadius := (lowerWidth - 1) bitShift: -1.
	upperRadius := (upperWidth - 1) bitShift: -1.
	idealCount := 12 * aSigma squared - (aPassCount * lowerWidth squared)
	              - (4 * aPassCount * lowerWidth) - (3 * aPassCount)
	              / (-4 * lowerWidth - 4).
	lowerCount := idealCount rounded.
	^ (Array new: aPassCount) withIndexCollect: [ :each :index |
		  index <= lowerCount
			  ifTrue: [ lowerRadius ]
			  ifFalse: [ upperRadius ] ]
]

{ #category : 'constants' }
VGA8GaussianBlurFilter class >> defaultPassCount [
	"Three box passes, which is where the approximation of a Gaussian is good enough to be invisible
	 and is the number Alexandrie and the reference implementation both use."

	^ 3
]

{ #category : 'constants' }
VGA8GaussianBlurFilter class >> inspectorRadiiShown [
	"The shadow radii the Box radii view tabulates. A display sample, chosen to span what Bloc
	 asks for: BlGaussianShadowEffect defaults to a radius of a few points and a large one is
	 tens of points."

	^ #( 1 2 4 8 16 32 64 )
]

{ #category : 'constants' }
VGA8GaussianBlurFilter class >> radiusToSigmaRatio [
	"A Bloc shadow names a width in pixels and a Gaussian is defined by a standard deviation, and
	 this is the ratio Alexandrie settled on between them: three quarters of the square root of two
	 pi, times one and a half. Changing it changes how wide every shadow in a Bloc window looks, so
	 it is kept at Alexandrie value to the last digit."

	^ 2.8199568089598754
]

{ #category : 'computing' }
VGA8GaussianBlurFilter class >> sigmaForRadius: aNumber [
	"The standard deviation a shadow of this width is blurred by. It is rounded because the box
	 radii it feeds are whole numbers in any case."

	^ (aNumber / self radiusToSigmaRatio) rounded
]

{ #category : 'applying' }
VGA8GaussianBlurFilter >> applyRadius: aRadius [
	^ self applyRadius: aRadius passes: self class defaultPassCount
]

{ #category : 'applying' }
VGA8GaussianBlurFilter >> applyRadius: aRadius passes: aPassCount [
	"Blur by a Bloc shadow width, which is a radius rather than a standard deviation."

	aRadius isZero ifTrue: [ ^ self ].
	self applySigma: (self class sigmaForRadius: aRadius) passes: aPassCount
]

{ #category : 'applying' }
VGA8GaussianBlurFilter >> applySigma: aSigma [
	^ self applySigma: aSigma passes: self class defaultPassCount
]

{ #category : 'applying' }
VGA8GaussianBlurFilter >> applySigma: aSigma passes: aPassCount [
	"Each pass runs the box once along the rows and once along the columns, which is what makes a
	 separable approximation of a two-dimensional Gaussian. The passes alternate between the two
	 buffers and end back in the first, so the surface is written once, at the end."

	aSigma isZero ifTrue: [ ^ self ].
	self prepareBuffers.
	(self class boxRadiiForSigma: aSigma passes: aPassCount) do: [ :boxRadius |
		self boxBlurAlongRowsFrom: bufferA to: bufferB boxRadius: boxRadius.
		self boxBlurAlongColumnsFrom: bufferB to: bufferA boxRadius: boxRadius ].
	self writeBufferBackToTheSurface
]

{ #category : 'private' }
VGA8GaussianBlurFilter >> boxBlurAlongColumnsFrom: aSourceBuffer to: aTargetBuffer boxRadius: aRadius [
	"The same pass down every column, which is what makes the pair of them separable: a box in two
	 dimensions is a box along the rows followed by a box down the columns. The index steps by the
	 column count instead of by one, and the first and the last row are what is repeated outside."

	| diameter reciprocal target top bottom firstByte lastByte runningSum |
	diameter := aRadius + aRadius + 1.
	reciprocal := 1.0 / diameter.
	1 to: columnCount do: [ :column |
		target := column.
		top := target.
		bottom := target + (aRadius * columnCount).
		firstByte := aSourceBuffer at: target.
		lastByte := aSourceBuffer at: target + (columnCount * (rowCount - 1)).
		runningSum := aRadius + 1 * firstByte.
		0 to: aRadius - 1 do: [ :each |
			runningSum := runningSum + (aSourceBuffer at: target + (each * columnCount)) ].
		aRadius + 1 timesRepeat: [
			runningSum := runningSum + (aSourceBuffer at: bottom) - firstByte.
			aTargetBuffer at: target put: (runningSum * reciprocal) floor.
			bottom := bottom + columnCount.
			target := target + columnCount ].
		rowCount - diameter timesRepeat: [
			runningSum := runningSum + (aSourceBuffer at: bottom) - (aSourceBuffer at: top).
			aTargetBuffer at: target put: (runningSum * reciprocal) floor.
			top := top + columnCount.
			bottom := bottom + columnCount.
			target := target + columnCount ].
		aRadius timesRepeat: [
			runningSum := runningSum + lastByte - (aSourceBuffer at: top).
			aTargetBuffer at: target put: (runningSum * reciprocal) floor.
			top := top + columnCount.
			target := target + columnCount ] ]
]

{ #category : 'private' }
VGA8GaussianBlurFilter >> boxBlurAlongRowsFrom: aSourceBuffer to: aTargetBuffer boxRadius: aRadius [
	"One box pass along every row, as a running sum: the window moves one byte at a time, so each
	 pixel costs one addition and one subtraction whatever the radius is. Outside the row the first
	 and the last byte are repeated rather than read as zero, which is what keeps a flat field flat,
	 and that is why the walk is in three parts: the window growing out of the left edge, the window
	 wholly inside the row, and the window running off the right edge."

	| diameter reciprocal target left right firstByte lastByte runningSum |
	diameter := aRadius + aRadius + 1.
	reciprocal := 1.0 / diameter.
	0 to: rowCount - 1 do: [ :row |
		target := row * columnCount + 1.
		left := target.
		right := target + aRadius.
		firstByte := aSourceBuffer at: target.
		lastByte := aSourceBuffer at: target + columnCount - 1.
		runningSum := aRadius + 1 * firstByte.
		0 to: aRadius - 1 do: [ :each |
			runningSum := runningSum + (aSourceBuffer at: target + each) ].
		aRadius + 1 timesRepeat: [
			runningSum := runningSum + (aSourceBuffer at: right) - firstByte.
			right := right + 1.
			aTargetBuffer at: target put: (runningSum * reciprocal) floor.
			target := target + 1 ].
		columnCount - diameter timesRepeat: [
			runningSum := runningSum + (aSourceBuffer at: right) - (aSourceBuffer at: left).
			right := right + 1.
			left := left + 1.
			aTargetBuffer at: target put: (runningSum * reciprocal) floor.
			target := target + 1 ].
		aRadius timesRepeat: [
			runningSum := runningSum + lastByte - (aSourceBuffer at: left).
			left := left + 1.
			aTargetBuffer at: target put: (runningSum * reciprocal) floor.
			target := target + 1 ] ]
]

{ #category : 'inspector' }
VGA8GaussianBlurFilter >> inspectorBoxRadii: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Box radii'>
	"What the three box passes would be for a range of shadow radii, asked of the arithmetic
	 itself rather than restated, so the table cannot drift from what a blur really does."

	^ aBuilder newTable
		  items: self class inspectorRadiiShown;
		  addColumn: (SpStringTableColumn
				   title: 'Radius'
				   evaluated: [ :each | each printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Sigma'
				   evaluated: [ :each | (self class sigmaForRadius: each) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Passes'
				   evaluated: [ :each |
					   (self class
						    boxRadiiForSigma: (self class sigmaForRadius: each)
						    passes: self class defaultPassCount) printString ]);
		  yourself
]

{ #category : 'inspector' }
VGA8GaussianBlurFilter >> inspectorBoxRadiiContext: aContext [
	"The table is arithmetic of the class alone, so it applies to any filter, blurred or not."

	aContext active: true
]

{ #category : 'inspector' }
VGA8GaussianBlurFilter >> inspectorMask: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Mask'>
	"The alpha I work on, shown as a grey image. #asForm answers a fresh Form, so showing it
	 cannot change the surface."

	^ aBuilder newImage
		  image: self surface asForm;
		  yourself
]

{ #category : 'inspector' }
VGA8GaussianBlurFilter >> inspectorMaskContext: aContext [
	aContext active: surface notNil
]

{ #category : 'private' }
VGA8GaussianBlurFilter >> prepareBuffers [
	"The surface is read only after it has drawn what it still owes, because our surface records a
	 frame and draws it when something reads its pixels."

	| byteCount |
	surface flush.
	byteCount := surface byteSize.
	bufferA := ByteArray new: byteCount.
	1 to: byteCount do: [ :each |
		bufferA at: each put: (surface data unsignedByteAt: each) ].
	bufferB := ByteArray new: byteCount
]

{ #category : 'accessing' }
VGA8GaussianBlurFilter >> surface [
	^ surface
]

{ #category : 'accessing' }
VGA8GaussianBlurFilter >> surface: aSurface [
	"The surface I blur in place. The column count is the stride and not the width, because that is
	 the row the bytes really sit in and what Alexandrie walks."

	surface := aSurface.
	columnCount := aSurface stride.
	rowCount := aSurface height
]

{ #category : 'private' }
VGA8GaussianBlurFilter >> writeBufferBackToTheSurface [

	1 to: bufferA size do: [ :each |
		surface data unsignedByteAt: each put: (bufferA at: each) ]
]
