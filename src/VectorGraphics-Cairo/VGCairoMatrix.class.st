"
I am an affine transformation, in the six numbers and the field names Cairo uses: a point is
mapped to (sx * x + shx * y + x) @ (shy * x + sy * y + y). Cairo's composition order is mine:
#translateBy:, #scaleBy: and #rotateByRadians: build a transformation that acts first and is then
followed by what I already held, which is why #translateBy: on a scaling matrix moves by the scaled
distance. #invert answers a status rather than signalling when I am singular, as Cairo does, and
#inverted signals, as Alexandrie's does. Six numbers decide my equality.
"
Class {
	#name : 'VGCairoMatrix',
	#superclass : 'Object',
	#instVars : [
		'sx',
		'shy',
		'shx',
		'sy',
		'x',
		'y'
	],
	#category : 'VectorGraphics-Cairo-Matrix',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Matrix'
}

{ #category : 'arithmetic' }
VGCairoMatrix class >> multiply: aMatrix by: anotherMatrix into: aResultMatrix [
	"Cairo's cairo_matrix_multiply: the result applies aMatrix first and anotherMatrix after it.
	 aResultMatrix may be either argument, so every number is read before any is written."
	^ aResultMatrix
		  beX:
			  aMatrix x * anotherMatrix sx + (aMatrix y * anotherMatrix shx)
			  + anotherMatrix x
		  y:
			  aMatrix x * anotherMatrix shy + (aMatrix y * anotherMatrix sy)
			  + anotherMatrix y
		  sx: aMatrix sx * anotherMatrix sx + (aMatrix shy * anotherMatrix shx)
		  sy: aMatrix shx * anotherMatrix shy + (aMatrix sy * anotherMatrix sy)
		  shx: aMatrix shx * anotherMatrix sx + (aMatrix sy * anotherMatrix shx)
		  shy: aMatrix sx * anotherMatrix shy + (aMatrix shy * anotherMatrix sy)
]

{ #category : 'instance creation' }
VGCairoMatrix class >> newFrom: aMatrix [
	"A matrix of mine holding the same six numbers as the argument, which may be an Alexandrie
	 matrix: it answers the same six accessors."
	^ self
		  newX: aMatrix x
		  y: aMatrix y
		  sx: aMatrix sx
		  sy: aMatrix sy
		  shx: aMatrix shx
		  shy: aMatrix shy
]

{ #category : 'instance creation' }
VGCairoMatrix class >> newIdentity [
	^ self new beIdentity
]

{ #category : 'instance creation' }
VGCairoMatrix class >> newRotationByRadians: anAngle [
	^ self new beRotationByRadians: anAngle
]

{ #category : 'instance creation' }
VGCairoMatrix class >> newScalingBy: aPoint [
	^ self newScalingByX: aPoint x y: aPoint y
]

{ #category : 'instance creation' }
VGCairoMatrix class >> newScalingByX: aNumber y: anotherNumber [
	^ self new beScaleByX: aNumber y: anotherNumber
]

{ #category : 'instance creation' }
VGCairoMatrix class >> newTranslationBy: aPoint [
	^ self newTranslationByX: aPoint x y: aPoint y
]

{ #category : 'instance creation' }
VGCairoMatrix class >> newTranslationByX: tx y: ty [
	^ self new beTranslationByX: tx y: ty
]

{ #category : 'instance creation' }
VGCairoMatrix class >> newX: aX y: aY sx: aSx sy: aSy shx: aShx shy: aShy [
	^ self new beX: aX y: aY sx: aSx sy: aSy shx: aShx shy: aShy
]

{ #category : 'comparing' }
VGCairoMatrix >> = anObject [
	self == anObject ifTrue: [ ^ true ].
	self class = anObject class ifFalse: [ ^ false ].
	^ sx = anObject sx and: [
		  shy = anObject shy and: [
			  shx = anObject shx and: [
				  sy = anObject sy and: [ x = anObject x and: [ y = anObject y ] ] ] ] ]
]

{ #category : 'initialization' }
VGCairoMatrix >> beIdentity [
	self
		beX: 0
		y: 0
		sx: 1
		sy: 1
		shx: 0
		shy: 0
]

{ #category : 'initialization' }
VGCairoMatrix >> beMultiplicationOf: aMatrix by: anotherMatrix [
	self class multiply: aMatrix by: anotherMatrix into: self
]

{ #category : 'initialization' }
VGCairoMatrix >> beRotationByRadians: anAngle [
	"Positive angles turn the positive X axis towards the positive Y axis, which with Cairo's axes
	 is clockwise on screen."
	| cosine sine |
	cosine := anAngle cos.
	sine := anAngle sin.
	self
		beX: 0
		y: 0
		sx: cosine
		sy: cosine
		shx: sine negated
		shy: sine
]

{ #category : 'initialization' }
VGCairoMatrix >> beScaleBy: aPoint [
	self beScaleByX: aPoint x y: aPoint y
]

{ #category : 'initialization' }
VGCairoMatrix >> beScaleByX: aNumber y: anotherNumber [
	self
		beX: 0
		y: 0
		sx: aNumber
		sy: anotherNumber
		shx: 0
		shy: 0
]

{ #category : 'initialization' }
VGCairoMatrix >> beTranslationBy: aPoint [
	self beTranslationByX: aPoint x y: aPoint y
]

{ #category : 'initialization' }
VGCairoMatrix >> beTranslationByX: tx y: ty [
	self
		beX: tx
		y: ty
		sx: 1
		sy: 1
		shx: 0
		shy: 0
]

{ #category : 'initialization' }
VGCairoMatrix >> beX: x0 y: y0 sx: xx sy: yy shx: xy shy: yx [
	"The six numbers in Cairo's own order of meaning: a point is mapped to
	 (xx * x + xy * y + x0) @ (yx * x + yy * y + y0)."
	x := x0.
	y := y0.
	sx := xx.
	sy := yy.
	shx := xy.
	shy := yx
]

{ #category : 'testing' }
VGCairoMatrix >> determinant [
	^ sx * sy - (shy * shx)
]

{ #category : 'comparing' }
VGCairoMatrix >> hash [
	^ (((sx hash bitXor: shy hash) bitXor: shx hash) bitXor: sy hash) bitXor:
		  (x hash bitXor: y hash)
]

{ #category : 'inspecting' }
VGCairoMatrix >> inspectorMapping: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Mapping'>
	^ aBuilder newTable
		  items: self mappingDescription;
		  addColumn: (SpStringTableColumn
				   title: 'User space'
				   evaluated: [ :each | (each at: 1) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Mapped'
				   evaluated: [ :each | (each at: 2) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Mapped back'
				   evaluated: [ :each |
					   (each at: 3) ifNil: [ 'no inverse' ] ifNotNil: [ :point | point printString ] ]);
		  yourself
]

{ #category : 'inspecting' }
VGCairoMatrix >> inspectorMappingContext: aContext [
	aContext active: sx notNil
]

{ #category : 'converting' }
VGCairoMatrix >> invert [
	"Cairo answers a status rather than signalling, because a singular matrix is something a caller
	 is expected to handle: the drawing it would have produced is empty."
	| det adjointX adjointY |
	self isInvertible ifFalse: [ ^ VGCairoStatus invalidMatrix ].
	det := self determinant.
	adjointX := shx * y - (sy * x).
	adjointY := shy * x - (sx * y).
	self
		beX: adjointX / det
		y: adjointY / det
		sx: sy / det
		sy: sx / det
		shx: shx negated / det
		shy: shy negated / det.
	^ VGCairoStatus success
]

{ #category : 'converting' }
VGCairoMatrix >> inverted [
	"An inverted copy, or an error, which is what Alexandrie's #inverted does."
	| inverse |
	inverse := self copy.
	inverse invert ensureIsSuccess.
	^ inverse
]

{ #category : 'testing' }
VGCairoMatrix >> isIdentity [
	^ x = 0 and: [
		  y = 0 and: [ sx = 1 and: [ sy = 1 and: [ shx = 0 and: [ shy = 0 ] ] ] ] ]
]

{ #category : 'testing' }
VGCairoMatrix >> isInvertible [
	"A matrix that collapses the plane onto a line or a point has no inverse, and Cairo refuses one
	 for a determinant that is zero or not a finite number."
	| det |
	det := self determinant.
	det isZero ifTrue: [ ^ false ].
	^ (det isFloat and: [ det isNaN or: [ det isInfinite ] ]) not
]

{ #category : 'inspecting' }
VGCairoMatrix >> mappingDescription [
	"Where I send the corners of the unit square and the two axis tips, and where an inverse of me
	 sends each answer back. The numbers come from #value: and #inverted, so the view cannot drift
	 from the arithmetic."
	| inverse |
	inverse := self isInvertible ifTrue: [ self inverted ].
	^ { 0 @ 0. 1 @ 0. 0 @ 1. 1 @ 1 } collect: [ :each |
		  | mapped |
		  mapped := self value: each.
		  {
			  each.
			  mapped.
			  (inverse ifNil: [ nil ] ifNotNil: [ inverse value: mapped ]) } ]
]

{ #category : 'transforming' }
VGCairoMatrix >> postMultiply: aMatrix [
	"I act first, then aMatrix does."
	self beMultiplicationOf: self copy by: aMatrix
]

{ #category : 'transforming' }
VGCairoMatrix >> preMultiply: aMatrix [
	"aMatrix acts first, then I do."
	self beMultiplicationOf: aMatrix by: self copy
]

{ #category : 'printing' }
VGCairoMatrix >> printOn: aStream [
	aStream nextPutAll: self class name.
	aStream nextPut: $(.
	#( #x #y #sx #sy #shx #shy ) do: [ :each |
		aStream
			nextPutAll: each;
			nextPutAll: ': '.
		(self perform: each) printOn: aStream showingDecimalPlaces: 4 ]
		separatedBy: [ aStream space ].
	aStream nextPut: $)
]

{ #category : 'transforming' }
VGCairoMatrix >> rotateByRadians: anAngle [
	self preMultiply: (self class newRotationByRadians: anAngle)
]

{ #category : 'transforming' }
VGCairoMatrix >> rotateByRadians: anAngle center: aPoint [
	self rotateByRadians: anAngle centerX: aPoint x y: aPoint y
]

{ #category : 'transforming' }
VGCairoMatrix >> rotateByRadians: anAngle centerX: cx y: cy [
	self
		translateByX: cx y: cy;
		rotateByRadians: anAngle;
		translateByX: cx negated y: cy negated
]

{ #category : 'transforming' }
VGCairoMatrix >> scaleBy: aPoint [
	self scaleByX: aPoint x y: aPoint y
]

{ #category : 'transforming' }
VGCairoMatrix >> scaleBy: aPoint center: aCenter [
	self
		scaleByX: aPoint x
		y: aPoint y
		centerX: aCenter x
		y: aCenter y
]

{ #category : 'transforming' }
VGCairoMatrix >> scaleByX: aNumber y: anotherNumber [
	self preMultiply: (self class newScalingByX: aNumber y: anotherNumber)
]

{ #category : 'transforming' }
VGCairoMatrix >> scaleByX: aNumber y: anotherNumber centerX: cx y: cy [
	self
		translateByX: cx y: cy;
		scaleByX: aNumber y: anotherNumber;
		translateByX: cx negated y: cy negated
]

{ #category : 'accessing' }
VGCairoMatrix >> scaleFactors [
	^ sx @ sy
]

{ #category : 'accessing' }
VGCairoMatrix >> shearFactors [
	^ shx @ shy
]

{ #category : 'accessing' }
VGCairoMatrix >> shx [
	^ shx
]

{ #category : 'accessing' }
VGCairoMatrix >> shx: aNumber [
	shx := aNumber
]

{ #category : 'accessing' }
VGCairoMatrix >> shy [
	^ shy
]

{ #category : 'accessing' }
VGCairoMatrix >> shy: aNumber [
	shy := aNumber
]

{ #category : 'accessing' }
VGCairoMatrix >> sx [
	^ sx
]

{ #category : 'accessing' }
VGCairoMatrix >> sx: aNumber [
	sx := aNumber
]

{ #category : 'accessing' }
VGCairoMatrix >> sy [
	^ sy
]

{ #category : 'accessing' }
VGCairoMatrix >> sy: aNumber [
	sy := aNumber
]

{ #category : 'transforming' }
VGCairoMatrix >> translateBy: aPoint [
	self translateByX: aPoint x y: aPoint y
]

{ #category : 'transforming' }
VGCairoMatrix >> translateByX: tx y: ty [
	"Cairo's rule: the translation acts first and what I already hold acts after it."
	self preMultiply: (self class newTranslationByX: tx y: ty)
]

{ #category : 'accessing' }
VGCairoMatrix >> translationFactors [
	^ x @ y
]

{ #category : 'mapping' }
VGCairoMatrix >> value: aPoint [
	"aPoint transformed by me."
	^ self valueX: aPoint x y: aPoint y
]

{ #category : 'mapping' }
VGCairoMatrix >> valueX: aNumber y: anotherNumber [
	^ sx * aNumber + (shx * anotherNumber) + x @ (shy * aNumber + (sy * anotherNumber) + y)
]

{ #category : 'accessing' }
VGCairoMatrix >> x [
	^ x
]

{ #category : 'accessing' }
VGCairoMatrix >> x: aNumber [
	x := aNumber
]

{ #category : 'accessing' }
VGCairoMatrix >> y [
	^ y
]

{ #category : 'accessing' }
VGCairoMatrix >> y: aNumber [
	y := aNumber
]
