"
I hold the documents of this package to the code they describe.

The package comment is the map a reader sees first in the browser, so I check that it names every tag the package has and no tag it does not have: a renamed tag fails here instead of sending a reader to a part of the package that is not there. I read only the list under the `Tags:` heading, since the comment holds other lists; `tagNamesNamedBy:` is that reader and is tested on its own degenerate states.

I grow with the other two documentation artefacts of this package: `doc/ARCHITECTURE.md`, whose class and selector names I check against the image, and the inspector views of the engine, whose examples I build. `VGCairoExamplesTest` does the same work for the layers above, but I cannot subclass it: `VGArchitectureTest class >> allowedDependencies` gives this package no outgoing edge, so no class here may name one of `VectorGraphics-Cairo-Tests`.
"
Class {
	#name : 'VectorGraphicsDocumentationTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> packageComment [
	"What a reader sees first when the package is selected in the browser. Pharo keeps it as the
	 comment of the package manifest class."

	^ self packageUnderTest packageComment ifNil: [ '' ]
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> packageUnderTest [
	"The package these tests document: the engine, the path commands and the TrueType code."

	^ PackageOrganizer default packageNamed: 'VectorGraphics'
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> tagHeadingOfThePackageComment [
	"The line the tag list follows. Changing it means changing the comment and this constant
	 together, which is why it is named once here."

	^ 'Tags:'
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> tagNamesNamedBy: aComment [
	"Every name aComment lists as a tag. The list is the one under the Tags: heading, one line a
	 tag, beginning with a dash and the name in backquotes, and it ends at the first line after it
	 that is neither such a line nor blank. A comment holds other lists, so the heading and the end
	 are both needed to tell them apart."

	| lines start names |
	lines := aComment lines.
	start := lines indexOf: self tagHeadingOfThePackageComment.
	start = 0 ifTrue: [ ^ Set new ].
	names := Set new.
	(lines allButFirst: start) do: [ :each |
		(each beginsWith: '- `')
			ifTrue: [
				| rest |
				rest := each allButFirst: 3.
				names add: (rest first: (rest indexOf: $`) - 1) ]
			ifFalse: [ (each trimmed isEmpty and: [ names isEmpty ]) ifFalse: [ ^ names ] ] ].
	^ names
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> tagNamesNamedByThePackageComment [
	"The tags the package comment lists, as strings."

	^ self tagNamesNamedBy: self packageComment
]

{ #category : 'accessing' }
VectorGraphicsDocumentationTest >> tagNamesOfThePackage [
	"The tags the package really has, as strings, so that a comparison with what a document says
	 does not depend on symbols."

	^ (self packageUnderTest tags collect: [ :each | each name asString ]) asSet
]

{ #category : 'tests - package comment' }
VectorGraphicsDocumentationTest >> testThePackageCommentNamesEveryTagOfThePackage [
	"A tag nobody has written down is a part of the package a reader will not look in."

	self tagNamesOfThePackage do: [ :each |
		self
			assert: (self tagNamesNamedByThePackageComment includes: each)
			description: 'The package comment does not name the tag ' , each ]
]

{ #category : 'tests - package comment' }
VectorGraphicsDocumentationTest >> testThePackageCommentNamesNoTagThePackageDoesNotHave [
	"A renamed tag leaves the old name in the comment, where it sends a reader to a tag that is not
	 there. This test fails on the rename rather than on the reading."

	self tagNamesNamedByThePackageComment do: [ :each |
		self
			assert: (self tagNamesOfThePackage includes: each)
			description: 'The package comment names ' , each , ', which is no tag of the package' ]
]

{ #category : 'tests - package comment' }
VectorGraphicsDocumentationTest >> testTheTagListIsReadOnlyUnderItsHeadingAndStopsAtTheEndOfTheList [
	"The degenerate states of the reader itself: a comment with no heading names no tag, a list
	 before the heading is not the tag list, and the list stops where it stops, so prose written
	 after it is not read as a tag."

	| comment |
	self assert: (self tagNamesNamedBy: '') isEmpty.
	self assert: (self tagNamesNamedBy: '- `Kernel` — a list with no heading above it') isEmpty.
	comment := String cr join: #( '- `NotATag` — this list comes first' '' 'Tags:' ''
			              '- `Kernel` — the engine' '- `Tests` — the suites' ''
			              'Prose after the list, naming `Examples`, which is not read.' ).
	self
		assert: (self tagNamesNamedBy: comment)
		equals: (Set withAll: #( 'Kernel' 'Tests' ))
]
