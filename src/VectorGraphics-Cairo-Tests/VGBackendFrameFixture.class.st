"
I am the one frame the backend tests draw.
Two shapes rather than one, so that a fallback replaying the whole display list can be told from a
fallback replaying what was left of it, and an extent big enough that a fill covers many pixels and
small enough that two frames are compared in no time.
`drawnBy:` answers the frame as a Form, which is how two backends are held against each other pixel
for pixel. I live here rather than in either test class because the backend tests of this package
and of the Vulkan package draw the same frame, and a picture compared against another picture has to
be the same picture.
"
Class {
	#name : 'VGBackendFrameFixture',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Tests-Fixtures',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Fixtures'
}

{ #category : 'drawing' }
VGBackendFrameFixture >> drawOn: aSurface [
	"Two shapes rather than one, so that a fallback replaying the whole display list can be told
	 from a fallback replaying what was left of it."

	| context |
	context := aSurface newContext.
	context
		sourceColorR: 1.0 g: 0.0 b: 0.0;
		rectangleX: 2 y: 2 width: 10 height: 10;
		fill.
	context
		sourceColorR: 0.0 g: 0.0 b: 1.0;
		rectangleX: 20 y: 12 width: 12 height: 9;
		fill.
	^ context
]

{ #category : 'drawing' }
VGBackendFrameFixture >> drawnBy: aBackend [
	"My frame on a fresh surface through that backend, answered as a Form, so that two backends
	 can be compared pixel for pixel."

	| surface |
	surface := VGCairoImageSurface extent: self extent.
	surface backend: aBackend.
	self drawOn: surface.
	surface flush.
	^ surface asForm
]

{ #category : 'accessing' }
VGBackendFrameFixture >> extent [
	"Big enough that a fill covers many pixels and small enough that two frames are compared in
	 no time."

	^ 40 @ 30
]
