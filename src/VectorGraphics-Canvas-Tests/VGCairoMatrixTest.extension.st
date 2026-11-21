Extension { #name : 'VGCairoMatrixTest' }

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
