"
I am the host space of `VGPixelBufferHost`: I own a buffer of premultiplied ARGB32 pixels
and perform the frame handover a window performs, lending the buffer and the pitch of its
rows to the renderer.
After a frame my `pixels` hold what was drawn, so a space can be drawn without a window and
without a graphics library, and what it drew can be read back.

"
Class {
	#name : 'VGPixelBufferHostSpace',
	#superclass : 'BlHeadlessHostSpace',
	#instVars : [
		'pixels',
		'stride'
	],
	#category : 'VectorGraphics-Bloc-Hosts',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Hosts'
}

{ #category : 'accessing' }
VGPixelBufferHostSpace >> form [
	"The last frame drawn, as a form. A surface is built over the same bytes and only read, so
	 nothing of what was drawn is moved or changed to show it."

	^ (VGCairoImageSurface
		   unownedNewForData: self pixels
		   format: VGCairoSurfaceFormat argb32
		   width: self physicalSize asPoint x
		   height: self physicalSize asPoint y
		   stride: self stride) asForm
]

{ #category : 'inspector' }
VGPixelBufferHostSpace >> inspectorFrame: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Frame'>
	"The frame that was last drawn into the buffer this host space lends the renderer."

	^ aBuilder newImage image: self form
]

{ #category : 'inspector' }
VGPixelBufferHostSpace >> inspectorFrameContext: aContext [
	"A buffer is only allocated once a frame has been asked for, and a form over nothing would
	 raise rather than show an empty tab."

	aContext active: pixels notNil
]

{ #category : 'inspector' }
VGPixelBufferHostSpace >> inspectorHandover: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Handover'>
	"What this host space lends the renderer on every frame, and what the renderer made of it.
	 The number of bytes a row needs is asked of the format rather than restated, so a change in
	 the stride rule shows here."

	^ aBuilder newTable
		  items: {
				  ('Renderer' -> self renderer class).
				  ('Renderer is valid' -> self renderer isValid).
				  ('Physical size' -> self physicalSize asPoint).
				  ('Logical size' -> self logicalSize asPoint).
				  ('Stride' -> self stride).
				  ('Buffer allocated' -> pixels notNil).
				  ('Frames drawn' -> self renderCount) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGPixelBufferHostSpace >> inspectorHandoverContext: aContext [
	"The renderer is asked for its state, and a host space built but never given one has none."

	aContext active: self renderer notNil
]

{ #category : 'host space - rendering' }
VGPixelBufferHostSpace >> lockSurfaceFor: aDamagedRectangle scaleFactor: aNumber during: aBlock [
	"The handover a window performs on every frame, with a byte array in place of the texture of
	 the window. The whole surface is handed over rather than the damaged rectangle, because
	 nothing here has to be fast."

	self renderer
		renderWith: aBlock
		pixels: self pixels
		stride: self stride
		physicalRectangle: (0 @ 0 extent: self physicalSize asPoint)
		logicalRectangle: (0 @ 0 extent: self logicalSize asPoint)
]

{ #category : 'host space - displaying' }
VGPixelBufferHostSpace >> open [
	"A window host space initialises its renderer when the window is created, and
	 `BlSpace >> validateHostSpaceDrawing` does it again only once the window has resized. The
	 headless host space does neither, because it never draws, so the renderer would hold no
	 canvas and would answer that it is not valid."

	super open.
	self initializeRenderer
]

{ #category : 'accessing' }
VGPixelBufferHostSpace >> pixels [
	"The buffer the frames are drawn into, one row of `stride` bytes per physical row."

	^ pixels ifNil: [
		  pixels := ByteArray new: self stride * self physicalSize asPoint y ]
]

{ #category : 'host space - rendering' }
VGPixelBufferHostSpace >> render: aSpace [
	"The inherited method counts the frame and clears the dirty elements without drawing, so the
	 renderer is never asked for anything. A window host space asks its renderer; so do I."

	self renderer render: self.
	super render: aSpace
]

{ #category : 'accessing' }
VGPixelBufferHostSpace >> stride [
	"The pitch of a row, which a window gets from its texture and this one computes for the
	 format every host space hands over."

	^ stride ifNil: [
		  stride := VGCairoSurfaceFormat argb32 strideForWidth:
			            self physicalSize asPoint x ]
]
