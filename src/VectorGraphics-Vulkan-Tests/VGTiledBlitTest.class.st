"
I am the gate of unit 2.6: a blit, which is Cairo cairo_mask_surface, drawn by the tiled rasteriser and by the device. A blit carries a mask surface and not a path, so its coverage is the coverage of its own clip scaled by the alpha of the mask, and what I hold is that the three ways of drawing one - the software backend, the buffers of an encoding and the device - agree byte for byte. A glyph reaches the backend as a blit, which is what makes this the unlock the profiled frame waits on.
"
Class {
	#name : 'VGTiledBlitTest',
	#superclass : 'VGTiledFrameTestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'constants' }
VGTiledBlitTest class >> blitCaseCount [
	"The cases of the conformance corpus that record a blit and that the subset draws: the two
	 ways a group is masked, the glyph run, and the four shadows, which are a blurred mask blitted
	 through a colour. The number is asserted wherever the corpus is walked, so a capability lost
	 by a later change cannot pass as a case quietly skipped."

	^ 7
]

{ #category : 'fixtures' }
VGTiledBlitTest >> blitCasesDo: aBlock [
	"Every case the subset draws that records a blit, with the block that draws it. The count is
	 asserted here, so that a subset quietly narrowed by a later change fails in every test that
	 walks the corpus."

	| drawn |
	drawn := 0.
	self supportedCasesDo: [ :case :draw :entries |
		(entries anySatisfy: [ :each | each isKindOf: VGBlitEntry ]) ifTrue: [
			drawn := drawn + 1.
			aBlock value: case value: draw ] ].
	self assert: drawn equals: self class blitCaseCount
]

{ #category : 'fixtures' }
VGTiledBlitTest >> blitEntryOfFrame: aBlock [
	"The one blit the frame that block draws records, read before anything drains it."

	^ (self displayListOfExtent: self caseExtent drawnWith: aBlock) entries
		  detect: [ :each | each isKindOf: VGBlitEntry ]
]

{ #category : 'fixtures' }
VGTiledBlitTest >> blitFrameNames [
	"Every frame of my own, by the name of the method that answers it, so that a test holds all
	 of them and a frame added here is gated without the test being edited."

	^ #( #maskedFrame #maskedFrameOffTheCorner #maskedFrameInAFractionalClip
	     #maskedFrameOutsideItsClip #maskedFrameUnderSourceAndClear )
]

{ #category : 'fixtures' }
VGTiledBlitTest >> maskTileOfExtent: anExtent [
	"A mask surface carrying all three alphas a mask can carry: transparent at the top, half
	 opaque over a band and opaque under a disc, so that a blit through it proves more than a
	 copy of one byte. It is the mask tile of the conformance corpus at a size of my choosing."

	| tile context |
	tile := VGCairoImageSurface extent: anExtent.
	context := tile newContext.
	context clearTransparent.
	context sourceColorR: 1.0 g: 1.0 b: 1.0 a: 0.5.
	context rectangleX: 0 y: anExtent y / 2 width: anExtent x height: anExtent y / 2.
	context fill.
	context sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
	context
		circleCenterX: anExtent x / 2
		y: anExtent y / 2
		radius: anExtent x / 4.
	context fill.
	tile flush.
	^ tile
]

{ #category : 'fixtures' }
VGTiledBlitTest >> maskedFrame [
	"One blit of a small mask at an offset, which is the shape a glyph arrives in: the mask is
	 recorded through the very message the glyph path sends, because the facade renders every
	 other mask into an intermediate of the target size first and a mask that covers the whole
	 target would never exercise an offset."

	^ [ :context |
	  context sourceColorR: 0.2 g: 0.4 b: 0.9 a: 1.0.
	  context recordBlitOf: (self maskTileOfExtent: 21 @ 18) at: 7 @ 5 ]
]

{ #category : 'fixtures' }
VGTiledBlitTest >> maskedFrameInAFractionalClip [
	"A blit through a clip whose sides fall between pixels. A mask carries no spans, so Cairo
	 shades the rim of the clip into the mask byte instead of meeting it span by span, which is
	 the one thing a blit does that a fill does not; a clip of whole pixels would not exercise
	 it."

	^ [ :context |
	  context
		  rectangleX: 10.25 y: 8.5 width: 18.5 height: 15.75;
		  clip;
		  sourceColorR: 0.1 g: 0.6 b: 0.4 a: 1.0.
	  context recordBlitOf: (self maskTileOfExtent: 30 @ 26) at: 6 @ 4 ]
]

{ #category : 'fixtures' }
VGTiledBlitTest >> maskedFrameOffTheCorner [
	"A blit whose mask hangs off the top left of the frame. The rectangle the clip narrows to
	 then starts at the frame and not at the mask, so a reader that indexes the bytes of the mask
	 from its own origin reads the wrong byte of every row."

	^ [ :context |
	  context sourceColorR: 0.9 g: 0.2 b: 0.3 a: 0.75.
	  context recordBlitOf: (self maskTileOfExtent: 24 @ 20) at: -9 @ -7 ]
]

{ #category : 'fixtures' }
VGTiledBlitTest >> maskedFrameOutsideItsClip [
	"A blit whose mask and clip do not meet at all, which writes no pixel. The rectangle the clip
	 narrows to is empty, so the run of bytes it owns is empty too, and nothing may read a byte
	 of it or allocate a buffer from a negative count."

	^ [ :context |
	  context
		  rectangleX: 40 y: 40 width: 20 height: 20;
		  clip;
		  sourceColorR: 0.1 g: 0.6 b: 0.4 a: 1.0.
	  context recordBlitOf: (self maskTileOfExtent: 12 @ 12) at: 2 @ 2 ]
]

{ #category : 'fixtures' }
VGTiledBlitTest >> maskedFrameUnderSourceAndClear [
	"Two blits over a fill under the other two operators of the subset. Both write the
	 destination where the mask covers nothing - source lays the paint down and clear takes the
	 destination away - and both leave it alone where the mask is zero, because a mask byte of
	 zero weighs the source by nothing under either of them."

	^ [ :context |
	  context
		  sourceColorR: 0.1 g: 0.7 b: 0.2 a: 1.0;
		  rectangleX: 4 y: 4 width: 56 height: 56;
		  fill;
		  setOperatorSource;
		  sourceColorR: 0.9 g: 0.4 b: 0.0 a: 0.6.
	  context recordBlitOf: (self maskTileOfExtent: 22 @ 22) at: 6 @ 6.
	  context setOperatorClear.
	  context recordBlitOf: (self maskTileOfExtent: 18 @ 24) at: 33 @ 29 ]
]

{ #category : 'tests' }
VGTiledBlitTest >> testABlitDecodesToTheFillItIsDrawnAs [
	"One entry out of the buffers and nothing else, which is what lets a test hold the layout
	 before a kernel exists. A blit decodes to the masked fill it is drawn as: the same path, the
	 same narrowed clip, the same operator and the same mask byte at every pixel of its
	 rectangle."

	| encoding decoded fill |
	fill := (self blitEntryOfFrame: self maskedFrame) asTiledFill.
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self maskedFrame.
	decoded := encoding entryAt: 1.
	self assert: decoded class equals: VGMaskedFillEntry.
	self
		assert: decoded segments coordinates
		equals: fill segments coordinates.
	self assert: decoded clip bounds equals: fill clip bounds.
	self assert: decoded operator equals: fill operator.
	self
		assert: decoded tiledMaskRectangle
		equals: fill tiledMaskRectangle.
	self assert: decoded tiledMaskBytes equals: fill tiledMaskBytes
]

{ #category : 'tests' }
VGTiledBlitTest >> testABlitDrawsTheSameBytesAsTheSoftwareBackend [
	"The gate of this step on one frame of my own, before the corpus. The alpha of the mask
	 stands where the coverage of a fill stands, scaled by the coverage of the clip, and the two
	 paths that draw a blit have to agree byte for byte. The mask carries three alphas, so
	 agreeing on one byte is not enough to pass."

	self
		assert: (self tiledFormOfExtent: self caseExtent drawnWith: self maskedFrame) bits
		equals:
		(self softwareFormOfExtent: self caseExtent drawnWith: self maskedFrame) bits
]

{ #category : 'tests' }
VGTiledBlitTest >> testABlitInAShapedClipIsDrawnAndNotRefused [
	"The refusal a blit of the profiled frame used to meet: every glyph of it is clipped to the
	 rounded rectangle of its card. Unit 2.6 owed that the reason named was the clip and not the
	 kind; unit 2.7 draws the clip, so the entry is refused for nothing at all and the census
	 names no reason but the supported one."

	| entry census |
	entry := self blitEntryOfFrame: [ :context |
		         context
			         roundedRectangleLeft: 4
			         top: 4
			         right: 60
			         bottom: 60
			         tl: 8
			         tr: 8
			         br: 8
			         bl: 8;
			         clip;
			         sourceColorR: 0.2 g: 0.4 b: 0.9 a: 1.0.
		         context recordBlitOf: (self maskTileOfExtent: 21 @ 18) at: 7 @ 5 ].
	census := VGTiledFillSupportCensus of: { entry } named: 'one shaped blit'.
	self deny: entry clip isRectangular.
	self assert: (VGTiledFillRasteriser supportsKindOf: entry).
	self assert: (VGTiledFillRasteriser supportsEntry: entry).
	self
		assert: (census reasonFor: entry)
		equals: VGTiledFillSupportCensus supportedReason
]

{ #category : 'tests' }
VGTiledBlitTest >> testAnEncodedBlitCarriesItsRectangleAndTheAlphaOfEveryPixelOfItsMask [
	"What the mask buffers hold of one blit: the rectangle its clip narrows to, and the alpha of
	 every pixel of that rectangle in the order the rows run. The entry answers both already -
	 the rasteriser draws from them - so the gate is that the buffers carry what the entry
	 carries and nothing is lost on the way."

	| encoding fill |
	fill := (self blitEntryOfFrame: self maskedFrame) asTiledFill.
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self maskedFrame.
	self assert: encoding entryCount equals: 1.
	self
		assert: (encoding decoder maskRectangleOfEntryAt: 1)
		equals: fill tiledMaskRectangle.
	self
		assert: (encoding decoder maskBytesOfEntryAt: 1)
		equals: fill tiledMaskBytes
]

{ #category : 'tests' }
VGTiledBlitTest >> testAnEncodedFillCarriesAnEmptyMaskRectangleAndNoBytesAtAll [
	"A fill is encoded beside a blit and has no mask. An empty rectangle is what says so, and it
	 is all that has to say so: the kernel answers full alpha at every pixel outside the
	 rectangle of an entry, and scaling a byte by full alpha leaves it as it was, so a fill needs
	 no mark of its own and the kernel needs no branch on the kind of an entry."

	| encoding |
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self maskedFrameUnderSourceAndClear.
	self assert: encoding entryCount equals: 3.
	self
		assert: (encoding decoder maskRectangleOfEntryAt: 1)
		equals: VGTiledFillLayout emptyMaskRectangle.
	self assert: (encoding decoder maskBytesOfEntryAt: 1) isEmpty.
	self
		deny: (encoding decoder maskRectangleOfEntryAt: 2)
		equals: VGTiledFillLayout emptyMaskRectangle
]

{ #category : 'tests - subset' }
VGTiledBlitTest >> testAnEntryOfNeitherKindIsRefusedForItsKindAndNamedSo [
	"A display list holds a fill and a blit today and the subset now holds both, so the clause
	 that asks the kind can only fire for a kind nobody has written yet. It stays, and is
	 tested, because a third kind of entry owes a refusal and not a walk over edges it does not
	 have."

	| entry census |
	entry := VGDisplayListEntry new
		         setPaint: (VGColorPaint color: Color blue)
		         clip: (VGClip bounds: (0 @ 0 corner: self caseExtent))
		         operator: VGCairoOperator over.
	census := VGTiledFillSupportCensus of: { entry } named: 'one entry of no kind'.
	self deny: (VGTiledFillRasteriser supportsKindOf: entry).
	self deny: (VGTiledFillRasteriser supportsEntry: entry).
	self assert: (census reasonFor: entry) equals: #notAFillOrABlit.
	self assert:
		(VGTiledFillSupportCensus refusalReasons includes: #notAFillOrABlit)
]

{ #category : 'tests' }
VGTiledBlitTest >> testEveryBlitCaseOfTheCorpusDrawsOnTheDeviceWhatTheSoftwareBackendDraws [
	"The gate of unit 2.6 over the corpus: every case the subset draws that records a blit, drawn
	 on the device and by the software backend on the same frame, holds to the tolerance the fill
	 cases set. A glyph run is such a case, which is the half of the stated gate the corpus can
	 answer; the surface patterns of the corpus are refused for their paint and wait on unit 2.9.
	 One context draws all of them. A machine with no device holds nothing."

	| context |
	context := [ VkContext computeContext ]
		           on: Error
		           do: [ :failure | nil ].
	context ifNil: [ ^ self ].
	[ self blitCasesDo: [ :case :draw |
		  self assertDeviceDrawsCase: case with: draw on: context ] ]
		ensure: [ context destroy ]
]

{ #category : 'tests' }
VGTiledBlitTest >> testEveryBlitCaseOfTheCorpusDrawsTheSameBytesAsTheSoftwareBackend [
	"The gate of this unit on the corpus. The oracle is the software backend and not Cairo: that
	 backend already held against Cairo on all forty-one cases in phase one, at the tolerances
	 phase 1 set for a glyph run, so matching it is both necessary and sufficient here."

	self blitCasesDo: [ :case :draw |
		self
			assert: (self tiledFormOfExtent: case extent drawnWith: draw) bits
				    = (self softwareFormOfExtent: case extent drawnWith: draw) bits
			description: case name ]
]

{ #category : 'tests' }
VGTiledBlitTest >> testEveryBlitCaseOfTheCorpusDrawsTheSameBytesFromTheBuffersAsFromItsOwnEntries [
	"The same gate over the seven cases of the corpus that record a blit."

	self blitCasesDo: [ :case :draw |
		self
			assert: (self encodedFormOfExtent: case extent drawnWith: draw) bits
				    = (self singleFloatFormOfExtent: case extent drawnWith: draw) bits
			description: case name ]
]

{ #category : 'tests' }
VGTiledBlitTest >> testEveryFrameOfMineDrawsOnTheDeviceWhatTheSoftwareBackendDraws [
	"The same gate over the frames of my own, which is where the degenerate masks are: one that
	 hangs off the corner of the frame, one in a clip whose sides fall between pixels, one that
	 does not meet its clip at all, and the other two operators of the subset. A mask rides to
	 the device as four floats and a byte a pixel, and a frame with no blit in it ships an empty
	 mask buffer, so these are the cases that say whether the kernel reads a byte where there is
	 one and full alpha where there is none."

	| context |
	context := [ VkContext computeContext ]
		           on: Error
		           do: [ :failure | nil ].
	context ifNil: [ ^ self ].
	[ self blitFrameNames do: [ :name |
		  | draw comparison |
		  draw := self perform: name.
		  comparison := VGFormComparison
			                between: (self
					                 deviceFormOfExtent: self caseExtent
					                 drawnWith: draw
					                 on: context)
			                and: (self
					                 softwareFormOfExtent: self caseExtent
					                 drawnWith: draw).
		  self
			  assert:
			  (comparison pixelsFartherThan: self class deviceChannelTolerance) = 0
			  description: name.
		  self
			  assert: comparison differingPixelCount
				      <= self class devicePixelsAllowedToDifferPerCase
			  description: name ] ] ensure: [ context destroy ]
]

{ #category : 'tests' }
VGTiledBlitTest >> testEveryFrameOfMineDrawsTheSameBytesAsTheSoftwareBackend [
	"The same gate as the first frame, over the frames that are not the plain case: a mask that
	 hangs off the corner of the frame, a clip whose sides fall between pixels, a mask that does
	 not meet its clip at all, and the other two operators of the subset."

	self blitFrameNames do: [ :name |
		| draw |
		draw := self perform: name.
		self
			assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
				    = (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
			description: name ]
]

{ #category : 'tests' }
VGTiledBlitTest >> testEveryFrameOfMineDrawsTheSameBytesFromTheBuffersAsFromItsOwnEntries [
	"The gate of the encoding over my own frames. The oracle is the frame narrowed to single
	 floats, because that is what the buffers can hold; a mask rectangle is whole pixels and a
	 mask byte is a byte, so neither of those narrows and the two have to agree exactly."

	self blitFrameNames do: [ :name |
		| draw |
		draw := self perform: name.
		self
			assert: (self encodedFormOfExtent: self caseExtent drawnWith: draw) bits
				    = (self singleFloatFormOfExtent: self caseExtent drawnWith: draw)
					      bits
			description: name ]
]

{ #category : 'tests - subset' }
VGTiledBlitTest >> testTheSubsetHoldsABlitOfASolidColourInARectangularClip [
	"What this unit widens the subset by. A blit is a mask surface under a paint, a clip and an
	 operator, and the three clauses a fill answers are the three a blit answers; the kind is no
	 longer one of them."

	| entry |
	entry := self blitEntryOfFrame: self maskedFrame.
	self assert: (VGTiledFillRasteriser supportsKindOf: entry).
	self assert: (VGTiledFillRasteriser supportsEntry: entry).
	self assert:
		(VGTiledFillRasteriser supports:
			 (self displayListOfExtent: self caseExtent drawnWith: self maskedFrame))
]
