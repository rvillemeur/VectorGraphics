"
I am the rounding of one box diameter of a Gaussian blur, written the way a device can divide.

VGA8GaussianBlurFilter writes `(sum * (1.0 / diameter)) floor` for the average of a window. That is not always the whole quotient of the sum by the diameter: for twenty diameters out of the first four hundred the Float64 reciprocal is rounded down far enough that the product of an exact multiple of the diameter falls just under the integer, and the floor then loses a unit. The deviation happens only at exact multiples and is always exactly one down.

A SPIR-V kernel has no Float64, so it divides in integers and subtracts one where the filter does. I carry the quotients that need that subtraction as a bit each, in the words the kernel indexes by the quotient, and I answer the average the same way the kernel computes it. The table is built by asking the filter rather than by naming the diameters, so the two cannot part.

Key methods: `ofDiameter:`, `averageOfSum:`, `correctsQuotient:`, `correctionWords`.
"
Class {
	#name : 'VGBlurRounding',
	#superclass : 'Object',
	#instVars : [
		'diameter',
		'correctionWords'
	],
	#category : 'VectorGraphics-Vulkan-Blur',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Blur'
}

{ #category : 'constants' }
VGBlurRounding class >> correctionWordCount [
	"The words the table of corrections occupies, one bit a quotient."

	^ self quotientLimit // self wordBitCount
]

{ #category : 'instance creation' }
VGBlurRounding class >> ofDiameter: anInteger [
	^ self new setDiameter: anInteger
]

{ #category : 'constants' }
VGBlurRounding class >> quotientLimit [
	"The quotients the table covers. A sample of a mask is a byte and a window holds one sample a
	 tap, so a window sum is at most 255 times the diameter and its quotient never passes 255."

	^ 256
]

{ #category : 'constants' }
VGBlurRounding class >> wordBitCount [
	"The bits of a word of the correction buffer, which is the width of a SPIR-V integer."

	^ 32
]

{ #category : 'accessing' }
VGBlurRounding >> averageOfSum: aSum [
	"The byte the filter writes for this window sum, computed the way the kernel computes it: a
	 whole division, then one off where the floor of the Float64 product loses a unit. The
	 deviation happens only at an exact multiple of the diameter, which is why the remainder gates
	 it."

	| quotient |
	quotient := aSum // diameter.
	((aSum - (quotient * diameter)) isZero and: [ self correctsQuotient: quotient ])
		ifTrue: [ ^ quotient - 1 ].
	^ quotient
]

{ #category : 'accessing' }
VGBlurRounding >> correctedQuotients [
	"Every quotient of my diameter the host filter's floor loses a unit on, asked of my own
	 predicate rather than read out of the table, so a caller sees what the kernel will do."

	^ (0 to: self class quotientLimit - 1) select: [ :each |
		  self correctsQuotient: each ]
]

{ #category : 'accessing' }
VGBlurRounding >> correctionWords [
	"One bit a quotient, least significant bit first, in the words the kernel indexes by the
	 quotient over the bits of a word."

	^ correctionWords
]

{ #category : 'accessing' }
VGBlurRounding >> correctsAnyQuotient [
	"Whether this diameter needs the correction at all. Twenty diameters of the first four hundred
	 do; for the rest the whole division is already what the filter writes."

	^ correctionWords anySatisfy: [ :each | each isZero not ]
]

{ #category : 'accessing' }
VGBlurRounding >> correctsQuotient: anInteger [
	| bitCount |
	bitCount := self class wordBitCount.
	^ (((correctionWords at: anInteger // bitCount + 1)
		    bitShift: (anInteger \\ bitCount) negated) bitAnd: 1) = 1
]

{ #category : 'accessing' }
VGBlurRounding >> diameter [
	^ diameter
]

{ #category : 'inspector' }
VGBlurRounding >> inspectorCorrections: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Corrections'>
	"The quotients my diameter needs a unit subtracted from, each with the sum it is the quotient
	 of, the average the host filter answers for that sum and the average I answer. The two
	 averages are asked of the arithmetic, so a diameter whose table is empty shows an empty tab
	 and a corrected one shows the two columns differing by one wherever the bit is set."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Quotient'
				   evaluated: [ :each | each printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Sum'
				   evaluated: [ :each | (each * diameter) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Host'
				   evaluated: [ :each |
					   (VGA8GaussianBlurFilter
						    averageOfSum: each * diameter
						    overDiameter: diameter) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Device'
				   evaluated: [ :each |
					   (self averageOfSum: each * diameter) printString ]);
		  items: self correctedQuotients;
		  yourself
]

{ #category : 'inspector' }
VGBlurRounding >> inspectorCorrectionsContext: aContext [
	aContext active: diameter notNil
]

{ #category : 'initialization' }
VGBlurRounding >> setDiameter: anInteger [
	"The table is built by asking VGA8GaussianBlurFilter what it writes for each exact multiple of
	 the diameter, and never by naming the diameters that need a correction, so a change to the
	 filter's arithmetic reaches the device without this class being edited."

	| bitCount |
	diameter := anInteger.
	bitCount := self class wordBitCount.
	correctionWords := Array new: self class correctionWordCount withAll: 0.
	0 to: self class quotientLimit - 1 do: [ :quotient |
		| written index |
		written := VGA8GaussianBlurFilter
			           averageOfSum: quotient * diameter
			           overDiameter: diameter.
		written = quotient ifFalse: [
			index := quotient // bitCount + 1.
			correctionWords
				at: index
				put: ((correctionWords at: index) bitOr: (1 bitShift: quotient \\ bitCount)) ] ]
]
