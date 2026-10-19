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
		'extraneousPixelCount',
		'maximumStrayAlpha'
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
	"How far our picture is from the reference. Two pictures of different sizes are not
	 comparable, and answer an instance that says so rather than a number a caller could read as
	 agreement."
	| ours theirs comparison |
	ours := aForm asFormOfDepth: 32.
	theirs := aReferenceForm asFormOfDepth: 32.
	ours extent = theirs extent ifFalse: [ ^ self new beIncomparable ].
	comparison := self new beEmptyTally.
	1 to: ours bits size do: [ :index |
		comparison
			addOurPixel: (ours bits at: index)
			againstReference: (theirs bits at: index) ].
	^ comparison
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

	| alpha |
	alpha := self alphaOf: aWord.
	^ (alpha bitShift: 24)
	  +
		  ((self premultipliedByte: ((aWord bitShift: -16) bitAnd: 255) byAlpha: alpha)
			   bitShift: 16)
	  +
		  ((self premultipliedByte: ((aWord bitShift: -8) bitAnd: 255) byAlpha: alpha)
			   bitShift: 8)
	  + (self premultipliedByte: (aWord bitAnd: 255) byAlpha: alpha)
]

{ #category : 'comparing' }
VGFormComparison class >> premultipliedByte: aByte byAlpha: anAlphaByte [
	"One stored channel multiplied by the alpha it carries, both as bytes, so the result is a byte
	 as well. Multiplying a byte by a byte would run into the next channel of the word."

	^ (aByte * anAlphaByte / 255) rounded
]

{ #category : 'measuring' }
VGFormComparison >> addOurPixel: aStoredWord againstReference: anotherStoredWord [
	"One pixel of each picture, as a Form stores it. A Form keeps unpremultiplied bytes, so both
	 are premultiplied before anything is measured. A pixel we paint where the reference is
	 untouched is counted and weighed: an alpha of one is the residue of the grid Cairo rounds a
	 polygon edge to, while a heavier one is a shape we got wrong."
	| ourWord theirWord ourAlpha |
	ourWord := self class premultiplied: aStoredWord.
	theirWord := self class premultiplied: anotherStoredWord.
	(self class alphaOf: theirWord) isZero ifTrue: [
		ourAlpha := self class alphaOf: ourWord.
		ourAlpha isZero ifFalse: [
			extraneousPixelCount := extraneousPixelCount + 1.
			maximumStrayAlpha := maximumStrayAlpha max: ourAlpha ] ].
	ourWord = theirWord ifTrue: [ ^ self ].
	differingPixelCount := differingPixelCount + 1.
	maximumChannelDistance := maximumChannelDistance
		                          max:
		                          (self class
			                           channelDistanceBetween: ourWord
			                           and: theirWord)
]

{ #category : 'initialization' }
VGFormComparison >> beEmptyTally [
	"A comparison of nothing yet: comparable, with every count at zero, ready to be told one
	 pixel at a time."
	isComparable := true.
	differingPixelCount := 0.
	maximumChannelDistance := 0.
	extraneousPixelCount := 0.
	maximumStrayAlpha := 0
]

{ #category : 'initialization' }
VGFormComparison >> beIncomparable [
	isComparable := false.
	differingPixelCount := 0.
	maximumChannelDistance := 0.
	extraneousPixelCount := 0.
	maximumStrayAlpha := 0
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

{ #category : 'inspecting' }
VGFormComparison >> inspectorVerdict: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Verdict'>
	"What the comparison found. An extraneous pixel is one we paint where the reference is
	 untouched, and the gate holds the heaviest of them to the residue a rounded edge leaves,
	 whatever the case tolerance allows a shade to differ by."
	^ aBuilder newTable
		  items: {
				  ('Comparable' -> self isComparable).
				  ('Differing pixels' -> self differingPixelCount).
				  ('Worst channel distance' -> self maximumChannelDistance).
				  ('Extraneous pixels' -> self extraneousPixelCount).
				  ('Heaviest stray alpha' -> self maximumStrayAlpha) };
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

{ #category : 'accessing' }
VGFormComparison >> maximumStrayAlpha [
	"The largest alpha among the pixels we paint that the reference leaves untouched, or zero
	 when there are none. An alpha of one is the residue of a grid Cairo rounds its polygon
	 edges to; anything larger is a wrong shape."
	^ maximumStrayAlpha
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
		nextPutAll: ' outside the reference at up to an alpha of ';
		print: maximumStrayAlpha;
		nextPut: $)
]

{ #category : 'initialization' }
VGFormComparison >> setDifferingPixelCount: anInteger maximumChannelDistance: anotherInteger extraneousPixelCount: aThirdInteger [
	isComparable := true.
	differingPixelCount := anInteger.
	maximumChannelDistance := anotherInteger.
	extraneousPixelCount := aThirdInteger
]

{ #category : 'initialization' }
VGFormComparison >> setDifferingPixelCount: anInteger maximumChannelDistance: anotherInteger extraneousPixelCount: aThirdInteger maximumStrayAlpha: aFourthInteger [
	isComparable := true.
	differingPixelCount := anInteger.
	maximumChannelDistance := anotherInteger.
	extraneousPixelCount := aThirdInteger.
	maximumStrayAlpha := aFourthInteger
]
