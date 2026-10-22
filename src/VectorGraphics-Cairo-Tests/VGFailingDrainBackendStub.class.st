"
I am a backend that records a frame and then fails to draw it: drainInto: raises VGBackendFailure before it writes a pixel.

I stand for the dispatch that fails at the end rather than at the start — a device lost, a queue submission refused, a readback that never arrives — which is where a GPU backend really breaks. I subclass the software backend so that recording works exactly as it does there, and I override drainInto: alone. The pixel I must not write is the point: a backend that raises after writing leaves a frame half drawn and no fallback can mend it, so the contract is that the raise comes first.
"
Class {
	#name : 'VGFailingDrainBackendStub',
	#superclass : 'VGSoftwareBackend',
	#instVars : [
		'drainAttempts'
	],
	#category : 'VectorGraphics-Cairo-Tests-Fixtures',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Fixtures'
}

{ #category : 'selection' }
VGFailingDrainBackendStub class >> isCandidate [
	"I inherit from the software backend to record a frame the way it does, but I am a fixture:
	 selection must never choose me, and a test forces me instead."

	^ false
]

{ #category : 'accessing' }
VGFailingDrainBackendStub >> drainAttempts [
	"How many times a frame recorded on me was asked to draw itself. One is all a surface may
	 try, because the second attempt goes to the software backend."

	^ drainAttempts
]

{ #category : 'drawing' }
VGFailingDrainBackendStub >> drainInto: aTarget [
	"The raise comes before the first pixel, which is what VGBackend >> drainInto: asks of a
	 backend that can fail: a frame half drawn cannot be mended by a fallback."

	drainAttempts := drainAttempts + 1.
	VGBackendFailure signalFor: self because: 'this backend fails when the frame is drained'
]

{ #category : 'initialization' }
VGFailingDrainBackendStub >> initialize [
	super initialize.
	drainAttempts := 0
]
