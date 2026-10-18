"
I check the skeletons of the Cairo replacement: every selector the inventory names exists, signals VGNotYetImplemented until its unit arrives, and names a unit that VECTORCANVAS-PLAN.md declares.

The point is that a conformance case which touches unfinished behaviour reports the unit that owes it, rather than a doesNotUnderstand or a silent wrong answer. I also hold the meta test that the unit table covers the inventory exactly, so a selector cannot be added to one without the other.
"
Class {
	#name : 'VGCairoSkeletonTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Cairo-Tests-Tests',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Tests'
}

{ #category : 'accessing' }
VGCairoSkeletonTest >> skeletonMethods [
	"Every method of the Cairo replacement that is still a skeleton, found by its send rather than
	 by its protocol name, so that renaming a protocol cannot hide one."

	^ (Smalltalk packageOrganizer packageNamed: 'VectorGraphics-Cairo') methods select: [ :each |
		  each messages includes: #notYetImplementedIn:selector: ]
]

{ #category : 'tests' }
VGCairoSkeletonTest >> testEverySkeletonNamesAUnitThePlanDeclares [
	| unknown |
	unknown := self skeletonMethods
		           select: [ :each |
			           (VGCairoInventory planUnits includes:
				            (each literals detect: [ :one | one isString and: [ one first isDigit ] ])) not ]
		           thenCollect: [ :each | each methodClass name , ' >> ' , each selector ].
	self assert: unknown asArray isEmpty description: unknown asArray printString
]

{ #category : 'tests' }
VGCairoSkeletonTest >> testEverySkeletonNamesItsOwnSelector [
	"A skeleton passes its own selector to the hook. A copy-paste that left the wrong one behind
	 would make a conformance failure name the wrong selector."

	| wrong |
	wrong := self skeletonMethods
		         select: [ :each | (each literals includes: each selector) not ]
		         thenCollect: [ :each | each methodClass name , ' >> ' , each selector ].
	self assert: wrong asArray isEmpty description: wrong asArray printString
]

{ #category : 'tests' }
VGCairoSkeletonTest >> testEverySkeletonSignalsAndTheErrorNamesItsUnit [
	"Send every skeleton for real, with nil arguments, and check what comes back. This is the test
	 that proves the calling surface is complete: a missing selector shows up as a
	 doesNotUnderstand, not as a passing test."

	| failures |
	failures := OrderedCollection new.
	self skeletonMethods do: [ :method |
		| receiver arguments |
		receiver := method methodClass isClassSide
			            ifTrue: [ method methodClass instanceSide ]
			            ifFalse: [ method methodClass instanceSide basicNew ].
		arguments := Array new: method numArgs withAll: nil.
		[ receiver perform: method selector withArguments: arguments.
		  failures add: method methodClass name , ' >> ' , method selector , ' did not signal' ]
			on: VGNotYetImplemented
			do: [ :error |
				error selectorName = method selector ifFalse: [
					failures add: method methodClass name , ' >> ' , method selector , ' signalled for '
						, error selectorName ].
				(VGCairoInventory unitForSelector: method selector) = error unit ifFalse: [
					failures add: method methodClass name , ' >> ' , method selector , ' named unit '
						, error unit printString ] ] ].
	self assert: failures asArray isEmpty description: failures asArray printString
]

{ #category : 'tests - meta' }
VGCairoSkeletonTest >> testTheUnitTableCoversTheInventoryExactly [
	"The table and the inventory are two lists, and a selector added to one and not the other is a
	 silent gap: a skeleton with no unit, or a unit owing a selector nobody sends."

	| tabled |
	tabled := VGCairoInventory selectorUnitTable
		          inject: Set new
		          into: [ :all :each | all addAll: each value; yourself ].
	self
		assertCollection: tabled asSortedCollection asArray
		hasSameElements: VGCairoInventory allInventorySelectors
]
