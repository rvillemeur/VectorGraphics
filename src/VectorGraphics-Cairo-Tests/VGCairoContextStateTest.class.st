"
I state the facts of the unit 1.2 context: the current transformation matrix, the state stack
that restoreStateAfter: unwinds, and what a singular matrix does to a context. The source, the fill
rule and the clip are set straight on the state, because the context selectors that set them belong
to later units; what I pin here is that the stack carries all four together.
"
Class {
	#name : 'VGCairoContextStateTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'support' }
VGCairoContextStateTest >> assertMatrix: aMatrix isCloseTo: anotherMatrix [
	#( #sx #shy #shx #sy #x #y ) do: [ :each |
		self
			assert: ((aMatrix perform: each) closeTo: (anotherMatrix perform: each) precision: self precision)
			description: each , ' differs' ]
]

{ #category : 'support' }
VGCairoContextStateTest >> newContext [
	^ (VGCairoImageSurface extent: 32 @ 32) newContext
]

{ #category : 'support' }
VGCairoContextStateTest >> precision [
	^ 1.0e-12
]

{ #category : 'support' }
VGCairoContextStateTest >> singularMatrix [
	"Both axes land on the same line, so the determinant is zero and Cairo refuses the matrix."
	^ VGCairoMatrix newX: 0 y: 0 sx: 2 sy: 2 shx: 1 shy: 4
]

{ #category : 'tests' }
VGCairoContextStateTest >> testContextInErrorDrawsNothing [
	"Cairo keeps a context in error from painting: measured on a live context, a paint after a
	 singular matrix leaves every pixel untouched."
	| surface context |
	surface := VGCairoImageSurface extent: 4 @ 4.
	context := surface newContext.
	context matrix: self singularMatrix.
	context clearColor: Color red.
	self assert: (surface pixelAtX: 0 y: 0) equals: 0
]

{ #category : 'tests - cairo' }
VGCairoContextStateTest >> testContextInErrorDrawsNothingJustAsCairoDoes [
	| ours cairoSurface cairoContext |
	VGCairoInventory isLiveCairoAvailable ifFalse: [ ^ self skip ].
	ours := self singularMatrix.
	cairoSurface := AeCairoImageSurface extent: 4 @ 4.
	cairoContext := cairoSurface newContext.
	cairoContext matrix: (AeCairoMatrix
			 newX: ours x
			 y: ours y
			 sx: ours sx
			 sy: ours sy
			 shx: ours shx
			 shy: ours shy).
	cairoContext
		sourceColor: Color red;
		paint.
	cairoSurface flush.
	self assert: (cairoSurface data uint32AtOffset: 0) equals: 0
]

{ #category : 'tests - source' }
VGCairoContextStateTest >> testEverySourceSetterIsIgnoredOnceTheContextIsInError [
	"A latched context ignores every request, so the source it had when it latched is the source it
	 still has."

	| context source |
	context := self newContext.
	context sourceColor: Color red.
	source := context source.
	context matrix: self singularMatrix.
	self assert: context isInError.
	context
		sourceColor: Color blue;
		sourceColorR: 0 g: 1 b: 0;
		sourceColorR: 0 g: 1 b: 0 a: 0.5;
		sourcePattern: (VGCairoColorPattern r: 0 g: 1 b: 0);
		sourceSurface: (VGCairoImageSurface extent: 4 @ 4);
		sourceSurface: (VGCairoImageSurface extent: 4 @ 4) x: 1 y: 1.
	self assert: context source identicalTo: source
]

{ #category : 'tests - source' }
VGCairoContextStateTest >> testEverySourceSetterLeavesAPatternOfItsOwnType [
	"Cairo answers the pattern it was given rather than a copy of it, so a caller that keeps a
	 pattern and asks the context for its source holds the same thing twice."

	| context pattern |
	context := self newContext.
	context sourceColor: Color red.
	self assert: context source type equals: #solid.
	context sourceColorR: 0.1 g: 0.2 b: 0.3.
	self assert: context source type equals: #solid.
	context sourceColorR: 0.1 g: 0.2 b: 0.3 a: 0.4.
	self assert: context source type equals: #solid.
	pattern := VGCairoLinearGradientPattern from: 0 @ 0 to: 8 @ 0.
	context sourcePattern: pattern.
	self assert: context source type equals: #linear.
	self assert: context source identicalTo: pattern.
	context sourcePattern: (VGCairoRadialGradientPattern
			 innerCenter: 0 @ 0
			 innerRadius: 1
			 outerCenter: 0 @ 0
			 outerRadius: 8).
	self assert: context source type equals: #radial.
	context sourceSurface: (VGCairoImageSurface extent: 4 @ 4).
	self assert: context source type equals: #surface
]

{ #category : 'tests' }
VGCairoContextStateTest >> testFreshContextHasTheIdentityMatrix [
	self assert: self newContext matrix isIdentity
]

{ #category : 'tests' }
VGCairoContextStateTest >> testFreshContextIsNotInError [
	| context |
	context := self newContext.
	self assert: context status isSuccess.
	self deny: context isInError
]

{ #category : 'tests' }
VGCairoContextStateTest >> testMatrixAnswersACopyThatCannotChangeTheContext [
	"Alexandrie answers a fresh matrix from #matrix, so mutating what a caller got must not move the
	 context."
	| context answered |
	context := self newContext.
	answered := context matrix.
	answered translateByX: 100 y: 100.
	self assert: context matrix isIdentity
]

{ #category : 'tests' }
VGCairoContextStateTest >> testMatrixSetterReplacesTheCurrentMatrix [
	| context |
	context := self newContext.
	context matrix: (VGCairoMatrix newScalingByX: 4 y: 4).
	self assert: (context matrix value: 1 @ 1) equals: 4 @ 4
]

{ #category : 'tests' }
VGCairoContextStateTest >> testPatternMatrixDefaultsToIdentityAndRoundTrips [
	| pattern matrix |
	pattern := VGCairoColorPattern new.
	self assert: pattern matrix isIdentity.
	matrix := VGCairoMatrix newScalingByX: 2 y: 2.
	pattern matrix: matrix.
	self assert: (pattern matrix value: 1 @ 1) equals: 2 @ 2
]

{ #category : 'tests' }
VGCairoContextStateTest >> testPoppingAGroupThatWasNeverPushedLatchesAnInvalidPopGroup [
	"Cairo reports a pop with no push as CAIRO_STATUS_INVALID_POP_GROUP, and a latched context
	 then draws nothing. The code is read from a live Cairo context here rather than written
	 from memory."
	| reference context |
	reference := (AeCairoImageSurface extent: 32 @ 32) newContext.
	reference popGroupToSource.
	self assert: reference status asInteger equals: VGCairoStatus invalidPopGroupCode.
	context := self newContext.
	context popGroupToSource.
	self assert: context status code equals: VGCairoStatus invalidPopGroupCode.
	self assert: context isInError.
	context
		sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0;
		paint.
	self assert: context currentTarget displayList isEmpty
]

{ #category : 'tests' }
VGCairoContextStateTest >> testPushingAGroupRedirectsTheTargetAndSavesTheState [
	"Cairo's push_group saves the state as well as redirecting the target, and both pops restore
	 it, so an operator set inside a group does not survive the pop."
	| context target group pattern |
	context := self newContext.
	target := context currentTarget.
	context pushGroup.
	group := context currentTarget.
	self deny: group == target.
	self assert: group extent equals: target extent.
	context setOperatorClear.
	self assert: context currentOperator equals: VGCairoOperator clear.
	pattern := context popGroupAsSurfacePattern.
	self assert: context currentTarget == target.
	self assert: context currentOperator equals: VGCairoOperator over.
	self assert: pattern surface == group
]

{ #category : 'tests' }
VGCairoContextStateTest >> testRestoreStateAfterNests [
	| context |
	context := self newContext.
	context restoreStateAfter: [
		context translateBy: 1 @ 0.
		context restoreStateAfter: [ context translateBy: 10 @ 0 ].
		self assert: (context matrix value: 0 @ 0) equals: 1 @ 0 ].
	self assert: context matrix isIdentity
]

{ #category : 'tests' }
VGCairoContextStateTest >> testRestoreStateAfterRestoresMatrixSourceFillRuleAndClipTogether [
	"The gate: the four pieces of state come back together. The source is the pattern itself and
	 not a copy of it, which is what Cairo keeps, so it is compared by identity. The fill rule and
	 the clip are still set on the state, because the context selectors that set them belong to
	 later units."

	| context source fillRule clip |
	context := self newContext.
	source := VGCairoColorPattern r: 1.0 g: 0.0 b: 0.0.
	fillRule := #evenOdd.
	clip := 0 @ 0 corner: 4 @ 4.
	context sourcePattern: source.
	context state fillRule: fillRule.
	context state clip: clip.
	context restoreStateAfter: [
		context translateBy: 9 @ 9.
		context sourceColor: Color blue.
		context state fillRule: #winding.
		context state clip: nil ].
	self assert: context matrix isIdentity.
	self assert: context source identicalTo: source.
	self assert: context state fillRule equals: fillRule.
	self assert: context state clip equals: clip
]

{ #category : 'tests' }
VGCairoContextStateTest >> testRestoreStateAfterUnwindsOnError [
	"A painting block that raises must not leave the context transformed, or the next frame draws in
	 the wrong place."
	| context |
	context := self newContext.
	self
		should: [
			context restoreStateAfter: [
				context translateBy: 7 @ 7.
				self error: 'painting failed' ] ]
		raise: Error.
	self assert: context matrix isIdentity
]

{ #category : 'tests' }
VGCairoContextStateTest >> testSetIdentityMatrixResetsTheCurrentMatrix [
	| context |
	context := self newContext.
	context
		translateBy: 5 @ 5;
		setIdentityMatrix.
	self assert: context matrix isIdentity
]

{ #category : 'tests' }
VGCairoContextStateTest >> testSingularMatrixPutsTheContextInErrorRatherThanRaising [
	"Cairo answers CAIRO_STATUS_INVALID_MATRIX from the context and draws nothing afterwards; it
	 does not signal."
	| context |
	context := self newContext.
	context matrix: self singularMatrix.
	self deny: context status isSuccess.
	self assert: context isInError
]

{ #category : 'tests - cairo' }
VGCairoContextStateTest >> testSingularMatrixStatusMatchesCairo [
	| ours context cairoContext |
	VGCairoInventory isLiveCairoAvailable ifFalse: [ ^ self skip ].
	ours := self singularMatrix.
	context := self newContext.
	context matrix: ours.
	cairoContext := (AeCairoImageSurface extent: 2 @ 2) newContext.
	cairoContext matrix: (AeCairoMatrix
			 newX: ours x
			 y: ours y
			 sx: ours sx
			 sy: ours sy
			 shx: ours shx
			 shy: ours shy).
	self assert: context status isSuccess equals: cairoContext status isSuccess
]

{ #category : 'tests' }
VGCairoContextStateTest >> testStateIsCopiedNotShared [
	"The state the block worked on is not the state that comes back, so a change made inside it is
	 gone afterwards."
	| context inner |
	context := self newContext.
	context state fillRule: #winding.
	inner := context restoreStateAfter: [
		         context state fillRule: #evenOdd.
		         context state ].
	self deny: inner == context state.
	self assert: context state fillRule equals: #winding
]

{ #category : 'tests' }
VGCairoContextStateTest >> testSurfaceDeviceScaleMatrixIsAScalingMatrix [
	| surface |
	surface := VGCairoImageSurface extent: 8 @ 8.
	surface deviceScaleX: 2 y: 3.
	self assert: (surface deviceScaleMatrix value: 1 @ 1) equals: 2 @ 3
]

{ #category : 'tests - source' }
VGCairoContextStateTest >> testTheDefaultSourceIsAnOpaqueBlackSolidPattern [
	"Measured: a fresh Cairo context paints opaque black, and the pattern it answers for its source
	 is a solid one."

	| surface context |
	surface := VGCairoImageSurface extent: 4 @ 4.
	context := surface newContext.
	self assert: context source type equals: #solid.
	context paint.
	self assert: (surface pixelAtX: 1 y: 1) equals: 16rFF000000
]

{ #category : 'tests' }
VGCairoContextStateTest >> testTransformWithAppliesAnAdditionalTransformation [
	| context |
	context := self newContext.
	context
		translateBy: 1 @ 1;
		transformWith: (VGCairoMatrix newScalingByX: 2 y: 2).
	self assert: (context matrix value: 1 @ 1) equals: 3 @ 3
]

{ #category : 'tests' }
VGCairoContextStateTest >> testTranslateScaleAndRotateChangeTheCurrentMatrix [
	| context expected |
	context := self newContext.
	context
		translateBy: 10 @ 20;
		scaleBy: 2 @ 3;
		rotateByRadians: Float pi / 5.
	expected := VGCairoMatrix newIdentity
		            translateByX: 10 y: 20;
		            scaleByX: 2 y: 3;
		            rotateByRadians: Float pi / 5;
		            yourself.
	self assertMatrix: context matrix isCloseTo: expected
]
