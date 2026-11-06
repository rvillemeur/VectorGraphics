"
I hold `TTKernPair`, the two glyph indexes of a kerning pair and the mask that identifies the pair in one number.

The mask is the key a layout looks the pair up by, so three facts are stated: it follows the formula the font format defines, two different pairs never produce the same mask, and it is computed once and kept on the instance — the second ask must answer the cached value, since kerning is looked up per character pair of every string drawn.

The laziness is held in both directions: the mask is absent until it is asked for, and present afterwards.
"
Class {
	#name : 'TTKernPairTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-TrueType-Tests-Tests',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
TTKernPairTest >> testAccessors [

	| kp |
	kp := TTKernPair new.
	kp left: 10.
	kp right: 20.
	kp value: -5.
	self assert: kp left equals: 10.
	self assert: kp right equals: 20.
	self assert: kp value equals: -5
]

{ #category : 'tests' }
TTKernPairTest >> testMaskDistinguishesDifferentPairs [

	| m1 m2 |
	m1 := TTKernPair maskFor: 1 with: 2.
	m2 := TTKernPair maskFor: 2 with: 1.
	self assert: m1 ~= m2
]

{ #category : 'tests' }
TTKernPairTest >> testMaskFormula [

	self
		assert: (TTKernPair maskFor: 3 with: 5)
		equals: (3 bitShift: 12) + 5
]

{ #category : 'tests' }
TTKernPairTest >> testMaskIsCachedOnInstance [

	| kp m1 m2 |
	kp := TTKernPair new.
	kp left: 1.
	kp right: 3.
	m1 := kp mask.
	m2 := kp mask.
	self assert: m1 = m2
]

{ #category : 'tests' }
TTKernPairTest >> testMaskIsLazyOnInstance [

	| kp |
	kp := TTKernPair new.
	kp left: 7.
	kp right: 2.
	self assert: kp mask equals: (TTKernPair maskFor: 7 with: 2)
]
