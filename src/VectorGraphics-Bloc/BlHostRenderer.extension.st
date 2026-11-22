Extension { #name : 'BlHostRenderer' }

{ #category : '*vectorgraphics-bloc' }
BlHostRenderer class >> measureTextDuring: aBlock [
	"Extension on BlHostRenderer class, in this package because a profile here has to ask a
	 renderer class to pose whatever its own text measuring needs, and Bloc has no such hook.
	 A renderer that does not care which faces it measures with evaluates the block as it is."

	^ aBlock value
]

{ #category : '*vectorgraphics-bloc' }
BlHostRenderer class >> measuresTextWithFacesOfThisProject [
	"Extension on BlHostRenderer class, in this package because a profile here asks a renderer
	 class which faces its own text measuring reads, and Bloc has no such question. A renderer
	 that knows nothing of this project reads the faces upstream builds."

	^ false
]
