Class {
	#name : 'FormGlyphTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'helpers' }
FormGlyphTest >> makeForm [

	^ Form extent: 20 @ 10 depth: 32
]

{ #category : 'tests' }
FormGlyphTest >> testAdvanceWidth [

	| g |
	g := FormGlyph form: self makeForm leftOffset: 2 topOffset: 8 advanceWidth: 15.
	self assert: g advanceWidth equals: 15
]

{ #category : 'tests' }
FormGlyphTest >> testDeltaXToCenterDefaultNil [

	| g |
	g := FormGlyph form: self makeForm leftOffset: 0 topOffset: 0 advanceWidth: 10.
	self assert: g deltaXToCenter isNil
]

{ #category : 'tests' }
FormGlyphTest >> testDeltaXToCenterSetter [

	| g |
	g := FormGlyph form: self makeForm leftOffset: 0 topOffset: 0 advanceWidth: 10.
	g deltaXToCenter: 3.5.
	self assert: g deltaXToCenter equals: 3.5
]

{ #category : 'tests' }
FormGlyphTest >> testFormGetter [

	| form g |
	form := self makeForm.
	g := FormGlyph form: form leftOffset: 0 topOffset: 0 advanceWidth: 10.
	self assert: g form == form
]

{ #category : 'tests' }
FormGlyphTest >> testLeftOffset [

	| g |
	g := FormGlyph form: self makeForm leftOffset: -3 topOffset: 0 advanceWidth: 10.
	self assert: g leftOffset equals: -3
]

{ #category : 'tests' }
FormGlyphTest >> testPostCopyCopiesForm [

	| original copy |
	original := FormGlyph form: self makeForm leftOffset: 1 topOffset: 2 advanceWidth: 5.
	copy := original copy.
	self deny: copy form == original form.
	self assert: copy leftOffset equals: 1.
	self assert: copy topOffset equals: 2.
	self assert: copy advanceWidth equals: 5
]

{ #category : 'tests' }
FormGlyphTest >> testRightOffset [

	"rightOffset = form width + leftOffset - advanceWidth = 20 + 2 - 15 = 7"

	| g |
	g := FormGlyph form: self makeForm leftOffset: 2 topOffset: 0 advanceWidth: 15.
	self assert: g rightOffset equals: 7
]

{ #category : 'tests' }
FormGlyphTest >> testTopOffset [

	| g |
	g := FormGlyph form: self makeForm leftOffset: 0 topOffset: 14 advanceWidth: 10.
	self assert: g topOffset equals: 14
]
