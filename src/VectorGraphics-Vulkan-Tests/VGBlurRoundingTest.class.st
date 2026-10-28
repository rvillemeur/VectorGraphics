"
I hold the integer rounding the device blur divides with to the rounding VGA8GaussianBlurFilter really writes.

The software filter multiplies a window sum by the reciprocal of the diameter in Float64 and floors the product, which is not always the whole quotient of the sum by the diameter: for some diameters the reciprocal is rounded down and an exact multiple of the diameter then falls just under the integer. A device kernel has no Float64, so it divides and corrects, and VGBlurRounding carries the table of quotients that need the correction. If that table is wrong by one bit the device writes a byte of difference into a shadow, so it is checked against the filter itself and not against a list written down here.
"
Class {
	#name : 'VGBlurRoundingTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'fixtures' }
VGBlurRoundingTest >> diameterLimit [
	"Every diameter up to four hundred and one is checked, which is eight times the widest box a
	 sixty-four point shadow asks for, so a diameter a caller could plausibly reach is inside the
	 range and the twenty corrections the table names are the whole of them."

	^ 401
]

{ #category : 'tests' }
VGBlurRoundingTest >> testADiameterOfOneCorrectsNothingAndAnswersTheSumItself [
	"The degenerate box, which a radius of zero would ask for: a window of one sample, whose
	 average is the sample."

	| rounding |
	rounding := VGBlurRounding ofDiameter: 1.
	self deny: rounding correctsAnyQuotient.
	0 to: 255 do: [ :sum | self assert: (rounding averageOfSum: sum) equals: sum ]
]

{ #category : 'tests' }
VGBlurRoundingTest >> testNoWindowSumHasAQuotientPastTheTableTheKernelCarries [
	"A sample is a byte and a window holds one sample a tap, so the sum of a window is at most 255
	 times the diameter and its quotient is at most 255 whatever the diameter is. The table is
	 that long and no longer, and a quotient past its end would read another quotient's bit."

	1 to: self diameterLimit do: [ :diameter |
		self assert: 255 * diameter // diameter < VGBlurRounding quotientLimit ]
]

{ #category : 'tests' }
VGBlurRoundingTest >> testTheAverageOfAnExactMultipleAgreesWithTheFilterForEveryDiameter [
	"The filter's arithmetic parts from a whole division only at exact multiples of the diameter,
	 so that is where the table has to be right, and every diameter in range is asked rather than
	 a sample of them."

	1 to: self diameterLimit do: [ :diameter |
		| rounding |
		rounding := VGBlurRounding ofDiameter: diameter.
		0 to: VGBlurRounding quotientLimit - 1 do: [ :quotient |
			self
				assert: (rounding averageOfSum: quotient * diameter)
				equals: (VGA8GaussianBlurFilter
						 averageOfSum: quotient * diameter
						 overDiameter: diameter) ] ]
]

{ #category : 'tests' }
VGBlurRoundingTest >> testTheAverageOfEverySumAgreesWithTheFilterOnTheDiametersThatCorrect [
	"Every sum a window can carry, not only the multiples, over the three smallest diameters, the
	 four below four hundred that correct the most quotients, and the largest diameter in range. A
	 correction that fired at a sum the filter does not move would show here and nowhere else."

	#( 1 2 3 7 49 103 249 401 ) do: [ :diameter |
		| rounding |
		rounding := VGBlurRounding ofDiameter: diameter.
		0 to: 255 * diameter do: [ :sum |
			self
				assert: (rounding averageOfSum: sum)
				equals: (VGA8GaussianBlurFilter averageOfSum: sum overDiameter: diameter) ] ]
]

{ #category : 'tests' }
VGBlurRoundingTest >> testTheCorrectedQuotientsAreTheOnesTheFilterLosesAUnitOn [
	"The quotients a rounding answers are exactly those where the host filter's own average of an
	 exact multiple is not the multiplier, over a diameter that deviates and one that does not, and
	 none of them lies outside the table the kernel carries."

	#( 49 50 ) do: [ :diameter |
		| rounding wanted |
		rounding := VGBlurRounding ofDiameter: diameter.
		wanted := (0 to: VGBlurRounding quotientLimit - 1) select: [ :quotient |
			          (VGA8GaussianBlurFilter
				           averageOfSum: quotient * diameter
				           overDiameter: diameter) ~= quotient ].
		self
			assert: rounding correctedQuotients asArray = wanted asArray
			description: 'the corrected quotients of diameter ' , diameter printString
				, ' are not the ones the filter loses a unit on' ].
	self assert: (VGBlurRounding ofDiameter: 50) correctedQuotients isEmpty.
	self deny: (VGBlurRounding ofDiameter: 49) correctedQuotients isEmpty
]

{ #category : 'tests' }
VGBlurRoundingTest >> testTheCorrectionWordsHoldOneBitPerQuotientInTheOrderTheKernelReadsThem [
	"The table reaches the device as the words of a buffer and the kernel indexes them by the
	 quotient: the word is the quotient over the bits of a word and the bit is the remainder. A
	 table laid out in another order would answer every question right in the image and write the
	 wrong byte on the device, so the words themselves are read here."

	| rounding words bitCount |
	rounding := VGBlurRounding ofDiameter: 249.
	words := rounding correctionWords.
	bitCount := VGBlurRounding wordBitCount.
	self assert: words size equals: VGBlurRounding correctionWordCount.
	self assert: VGBlurRounding quotientLimit equals: words size * bitCount.
	0 to: VGBlurRounding quotientLimit - 1 do: [ :quotient |
		| bit |
		bit := ((words at: quotient // bitCount + 1)
			        bitShift: (quotient \\ bitCount) negated) bitAnd: 1.
		self assert: bit = 1 equals: (rounding correctsQuotient: quotient) ]
]

{ #category : 'tests' }
VGBlurRoundingTest >> testTwentyDiametersInRangeCorrectAQuotientAndTheRestDoNot [
	"The diameters whose reciprocal is rounded down far enough to lose a unit, named here so that
	 a change to the filter's arithmetic cannot pass unnoticed: the correction is a device-only
	 workaround for one of twenty diameters out of four hundred, and a unit that grew the set
	 would mean the software arithmetic had moved."

	| correcting |
	correcting := (1 to: self diameterLimit) select: [ :diameter |
		(VGBlurRounding ofDiameter: diameter) correctsAnyQuotient ].
	self
		assert: correcting asArray
		equals: #( 49 98 103 107 161 187 196 197 206 214 237 239 249 253 322 347 374 389 392 394 )
]
