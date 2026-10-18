"
I state the facts of the unit 1.2 matrix: that it composes in Cairo's order, that it maps
points the way Cairo maps them, that inverting a singular matrix reports a status instead of
signalling, and that six numbers decide equality. Several of my tests use the live
AeCairoMatrix as their oracle and skip when Alexandrie is absent.
"
Class {
	#name : 'VGCairoMatrixTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'support' }
VGCairoMatrixTest >> assertMatrix: aMatrix isCloseTo: anotherMatrix [
	#( #sx #shy #shx #sy #x #y ) do: [ :each |
		self
			assert: ((aMatrix perform: each) closeTo: (anotherMatrix perform: each) precision: self precision)
			description: each , ' is ' , (aMatrix perform: each) printString , ' but '
				, (anotherMatrix perform: each) printString , ' was expected' ]
]

{ #category : 'support' }
VGCairoMatrixTest >> assertPoint: aPoint isCloseTo: anotherPoint [
	self assert: (aPoint x closeTo: anotherPoint x precision: self precision).
	self assert: (aPoint y closeTo: anotherPoint y precision: self precision)
]

{ #category : 'support' }
VGCairoMatrixTest >> cairoRotatedAndShearedMatrix [
	^ AeCairoMatrix newIdentity
		  translateByX: 12 y: -5;
		  rotateByRadians: Float pi / 7;
		  scaleByX: 2 y: 3;
		  yourself
]

{ #category : 'support' }
VGCairoMatrixTest >> precision [
	"Our arithmetic is Pharo doubles and Cairo's is C doubles, so they agree to about this much."
	^ 1.0e-12
]

{ #category : 'support' }
VGCairoMatrixTest >> rotatedAndShearedMatrix [
	"A matrix that is neither axis aligned nor shear free, built by the same sequence on ours and on
	 Cairo's, which is what makes it an oracle."
	^ VGCairoMatrix newIdentity
		  translateByX: 12 y: -5;
		  rotateByRadians: Float pi / 7;
		  scaleByX: 2 y: 3;
		  yourself
]

{ #category : 'support' }
VGCairoMatrixTest >> singularMatrix [
	"Both axes land on the same line, so the determinant is zero and no inverse exists."
	^ VGCairoMatrix newX: 0 y: 0 sx: 2 sy: 2 shx: 1 shy: 4
]

{ #category : 'tests' }
VGCairoMatrixTest >> testCopyIsIndependentOfTheOriginal [
	| matrix copy |
	matrix := VGCairoMatrix newIdentity.
	copy := matrix copy.
	copy translateByX: 3 y: 4.
	self assert: matrix isIdentity.
	self assert: (copy value: 0 @ 0) equals: 3 @ 4
]

{ #category : 'tests' }
VGCairoMatrixTest >> testEqualityAndHashFollowTheSixFields [
	| matrix same different |
	matrix := VGCairoMatrix newX: 1 y: 2 sx: 3 sy: 4 shx: 5 shy: 6.
	same := VGCairoMatrix newFrom: matrix.
	different := VGCairoMatrix newFrom: matrix.
	different shx: 50.
	self assert: matrix equals: same.
	self assert: matrix hash equals: same hash.
	self deny: matrix = different
]

{ #category : 'tests' }
VGCairoMatrixTest >> testIdentityMapsPointsUnchanged [
	| matrix |
	matrix := VGCairoMatrix newIdentity.
	self assert: matrix isIdentity.
	self assert: (matrix value: 3 @ 4) equals: 3 @ 4
]

{ #category : 'tests' }
VGCairoMatrixTest >> testInversionMatchesTheCairoMatrix [
	VGCairoInventory isLiveCairoAvailable ifFalse: [ ^ self skip ].
	self
		assertMatrix: self rotatedAndShearedMatrix inverted
		isCloseTo: self cairoRotatedAndShearedMatrix inverted
]

{ #category : 'tests' }
VGCairoMatrixTest >> testInvertedUndoesTheTransformation [
	| matrix point |
	matrix := self rotatedAndShearedMatrix.
	point := 17 @ -3.
	self assertPoint: (matrix inverted value: (matrix value: point)) isCloseTo: point
]

{ #category : 'tests' }
VGCairoMatrixTest >> testMappedCornersMatchTheCairoMatrix [
	"What the gate asks of a rotated and sheared shape, at the only level unit 1.2 can ask it: every
	 corner of the rectangle lands where Cairo lands it. The shape itself arrives with unit 1.3."
	| ours theirs |
	VGCairoInventory isLiveCairoAvailable ifFalse: [ ^ self skip ].
	ours := self rotatedAndShearedMatrix.
	theirs := self cairoRotatedAndShearedMatrix.
	(Rectangle origin: 4 @ 6 corner: 40 @ 22) corners do: [ :each |
		self assertPoint: (ours value: each) isCloseTo: (theirs value: each) ]
]

{ #category : 'tests' }
VGCairoMatrixTest >> testMultiplyAppliesTheFirstMatrixThenTheSecond [
	| first second product |
	first := VGCairoMatrix newTranslationByX: 1 y: 0.
	second := VGCairoMatrix newScalingByX: 10 y: 10.
	product := VGCairoMatrix newIdentity.
	VGCairoMatrix multiply: first by: second into: product.
	self assert: (product value: 0 @ 0) equals: 10 @ 0
]

{ #category : 'tests' }
VGCairoMatrixTest >> testPrintOnNamesTheSixFields [
	| printed |
	printed := (VGCairoMatrix newScalingByX: 2 y: 3) printString.
	#( 'sx' 'sy' 'shx' 'shy' ) do: [ :each |
		self assert: (printed includesSubstring: each) ]
]

{ #category : 'tests' }
VGCairoMatrixTest >> testRotatedAndShearedMatrixMatchesTheCairoMatrix [
	"The unit 1.2 oracle: the same sequence of operations on Cairo's matrix and on ours."
	VGCairoInventory isLiveCairoAvailable ifFalse: [ ^ self skip ].
	self assertMatrix: self rotatedAndShearedMatrix isCloseTo: self cairoRotatedAndShearedMatrix
]

{ #category : 'tests' }
VGCairoMatrixTest >> testRotationAboutACentreLeavesThatCentreFixed [
	| matrix |
	matrix := VGCairoMatrix newIdentity
		          rotateByRadians: Float pi / 3 center: 20 @ 30;
		          yourself.
	self assertPoint: (matrix value: 20 @ 30) isCloseTo: 20 @ 30
]

{ #category : 'tests' }
VGCairoMatrixTest >> testRotationByAQuarterTurnTakesTheXAxisToTheYAxis [
	| matrix |
	matrix := VGCairoMatrix newRotationByRadians: Float pi / 2.
	self assertPoint: (matrix value: 1 @ 0) isCloseTo: 0 @ 1.
	self assertPoint: (matrix value: 0 @ 1) isCloseTo: -1 @ 0
]

{ #category : 'tests - cairo' }
VGCairoMatrixTest >> testSingularInversionFailsExactlyAsCairoDoes [
	| ours theirs |
	VGCairoInventory isLiveCairoAvailable ifFalse: [ ^ self skip ].
	ours := self singularMatrix.
	theirs := AeCairoMatrix
		          newX: ours x
		          y: ours y
		          sx: ours sx
		          sy: ours sy
		          shx: ours shx
		          shy: ours shy.
	self assert: ours invert isSuccess equals: theirs invert isSuccess
]

{ #category : 'tests' }
VGCairoMatrixTest >> testSingularMatrixReportsAStatusAndRefusesToInvert [
	| matrix status |
	matrix := self singularMatrix.
	self deny: matrix isInvertible.
	self assert: matrix determinant equals: 0.
	status := matrix invert.
	self deny: status isSuccess.
	self should: [ matrix inverted ] raise: Error
]

{ #category : 'tests' }
VGCairoMatrixTest >> testTranslateAppliesBeforeTheExistingTransformation [
	"Cairo's rule: the new transformation first translates, then applies what was already there, so
	 scaling by two and then translating by one maps the origin to two, not to one."
	| matrix |
	matrix := (VGCairoMatrix newScalingByX: 2 y: 2)
		          translateByX: 1 y: 1;
		          yourself.
	self assert: (matrix value: 0 @ 0) equals: 2 @ 2
]

{ #category : 'tests' }
VGCairoMatrixTest >> testTranslationAndScalingMapPoints [
	self assert: ((VGCairoMatrix newTranslationByX: 5 y: 7) value: 1 @ 1) equals: 6 @ 8.
	self assert: ((VGCairoMatrix newScalingByX: 2 y: 3) value: 4 @ 5) equals: 8 @ 15.
	self deny: (VGCairoMatrix newScalingByX: 2 y: 3) isIdentity
]
