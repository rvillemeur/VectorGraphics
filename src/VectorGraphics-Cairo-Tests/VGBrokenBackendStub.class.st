"
I am a backend that cannot draw: every frame recorded on me raises VGBackendFailure at the first shape.

I stand for the broken GPU, which is the case the failover exists for: a present library with no working driver behind it. I count the shapes handed to me before I raise, so a test can prove that the fallback replayed the whole display list and not the part that was left. I write no pixel, ever, which is the contract VGBackend >> drainInto: states for every backend that raises.
"
Class {
	#name : 'VGBrokenBackendStub',
	#superclass : 'VGBackend',
	#instVars : [
		'recorded'
	],
	#category : 'VectorGraphics-Cairo-Tests-Fixtures',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Fixtures'
}

{ #category : 'drawing' }
VGBrokenBackendStub >> blitSurface: aSurface at: aPoint paint: aPaint clip: aRectangle operator: aSymbol [
	recorded := recorded + 1.
	VGBackendFailure signalFor: self because: 'this backend draws nothing on purpose'
]

{ #category : 'drawing' }
VGBrokenBackendStub >> drainInto: aTarget [
	"Nothing was recorded, because recording raises, so there is nothing to draw and no pixel of
	 the target is touched."

	^ self
]

{ #category : 'drawing' }
VGBrokenBackendStub >> fillSegments: aSegments paint: aPaint clip: aRectangle operator: aSymbol [
	recorded := recorded + 1.
	VGBackendFailure signalFor: self because: 'this backend draws nothing on purpose'
]

{ #category : 'initialization' }
VGBrokenBackendStub >> initialize [
	super initialize.
	recorded := 0
]

{ #category : 'accessing' }
VGBrokenBackendStub >> recorded [
	"How many shapes were handed to me before I raised. A fallback that replays the whole display
	 list hands me the first shape and no more, because the first one raises."

	^ recorded
]
