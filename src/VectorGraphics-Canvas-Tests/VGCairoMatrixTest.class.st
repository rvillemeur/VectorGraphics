"
I state the facts of the unit 1.2 matrix: that it composes in Cairo's order, that it maps
points the way Cairo maps them, that inverting a singular matrix reports a status instead of
signalling, and that six numbers decide equality. Several of my tests use the live
AeCairoMatrix as their oracle and skip when Alexandrie is absent.
"
Class {
	#name : 'VGCairoMatrixTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Canvas-Tests-Tests',
	#package : 'VectorGraphics-Canvas-Tests',
	#tag : 'Tests'
}

{ #category : '*VectorGraphics-Canvas-Tests' }
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

{ #category : '*VectorGraphics-Canvas-Tests' }
VGCairoMatrixTest >> testSingularMatrixReportsAStatusAndRefusesToInvert [
	| matrix status |
	matrix := self singularMatrix.
	self deny: matrix isInvertible.
	self assert: matrix determinant equals: 0.
	status := matrix invert.
	self deny: status isSuccess.
	self should: [ matrix inverted ] raise: Error
]
