"
I am an entry that counts how often it is asked whether it covers a rectangle whole.
I exist for one test: a binning asks a super tile before it asks the sixteen tiles inside it, and
the only way to see that it asked once rather than sixteen times is to count the questions. I
answer one bounding box and yes to every rectangle, so a binning of me marks every tile it
touches interior. See VGTileBinningTest.
"
Class {
	#name : 'VGCountingCoverageEntryStub',
	#superclass : 'VGDisplayListEntry',
	#instVars : [
		'box',
		'coverageQuestions'
	],
	#category : 'VectorGraphics-Vulkan-Tests-Fixtures',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Fixtures'
}

{ #category : 'instance creation' }
VGCountingCoverageEntryStub class >> coveringEverythingOf: aRectangle [
	"An entry whose box is that rectangle and which covers whatever it is asked about."
	^ self new setBox: aRectangle
]

{ #category : 'draining' }
VGCountingCoverageEntryStub >> boundingBox [
	^ box
]

{ #category : 'accessing' }
VGCountingCoverageEntryStub >> coverageQuestions [
	"How often I have been asked whether I cover a rectangle whole."
	^ coverageQuestions
]

{ #category : 'testing' }
VGCountingCoverageEntryStub >> coversEveryPixelOf: aRectangle [
	coverageQuestions := coverageQuestions + 1.
	^ true
]

{ #category : 'initialization' }
VGCountingCoverageEntryStub >> setBox: aRectangle [
	box := aRectangle.
	coverageQuestions := 0
]
