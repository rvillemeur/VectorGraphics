"
I am raised by a backend that cannot draw what it was handed.
I carry the backend that raised me, because the recovery rejects the backend by class and has to
know which one failed; the frame itself is not mine to carry, since whoever catches me still holds
the display list that produced it.
A backend may raise me while a frame is recorded or while it is drained, but never between its
first pixel and its last: a frame half drawn cannot be mended by replaying it elsewhere.
VGCairoImageSurface >> flush is the only place that catches me.
"
Class {
	#name : 'VGBackendFailure',
	#superclass : 'Error',
	#instVars : [
		'backend'
	],
	#category : 'VectorGraphics-Cairo-Backend',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Backend'
}

{ #category : 'signalling' }
VGBackendFailure class >> signalFor: aBackend because: aString [
	"Raise a failure of that backend, with the reason it gives. The instance is built before it is
	 signalled, because a cascade on `self new` would send the signal to me and not to the
	 failure."

	| failure |
	failure := self new.
	failure backend: aBackend.
	^ failure signal: aString
]

{ #category : 'accessing' }
VGBackendFailure >> backend [
	"The backend that could not draw. It is answered as the instance and not as its class, so a
	 handler can ask it what it tried before rejecting its whole class."

	^ backend
]

{ #category : 'accessing' }
VGBackendFailure >> backend: aBackend [
	backend := aBackend
]
