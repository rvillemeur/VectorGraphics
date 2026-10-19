"
I measure the distance between two pictures: how many pixels differ at all, and the largest difference in any single channel of any pixel.

Both corpora use me as their verdict, so the arithmetic that decides whether the replacement matches Cairo exists once. Pictures of different sizes are not comparable at all, and I say so through `isComparable` rather than answering a number a caller could read as agreement.

`VGFormComparison between: aForm and: anotherForm` is my whole protocol.
"
Class {
	#name : 'VGFormComparison',
	#superclass : 'Object',
	#instVars : [
		'isComparable',
		'differingPixelCount',
		'maximumChannelDistance',
		'extraneousPixelCount'
	],
	#category : 'VectorGraphics-Cairo-Tests-Conformance',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Conformance'
}

{ #category : 'private' }
VGFormComparison class >> alphaOf: aWord [
	^ (aWord bitShift: -24) bitAnd: 255
]

{ #category : 'instance creation' }
VGFormComparison class >> between: aForm and: aReferenceForm [
	"How far our picture is from the reference: how many pixels differ at all, the largest
	 difference in any single channel, and how many pixels we paint that the reference leaves
	 untouched. The last number is the one that must be zero: a disagreement on an antialiased
	 edge is a shade, while a pixel outside the reference's shape is a wrong shape. Two pictures
	 of different sizes are not comparable, and answer an instance that says so rather than a
	 number a caller could read as agreement."

	| ours theirs differing maximum extraneous |
	ours := aForm asFormOfDepth: 32.
	theirs := aReferenceForm asFormOfDepth: 32.
	ours extent = theirs extent ifFalse: [ ^ self new beIncomparable ].
	differing := 0.
	maximum := 0.
	extraneous := 0.
	1 to: ours bits size do: [ :index |
		| ourWord theirWord |
		ourWord := self premultiplied: (ours bits at: index).
		theirWord := self premultiplied: (theirs bits at: index).
		(self alphaOf: theirWord) isZero ifTrue: [
			(self alphaOf: ourWord) isZero ifFalse: [
				extraneous := extraneous + 1 ] ].
		ourWord = theirWord ifFalse: [
			differing := differing + 1.
			maximum := maximum
				           max: (self channelDistanceBetween: ourWord and: theirWord) ] ].
	^ self new
		  setDifferingPixelCount: differing
		  maximumChannelDistance: maximum
		  extraneousPixelCount: extraneous
]

{ #category : 'private' }
VGFormComparison class >> channelDistanceBetween: aWord and: anotherWord [
	^ ((0 to: 24 by: 8) collect: [ :shift |
		   (((aWord bitShift: shift negated) bitAnd: 255)
		    - ((anotherWord bitShift: shift negated) bitAnd: 255)) abs ]) max
]

{ #category : 'comparing' }
VGFormComparison class >> premultiplied: aWord [
	"A Form holds unpremultiplied channels, and a fully transparent pixel is stored as transparent
	 white. Unpremultiplied, that pixel and a pixel one step of coverage away from it read as the
	 whole range apart, which would report a difference of 255 where the pictures differ by one
	 two-hundred-and-fifty-fifth of coverage. Premultiplying first measures what the eye sees."

	| alpha pixelFormat |
	pixelFormat := VGCairoSurfaceFormat argb32.
	alpha := (aWord bitShift: -24) bitAnd: 255.
	^ (alpha bitShift: 24)
	  +
		  ((pixelFormat
			    premultiplyChannel: ((aWord bitShift: -16) bitAnd: 255)
			    byAlpha: alpha) bitShift: 16)
	  +
		  ((pixelFormat
			    premultiplyChannel: ((aWord bitShift: -8) bitAnd: 255)
			    byAlpha: alpha) bitShift: 8)
	  + (pixelFormat premultiplyChannel: (aWord bitAnd: 255) byAlpha: alpha)
]

{ #category : 'initialization' }
VGFormComparison >> beIncomparable [
	isComparable := false.
	differingPixelCount := 0.
	maximumChannelDistance := 0.
	extraneousPixelCount := 0
]

{ #category : 'accessing' }
VGFormComparison >> differingPixelCount [
	^ differingPixelCount
]

{ #category : 'accessing' }
VGFormComparison >> extraneousPixelCount [
	"How many pixels we paint that the reference leaves untouched."

	^ extraneousPixelCount
]

{ #category : 'inspector' }
VGFormComparison >> inspectorVerdict: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Verdict'>
	"What the comparison found. An extraneous pixel is one we paint where the reference is
	 untouched, and it is the number a case holds to zero whatever its tolerance."

	^ aBuilder newTable
		  items: {
				  ('Comparable' -> self isComparable).
				  ('Differing pixels' -> self differingPixelCount).
				  ('Worst channel distance' -> self maximumChannelDistance).
				  ('Extraneous pixels' -> self extraneousPixelCount) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGFormComparison >> inspectorVerdictContext: aContext [
	aContext active: isComparable notNil
]

{ #category : 'testing' }
VGFormComparison >> isComparable [
	^ isComparable
]

{ #category : 'accessing' }
VGFormComparison >> maximumChannelDistance [
	^ maximumChannelDistance
]

{ #category : 'printing' }
VGFormComparison >> printOn: aStream [
	super printOn: aStream.
	isComparable ifFalse: [ ^ aStream nextPutAll: '(incomparable extents)' ].
	aStream
		nextPut: $(;
		print: differingPixelCount;
		nextPutAll: ' pixels differ, up to ';
		print: maximumChannelDistance;
		nextPutAll: ' per channel, ';
		print: extraneousPixelCount;
		nextPutAll: ' outside the reference)'
]

{ #category : 'initialization' }
VGFormComparison >> setDifferingPixelCount: anInteger maximumChannelDistance: anotherInteger extraneousPixelCount: aThirdInteger [
	isComparable := true.
	differingPixelCount := anInteger.
	maximumChannelDistance := anotherInteger.
	extraneousPixelCount := aThirdInteger
]
