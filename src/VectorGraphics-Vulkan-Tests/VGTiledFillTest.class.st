"
I hold the parity tests of the tiled fill rasteriser of unit 2.3, which draws a recorded frame tile
by tile and pixel by pixel the way the GPU kernel does.
The software backend is the oracle: a frame drawn through the tiles has to carry the same bytes as
the same frame drawn through the software backend, because the software backend is what phase 1
measured against live Cairo.
I compare whole Forms rather than coverage numbers, so a difference in the quantisation or in the
compositing fails here as readily as a difference in the geometry.
"
Class {
	#name : 'VGTiledFillTest',
	#superclass : 'VGTiledFrameTestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'constants' }
VGTiledFillTest class >> degenerateGradientFrameNames [
	"The two frames of the fixture that lay down nothing at all: a gradient with no stops and a
	 line of no length. They are drawn for the branch that answers nothing, so they are the two
	 frames a test of painted pixels has to leave out."

	^ #( #linearWithNoStops #linearOfNoLength )
]

{ #category : 'constants' }
VGTiledFillTest class >> fillCaseCount [
	"Counted over the corpus: thirty of the forty-one cases are fills the subset draws. Unit 2.3
	 drew twenty-two of them, fills of a solid colour inside a rectangular clip, unit 2.4 added
	 the two gradient cases, unit 2.7 added clip-circle by drawing a clip cut out by shapes, and
	 unit 2.9 added the five that fill through a surface paint. Of the eleven left, seven record a
	 blit and are gated by VGTiledBlitTest, and four carry a mesh paint, which no unit draws yet."

	^ 30
]

{ #category : 'constants' }
VGTiledFillTest class >> gradientFrameCount [
	"The frames VGGradientFrameFixture holds. Asserted wherever they are drawn, so that a frame
	 dropped from the fixture cannot quietly narrow the gate of unit 2.4."

	^ 15
]

{ #category : 'fixtures' }
VGTiledFillTest >> fillCasesDo: aBlock [
	"Every case the subset draws that records no blit, with the block that draws it. The count is
	 asserted here, so that a subset quietly narrowed by a later change fails in every test that
	 walks the corpus. A case that records a blit is gated by VGTiledBlitTest."

	| drawn |
	drawn := 0.
	self supportedCasesDo: [ :case :draw :entries |
		(entries anySatisfy: [ :each | each isKindOf: VGBlitEntry ]) ifFalse: [
			drawn := drawn + 1.
			aBlock value: case value: draw ] ].
	self assert: drawn equals: self class fillCaseCount
]

{ #category : 'running' }
VGTiledFillTest >> gradientFrames [
	"The gradient frames of the fixture, each as its name and the block that draws it. The count
	 is held in every test that reads them, so the fixture cannot shrink unnoticed."

	| frames |
	frames := VGGradientFrameFixture frames.
	self assert: frames size equals: self class gradientFrameCount.
	^ frames
]

{ #category : 'fixtures' }
VGTiledFillTest >> mixedFillFrame [
	"Four fills of the subset in one frame: an opaque rectangle, a fractional rectangular clip
	 and a translucent circle under the source operator, a paint through a constant alpha, which
	 that operator refuses to fold into the colour so that the alpha rides in the segments
	 instead, and a circle that clears part of what the others laid down."
	^ [ :context |
	  context
		  sourceColorR: 0.1 g: 0.7 b: 0.2 a: 1.0;
		  rectangleX: 5 y: 7 width: 44 height: 30;
		  fill;
		  rectangleX: 8.5 y: 12.25 width: 42 height: 36.75;
		  clip;
		  setOperatorSource;
		  sourceColorR: 0.9 g: 0.4 b: 0.0 a: 0.6;
		  circleCenterX: 26.5 y: 26.25 radius: 16.5;
		  fill;
		  paintWithAlpha: 0.35;
		  setOperatorClear;
		  circleCenterX: 42 y: 42 radius: 10.25;
		  fill ]
]

{ #category : 'private' }
VGTiledFillTest >> referenceOfTileAt: anIndex in: anEncoding [
	"The first reference word of that tile, its flag and its identifier together, which is the
	 word an invocation of the kernel reads."

	| base |
	base := (anEncoding rowOfTileAt: anIndex) - 1
	        * VGTiledFillLayout tileRecordWords.
	^ anEncoding entryRefs at:
		  (anEncoding tileTable
			   at: base + VGTiledFillLayout referenceOffsetField) + 1
]

{ #category : 'tests' }
VGTiledFillTest >> testAClippedFillDrawsTheSameBytesAsTheSoftwareBackend [
	"A rectangular clip on fractional coordinates. The clip is trimmed across on every sub-row
	 and down by whole rows, which is what the rasteriser does, and a clip is a geometric
	 intersection of spans and never a second coverage."

	| draw |
	draw := [ :context |
	         context
		         rectangleX: 8.5 y: 12.25 width: 30 height: 24.75;
		         clip;
		         sourceColorR: 0.3 g: 0.3 b: 0.9 a: 1.0;
		         circleCenterX: 24 y: 24 radius: 20;
		         fill ].
	self
		assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
		equals: (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
]

{ #category : 'tests' }
VGTiledFillTest >> testADecodedTileAnswersItsEntriesInTheOrderTheyWereDrawn [
	"Compositing is not commutative, so the references of a tile keep the order of the display
	 list. The four fills of this frame run under three different operators, which is what makes
	 the order visible."
	| list encoding binning |
	list := self displayListOfExtent: self caseExtent drawnWith: self mixedFillFrame.
	binning := VGTileBinning of: list extent: self caseExtent.
	encoding := VGTiledFillEncoding of: list extent: self caseExtent.
	binning touchedTileIndexes do: [ :index |
		self
			assert:
			((encoding entriesOfTileAt: index) collect: [ :each | each operator ])
				asArray
			equals:
			((binning entriesOfTileAt: index) collect: [ :each | each operator ])
				asArray ]
]

{ #category : 'tests' }
VGTiledFillTest >> testADispatchSendsOneBlockOfWordsForEveryBindingTheKernelReads [
	"What a dispatch uploads: one block for every binding the kernel declares, and every block
	 that an encoding answers is the encoding's own array and not a run of bytes packed from it.
	 The words of a WordArray and the floats of a Float32Array already lie in object memory in
	 the order and the width a storage buffer reads them, so a copy between the two would be a
	 copy of a frame for nothing. None of this needs a device, so it is held on every machine."

	| encoding target blocks dispatch |
	encoding := VGTiledFillEncoding
		            of: (self
				             displayListOfExtent: self caseExtent
				             drawnWith: self mixedFillFrame)
		            extent: self caseExtent.
	target := ByteArray new:
		          self caseExtent x * self caseExtent y
		          * VGTiledFillEncoding targetFormat bytesPerPixel.
	dispatch := VGTiledFillDispatch new.
	blocks := dispatch blocksOf: encoding target: target.
	self
		assert: blocks keys asSortedCollection asArray
		equals: VGTiledFillKernel bindingNames asSortedCollection asArray.
	(VGTiledFillKernel bindingNames
		 reject: [ :each | VGTiledFillDispatch bindingsNotOfAnEncoding includes: each ])
		do: [ :each |
			self
				assert: (blocks at: each)
				identicalTo: (encoding perform: each) ].
	self assert: (blocks at: #target) identicalTo: target.
	self
		assert: ((blocks at: #frame) at: VGTiledFillKernel frameWidthField)
		equals: self caseExtent x.
	self
		assert: ((blocks at: #frame) at: VGTiledFillKernel frameHeightField)
		equals: self caseExtent y.
	self
		assert: (dispatch byteCountOfBlock: (blocks at: #edges))
		equals: encoding edges size * VGTiledFillKernel elementStride
]

{ #category : 'tests' }
VGTiledFillTest >> testAFillBeyondTheSurfaceLeavesEverySurfacePixelAlone [
	"A shape wholly outside the clip, which is the surface itself here: no tile is touched, and a
	 pixel of a neighbouring tile is not written on its behalf."

	| draw |
	draw := [ :context |
	         context
		         rectangleX: 200 y: 200 width: 10 height: 10;
		         fill ].
	self
		assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
		equals: (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
]

{ #category : 'tests' }
VGTiledFillTest >> testAFrameNotReadBackAtOnceHasOnTheDeviceThePixelsAFrameReadBackHasInTheHost [
	"Asking for the pixels later is asking for the same pixels: the request decides when the
	 target buffer is copied into the host and nothing about what the device writes into it. So
	 the frame is drawn twice from the same zeroed target, once read back by the frame itself and
	 once read back afterwards, and the two runs of pixels are the same bytes."

	| encoding pixelCount dispatch atOnce later |
	self hasDevice ifFalse: [ ^ self ].
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self mixedFillFrame.
	pixelCount := self caseExtent x * self caseExtent y
	              * VGTiledFillEncoding targetFormat bytesPerPixel.
	atOnce := ByteArray new: pixelCount.
	later := ByteArray new: pixelCount.
	dispatch := VGVulkanDeviceSession default dispatchForEncoding: encoding.
	dispatch draw: encoding into: atOnce.
	dispatch draw: encoding into: later readBack: false.
	self assert: later equals: (ByteArray new: pixelCount).
	dispatch readbackInto: later.
	self assert: later equals: atOnce
]

{ #category : 'tests' }
VGTiledFillTest >> testAFrameThatIsNotAWholeNumberOfTilesDrawsOnTheDeviceWhatTheSoftwareBackendDraws [
	"A frame whose extent is not a multiple of the tile size leaves the tiles of its last column
	 and of its last row short, and the invocations of such a workgroup that fall past the frame
	 have no pixel of their own to draw. They run the entry loop and reach its barriers all the
	 same, because a barrier one invocation of a workgroup reaches and another does not is
	 undefined behaviour, and the records every invocation reads out of workgroup storage are
	 only there once those barriers have been passed. So this frame is what says the staging of
	 unit 3.2 is synchronised in control flow the whole workgroup runs."

	| draw extent comparison |
	self hasDevice ifFalse: [ ^ self ].
	extent := 70 @ 54.
	draw := [ :context |
	         context
		         sourceColorR: 0.2 g: 0.6 b: 0.9 a: 0.75;
		         circleCenterX: 35 y: 27 radius: 24;
		         fill ].
	comparison := VGFormComparison
		              between: (self deviceFormOfExtent: extent drawnWith: draw)
		              and: (self softwareFormOfExtent: extent drawnWith: draw).
	self
		assert: (comparison pixelsFartherThan: self class deviceChannelTolerance)
		equals: 0.
	self
		assert: comparison differingPixelCount
		    <= self class devicePixelsAllowedToDifferPerCase
]

{ #category : 'tests' }
VGTiledFillTest >> testAFrameThatIsNotReadBackPaysNoReadbackAndLeavesTheTargetAlone [
	"The readback is a request and not a step of every frame. A frame whose pixels the host will
	 read asks for them; a frame that ends on the device does not, and then it pays no readback
	 at all and the array it was given is as it was. A dispatch of its own is used, so that the
	 session's dispatch is not left reading the clock for every later frame."

	| encoding target dispatch |
	self hasDevice ifFalse: [ ^ self ].
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self mixedFillFrame.
	target := ByteArray new:
		          self caseExtent x * self caseExtent y
		          * VGTiledFillEncoding targetFormat bytesPerPixel.
	dispatch := (VGTiledFillDispatch on: VGVulkanDeviceSession default context)
		            recordStages.
	[
	dispatch draw: encoding into: target readBack: false.
	self assert: (dispatch stageMicroseconds includesKey: #dispatch).
	self deny: (dispatch stageMicroseconds includesKey: #readback).
	self assert: target equals: (ByteArray new: target size) ] ensure: [
		dispatch releaseDevice ]
]

{ #category : 'tests' }
VGTiledFillTest >> testAFrameThatTouchesNoTileIsDispatchedOnNoDeviceAtAll [
	"A fill wholly beyond the surface is binned into no tile, so there is no workgroup to
	 dispatch and no pixel to write. The dispatch answers the pixels it was given as they were,
	 and asks nothing of a device to do it."

	| encoding target dispatch |
	encoding := VGTiledFillEncoding
		            of: (self
				             displayListOfExtent: self caseExtent
				             drawnWith: [ :context |
					             context
						             rectangleX: self caseExtent x + 10
						             y: self caseExtent y + 10
						             width: 10
						             height: 10;
						             fill ])
		            extent: self caseExtent.
	target := ByteArray new:
		          self caseExtent x * self caseExtent y
		          * VGTiledFillEncoding targetFormat bytesPerPixel.
	dispatch := VGTiledFillDispatch new.
	self assert: encoding touchedTileCount equals: 0.
	self assert: (dispatch draw: encoding into: target) identicalTo: target.
	self assert: (target allSatisfy: [ :each | each = 0 ]).
	self assert: dispatch blocks notNil
]

{ #category : 'tests' }
VGTiledFillTest >> testAReferenceCarriesItsIdentifierUnchangedWhetherItIsMarkedOrNot [
	"The flag rides in the top bit of the reference, so the identifier has to read back the same
	 with the flag set and clear. A frame of two thousand million entries would reach that bit,
	 and an encoding of one would not fit in memory."

	| identifier marked plain |
	identifier := 12345.
	marked := VGTiledFillLayout referenceFor: identifier interior: true.
	plain := VGTiledFillLayout referenceFor: identifier interior: false.
	self assert: (VGTiledFillLayout isInteriorReference: marked).
	self deny: (VGTiledFillLayout isInteriorReference: plain).
	self
		assert: (VGTiledFillLayout identifierOfReference: marked)
		equals: identifier.
	self
		assert: (VGTiledFillLayout identifierOfReference: plain)
		equals: identifier.
	self assert: plain equals: identifier
]

{ #category : 'tests' }
VGTiledFillTest >> testATileRecordNamesEveryTileTheFrameTouchesAndItsOwnEntries [
	"The record is what a workgroup reads first: which tile it owns, where that tile starts in
	 pixels, and the window of entry references inside it. The tiles and the counts are the
	 binning's own."
	| list encoding binning |
	list := self displayListOfExtent: self caseExtent drawnWith: self mixedFillFrame.
	binning := VGTileBinning of: list extent: self caseExtent.
	encoding := VGTiledFillEncoding of: list extent: self caseExtent.
	self
		assert: encoding touchedTileIndexes asSortedCollection asArray
		equals: binning touchedTileIndexes asSortedCollection asArray.
	binning touchedTileIndexes do: [ :index |
		self
			assert: (encoding entriesOfTileAt: index) size
			equals: (binning entriesOfTileAt: index) size ].
	self assert: encoding grid tileCount equals: binning grid tileCount
]

{ #category : 'tests' }
VGTiledFillTest >> testATranslucentCircleDrawsTheSameBytesAsTheSoftwareBackend [
	"Antialiasing and a translucent paint at once: the coverage of every edge pixel has to be the
	 same float as the rasteriser's, because a quantised byte would hide a small difference and
	 the alpha of the paint then scales it again."

	| draw |
	draw := [ :context |
	         context
		         sourceColorR: 0.2 g: 0.4 b: 0.9 a: 0.6;
		         circleCenterX: 32 y: 32 radius: 20;
		         fill ].
	self
		assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
		equals: (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
]

{ #category : 'tests' }
VGTiledFillTest >> testAWindingStarDrawsTheSameBytesAsTheSoftwareBackend [
	"The same path under the other rule, where the middle is filled: the walk adds the direction
	 each edge runs in."

	| draw |
	draw := [ :context |
	         context fillRule: #winding.
	         VGConformanceCorpus appendFivePointedStarTo: context.
	         context fill ].
	self
		assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
		equals: (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
]

{ #category : 'tests' }
VGTiledFillTest >> testAnAliasedCircleDrawsTheSameBytesAsTheSoftwareBackend [
	"Antialiasing off is one sample at the centre of the pixel row, and the picture is whole
	 pixels. The circle is placed on half coordinates, so a wrong half-open end would show."

	| draw |
	draw := [ :context |
	         context
		         antialias: #none;
		         circleCenterX: 32.5 y: 31.5 radius: 18.25;
		         fill ].
	self
		assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
		equals: (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
]

{ #category : 'tests' }
VGTiledFillTest >> testAnAxisAlignedRectangleDrawsTheSameBytesAsTheSoftwareBackend [
	"The simplest fill there is: whole pixels, one entry, source over an empty surface."

	| draw |
	draw := [ :context |
	         context
		         rectangleX: 8 y: 8 width: 48 height: 24;
		         fill ].
	self
		assert: (self tiledFormOfExtent: 64 @ 64 drawnWith: draw) bits
		equals: (self softwareFormOfExtent: 64 @ 64 drawnWith: draw) bits
]

{ #category : 'tests' }
VGTiledFillTest >> testAnEmptyFrameEncodesToEmptyBuffersAndDrawsNothing [
	"The degenerate frame: no entry, so no header, no edge, no tile record and no reference, and
	 a surface no pixel of which is read or written."
	| draw list encoding |
	draw := [ :context | context ].
	list := self displayListOfExtent: self caseExtent drawnWith: draw.
	encoding := VGTiledFillEncoding of: list extent: self caseExtent.
	self assert: encoding entryCount isZero.
	self assert: encoding edgeCount isZero.
	self assert: encoding headers isEmpty.
	self assert: encoding tileTable isEmpty.
	self assert: encoding entryRefs isEmpty.
	self assert: encoding touchedTileIndexes isEmpty.
	self
		assert: (self encodedFormOfExtent: self caseExtent drawnWith: draw) bits
		equals: (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
]

{ #category : 'tests' }
VGTiledFillTest >> testAnEmptyFrameLeavesEverySurfacePixelAlone [
	"A frame with no entry touches no tile, so nothing is drawn and nothing is read."

	| draw |
	draw := [ :context | context ].
	self
		assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
		equals: (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
]

{ #category : 'tests - encoding' }
VGTiledFillTest >> testAnEncodedEntryCarriesItsOwnPaintAndItsStops [
	"What the header and the two paint buffers hold of a fill: the tag of its paint, the sixteen
	 floats of its coefficient block as the paint itself holds them, and, for a gradient, every
	 stop as an offset and four unpremultiplied channels narrowed to single floats. A solid paint
	 carries no stop and keeps the source pixel unit 2.3 gave it, because one pixel is less for
	 the kernel to read than a block it would find the same colour in."

	| frames |
	frames := (self gradientFrames collect: [ :each | each value ])
		          copyWith: self mixedFillFrame.
	frames do: [ :draw |
		| list encoding |
		list := self displayListOfExtent: self caseExtent drawnWith: draw.
		encoding := VGTiledFillEncoding of: list extent: self caseExtent.
		list entries withIndexDo: [ :each :index |
			| decoded |
			decoded := encoding entryAt: index.
			self
				assert: decoded paint class paintTag
				equals: each paint class paintTag.
			each paint isSolid
				ifTrue: [ self deny: (decoded paint isKindOf: VGGradientPaint) ]
				ifFalse: [
					self
						assert: decoded paint coefficients asArray
						equals: each paint coefficients asArray.
					self
						assert: (decoded paint stops collect: [ :stop | stop key ])
						equals: (each paint stops collect: [ :stop |
								 self roundedToSingleFloat: stop key ]).
					self
						assert:
						(decoded paint stops collect: [ :stop | stop value asArray ])
						equals: (each paint stops collect: [ :stop |
								 (stop value collect: [ :channel |
									  self roundedToSingleFloat: channel ]) asArray ]) ] ] ]
]

{ #category : 'tests' }
VGTiledFillTest >> testAnEncodedEntryCarriesThePixelItsPaintAnswersAndItsOwnAlphaByte [
	"What a header holds of a fill: the premultiplied pixel, because the kernel carries a pixel
	 and not a paint, the operator, the fill rule, the antialiasing mode and the one alpha byte
	 the mask is scaled by. The alpha is kept as that byte, which the entry's own alpha answers
	 again, since the byte is all the mask ever asks for."
	| list encoding format |
	format := VGTiledFillEncoding targetFormat.
	list := self displayListOfExtent: self caseExtent drawnWith: self mixedFillFrame.
	encoding := VGTiledFillEncoding of: list extent: self caseExtent.
	list entries withIndexDo: [ :each :index |
		| decoded |
		decoded := encoding entryAt: index.
		self
			assert: (decoded paint pixelIn: format atX: 0 y: 0)
			equals: (each paint pixelIn: format atX: 0 y: 0).
		self
			assert: (format shortByteOf: decoded segments alpha)
			equals: (format shortByteOf: each segments alpha).
		self assert: decoded operator equals: each operator.
		self assert: decoded segments fillRule equals: each segments fillRule.
		self assert: decoded segments isAliased equals: each segments isAliased.
		self assert: decoded clip isRectangular ]
]

{ #category : 'tests' }
VGTiledFillTest >> testAnEvenOddStarDrawsTheSameBytesAsTheSoftwareBackend [
	"A self-intersecting path, where the even-odd rule leaves the middle empty: the walk counts
	 crossings rather than directions, and two edges can cross one point."

	| draw |
	draw := [ :context |
	         context fillRule: #evenOdd.
	         VGConformanceCorpus appendFivePointedStarTo: context.
	         context fill ].
	self
		assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
		equals: (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
]

{ #category : 'tests' }
VGTiledFillTest >> testAnOperatorAndAFillRuleAreNamedByCodeAndByValueBothWays [
	"A kernel branches on a small whole number, so each operator of the subset and each fill
	 rule carries a code of its own, and the code is read back as the value it stands for."
	| operators |
	operators := VGTiledFillRasteriser supportedOperators.
	operators do: [ :each |
		self
			assert: (VGTiledFillEncoding operatorAtCode:
					 (VGTiledFillEncoding codeForOperator: each))
			equals: each ].
	self
		assert: (operators collect: [ :each |
				 VGTiledFillEncoding codeForOperator: each ]) asSet size
		equals: operators size.
	VGTiledFillEncoding fillRuleNames do: [ :each |
		self
			assert: (VGTiledFillEncoding fillRuleAtCode:
					 (VGTiledFillEncoding codeForFillRule: each))
			equals: each ]
]

{ #category : 'tests' }
VGTiledFillTest >> testCoverageIsTheSameFloatAsTheRasteriserAnswersForEveryPixel [
	"The sorting-free walk against VGRasteriser pixel by pixel, compared as floats and not as
	 quantised bytes: the sums are the same terms in the same order, so they are equal exactly."

	| entry coverage rasteriser rows |
	entry := (self
		          displayListOfExtent: self caseExtent
		          drawnWith: [ :context |
			          context
				          circleCenterX: 31.75 y: 32.25 radius: 19.5;
				          fill ]) entries first.
	coverage := VGTileCoverage of: entry.
	rasteriser := VGRasteriser
		              segments: entry segments coordinates
		              fillRule: entry segments fillRule
		              antialias: entry segments antialias
		              clip: entry clip.
	rows := 0.
	rasteriser coverageRowsDo: [ :y :row :left |
		rows := rows + 1.
		1 to: row size do: [ :index |
			self
				assert: (coverage atX: left + index - 1 row: y)
				equals: (row at: index) ] ].
	self deny: rows isZero.
	self assert: (coverage atX: 32 row: self caseExtent y - 1) equals: 0.0
]

{ #category : 'tests - encoding' }
VGTiledFillTest >> testEveryBufferAnEncodingWritesIsFetchedOnceAndNotOncePerElement [
	"A buffer of VGTiledFillBuffers is held under the name the kernel binds it by, so fetching
	 one is a lookup in a dictionary and not a read of a slot. That is the right shape for the
	 set of buffers — a binding added to the contract adds a buffer and not a variable — and it
	 is the wrong thing to do a hundred thousand times a frame: measured on the reference frame,
	 the lookups inside the write loops were better than a third of the encoding. So an encoding
	 fetches a buffer at most once in a method and never inside a block, and a loop writes
	 through a temporary fetched before it. The accessors are read off VGTiledFillBuffers itself,
	 as the methods that answer one buffer by its literal name, so this test cannot miss a
	 buffer added later."

	| accessors inBlocks fetchedTwice |
	accessors := (VGTiledFillBuffers selectors select: [ :each |
		              | ast |
		              ast := (VGTiledFillBuffers >> each) ast.
		              ast sendNodes size = 1 and: [
			              ast sendNodes first selector = #bufferNamed: and: [
				              ast sendNodes first arguments first isLiteralNode ] ] ]) asSet.
	self deny: accessors isEmpty.
	inBlocks := OrderedCollection new.
	fetchedTwice := OrderedCollection new.
	VGTiledFillEncoding selectorsAndMethodsDo: [ :selector :method |
		| fetches |
		fetches := OrderedCollection new.
		method ast sendNodes do: [ :send |
			((accessors includes: send selector) and: [
				 send receiver isVariable and: [ send receiver name = 'buffers' ] ])
				ifTrue: [
					fetches add: send selector.
					(send allParents anySatisfy: [ :each | each isBlock ]) ifTrue: [
						inBlocks add: selector -> send selector ] ] ].
		fetches asSet size = fetches size ifFalse: [
			fetchedTwice add: selector -> fetches asArray ] ].
	self assertEmpty: inBlocks.
	self assertEmpty: fetchedTwice
]

{ #category : 'tests' }
VGTiledFillTest >> testEveryBufferOfAFrameHoldsTheWordsOfTheBlockItWasUploadedFrom [
	"The device is given the words of the encoding's own arrays, copied out of object memory in
	 one call of libc, so every buffer has to hold exactly what a run of bytes packed word by
	 word from that array would have held. Read back and compared here, because a copy at the
	 wrong width or in the wrong order would not fail: it would draw a frame whose every pixel is
	 wrong for a reason no pixel shows."

	| encoding target dispatch stride |
	self hasDevice ifFalse: [ ^ self ].
	stride := VGTiledFillKernel elementStride.
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self mixedFillFrame.
	target := ByteArray new:
		          self caseExtent x * self caseExtent y
		          * VGTiledFillEncoding targetFormat bytesPerPixel.
	dispatch := VGVulkanDeviceSession default dispatchForEncoding: encoding.
	dispatch draw: encoding into: target.
	(VGTiledFillKernel bindingNames
		 reject: [ :each | VGTiledFillDispatch bindingsNotOfAnEncoding includes: each ])
		do: [ :name |
			| block count read packed |
			block := dispatch blocks at: name.
			count := dispatch byteCountOfBlock: block.
			count > 0 ifTrue: [
				read := ByteArray new: count.
				(dispatch deviceBuffers at: name) readbackInto: read.
				packed := ByteArray new: count.
				1 to: block size do: [ :index |
					packed
						uint32AtOffset: index - 1 * stride
						put: (block basicAt: index) ].
				self assert: read equals: packed ] ]
]

{ #category : 'tests' }
VGTiledFillTest >> testEveryBufferTheKernelBindsOutOfAnEncodingIsOneTheBuffersAnswer [
	"The set holds one buffer a binding of the kernel that an encoding writes, and the encoding
	 answers each of them by the name the binding carries. A binding added to the contract and
	 not to the set would reach the device as nothing at all, and a buffer the set holds under a
	 name no binding carries would never be read."

	| buffers encoding names list |
	names := VGTiledFillKernel bindingNames reject: [ :each |
		         VGTiledFillDispatch bindingsNotOfAnEncoding includes: each ].
	buffers := VGTiledFillBuffers new.
	buffers allocateForEntries: 1 edges: 4 stops: 0 masks: 0.
	buffers allocateForShapes: 1.
	buffers allocateForPixels: 0.
	buffers allocateForTiles: 1 references: 1.
	list := self
		        displayListOfExtent: 64 @ 64
		        drawnWith: [ :context |
			        context
				        rectangleX: 8 y: 8 width: 48 height: 48;
				        fill ].
	encoding := VGTiledFillEncoding
		            of: list
		            grid: (VGTileGrid extent: 64 @ 64 tileExtent: 16 @ 16).
	names do: [ :name |
		self assert: (buffers respondsTo: name).
		self assert: (buffers perform: name) isNotNil.
		self assert: (encoding perform: name) isNotNil ].
	self
		assert: buffers bufferNames asSortedCollection asArray
		equals: names asSortedCollection asArray
]

{ #category : 'tests - bands' }
VGTiledFillTest >> testEveryEdgeThatCanCrossARowOfTilesIsInTheBandOfThatRowAndNoEdgeThatCannot [
	"The whole of the unit rests on this: an edge whose own rows miss the rows of a row of tiles
	 cannot cross a sub-row inside it, and so cannot wind a pixel of it. A band that dropped an
	 edge which does cross one of those rows would lose coverage, and a band holding an edge
	 whose rows miss it entirely would cost the kernel the reading and tell it nothing. The
	 first is asked of every edge that strictly crosses the rows and the second of every edge
	 the band holds."

	| list binning bands fills height |
	list := self
		        displayListOfExtent: self caseExtent
		        drawnWith: self mixedFillFrame.
	binning := VGTileBinning of: list extent: self caseExtent.
	fills := binning entries collect: [ :each | each asTiledFill ].
	bands := VGTiledFillBands binning: binning fills: fills.
	height := binning grid tileExtent y.
	fills withIndexDo: [ :fill :index |
		(bands rowsOfEntry: index) do: [ :row |
			| top bottom |
			top := row * height.
			bottom := top + height.
			(bands shapesOfEntry: index) withIndexDo: [ :shape :ordinal |
				| found |
				found := bands
					         edgeIndexesOfEntry: index
					         shape: ordinal
					         inRow: row.
				1 to: shape segments size by: VGTiledFillLayout edgeFloats do: [
					:offset |
					| box |
					box := shape edgeIndex boxOfEdgeAt: offset.
					(box top < bottom and: [ box bottom > top ]) ifTrue: [
						self assert: (found includes: offset) ] ].
				found do: [ :offset |
					| box |
					box := shape edgeIndex boxOfEdgeAt: offset.
					self assert: box top <= bottom.
					self assert: box bottom >= top ] ] ] ]
]

{ #category : 'tests - layout' }
VGTiledFillTest >> testEveryFieldOfARecordIsOneBasedWithinItsStrideAndNamedOnce [
	"A field is an index into one record of one buffer, so it has to fit inside that record and
	 mean one thing. A field past its own stride, or named in two records, would have the
	 encoding write one word and the kernel read another."

	| named |
	named := OrderedCollection new.
	VGTiledFillLayout recordFields keysAndValuesDo: [ :stride :fields |
		| words values |
		words := VGTiledFillLayout perform: stride.
		values := fields collect: [ :each | VGTiledFillLayout perform: each ].
		named addAll: fields.
		values do: [ :each |
			self assert: each >= 1.
			self assert: each <= words ].
		self
			assert: values asSet size = fields size
			description: 'two fields of ' , stride , ' share a number' ].
	self
		assert: named asSet size = named size
		description: 'a field is named in two records'.
	self
		assertCollection: named asSet
		hasSameElements:
			(VGTiledFillLayout class selectors select: [ :each | each endsWith: 'Field' ])
]

{ #category : 'tests - device' }
VGTiledFillTest >> testEveryFillCaseOfTheCorpusDrawsOnTheDeviceWhatTheSoftwareBackendDraws [
	"The gate of unit 2.3. Every case of the corpus the subset draws, drawn on the device and by
	 the software backend on the same frame and compared premultiplied: no pixel farther than the
	 tolerance in any channel, and at most the measured count of pixels differing at all.
	 One context draws all of them, and it is the session's: a device costs 37 to 52 ms to open
	 and a frame does not. A machine with no device has nothing to compare and holds nothing."

	self hasDevice ifFalse: [ ^ self ].
	self fillCasesDo: [ :case :draw |
		self assertDeviceDrawsCase: case with: draw ]
]

{ #category : 'tests' }
VGTiledFillTest >> testEveryFillCaseOfTheCorpusDrawsTheSameBytesAsTheSoftwareBackend [
	"The gate of unit 2.3. The oracle is the software backend and not Cairo: that backend already
	 held against Cairo on all forty-one cases in phase one, so matching it is both necessary and
	 sufficient. Every case the subset refuses belongs to a later unit, and fillCasesDo: asserts
	 the count, so a subset quietly narrowed by a later change fails here."

	self fillCasesDo: [ :case :draw |
		self
			assert: (self tiledFormOfExtent: case extent drawnWith: draw) bits
			equals: (self softwareFormOfExtent: case extent drawnWith: draw) bits ]
]

{ #category : 'tests' }
VGTiledFillTest >> testEveryFillCaseOfTheCorpusDrawsTheSameBytesFromTheBuffersAsFromItsOwnEntries [
	"The gate of the encoding, over the same cases the first step holds against the software
	 backend. The oracle is the frame narrowed to single floats, because that is what the buffers
	 can hold; what a single float costs against the software backend is measured in the last
	 step of unit 2.4 and not here."

	self fillCasesDo: [ :case :draw |
		self
			assert: (self encodedFormOfExtent: case extent drawnWith: draw) bits
			equals: (self singleFloatFormOfExtent: case extent drawnWith: draw) bits ]
]

{ #category : 'tests - gradients' }
VGTiledFillTest >> testEveryGradientFrameButTheDegenerateOnesLaysDownPixels [
	"A frame that draws nothing matches the software backend for nothing, so the gate above would
	 pass on a fixture of empty frames. Every frame but the two degenerate ones changes a pixel of
	 a surface nothing has drawn on, and those two change none."

	| blank |
	blank := (VGCairoImageSurface extent: VGGradientFrameFixture extent) asForm.
	self gradientFrames do: [ :each |
		| drawn degenerate |
		drawn := self
			         softwareFormOfExtent: VGGradientFrameFixture extent
			         drawnWith: each value.
		degenerate := self class degenerateGradientFrameNames includes:
			              each key.
		self
			assert: drawn bits = blank bits = degenerate
			description: each key ]
]

{ #category : 'tests - encoding' }
VGTiledFillTest >> testEveryGradientFrameDrawsTheSameBytesFromTheBuffersAloneAsFromItsOwnEntries [
	"The gate of the encoding over the gradient frames: the rasteriser reads the buffers and
	 never the display list they came from, and the oracle is the same frame narrowed to single
	 floats, which is all a buffer can hold. Every extend mode, both geometries and the
	 degenerate gradients are in the fixture, so a field of the paint block left unwritten shows
	 here and not in a picture no test draws."

	self gradientFrames do: [ :each |
		| draw |
		draw := each value.
		self
			assert: (VGTiledFillRasteriser supports:
					 (self displayListOfExtent: self caseExtent drawnWith: draw))
			description: each key printString , ' is not in the subset'.
		self
			assert: (self encodedFormOfExtent: self caseExtent drawnWith: draw) bits
			= (self singleFloatFormOfExtent: self caseExtent drawnWith: draw) bits
			description: each key printString
				, ' draws other bytes from the buffers' ]
]

{ #category : 'tests - device' }
VGTiledFillTest >> testEveryGradientFrameOfTheFixtureDrawsOnTheDeviceWhatTheSoftwareBackendDraws [
	"The gate of unit 2.4. Every gradient frame of the fixture, drawn on the device and by the
	 software backend on the same frame, holds to the same tolerance and the same per-case count
	 as the corpus; and against a software frame whose stops are narrowed to f32 first it is byte
	 for byte identical, which is the sharper half of the gate: the kernel evaluates a paint and
	 searches a stop list to the same bytes as the rasteriser, and what the loose half allows is
	 the narrowing of the stop and not the evaluation.
	 One context draws all of them, which is the session's. A machine with no device holds
	 nothing."

	| drawn |
	self hasDevice ifFalse: [ ^ self ].
	drawn := 0.
	self gradientFrames do: [ :each |
		| extent device comparison |
		extent := VGGradientFrameFixture extent.
		drawn := drawn + 1.
		device := self deviceFormOfExtent: extent drawnWith: each value.
		comparison := VGFormComparison
			              between: device
			              and: (self
					               softwareFormOfExtent: extent
					               drawnWith: each value).
		self
			assert: (comparison pixelsFartherThan: self class deviceChannelTolerance) = 0
			description: each key.
		self
			assert: comparison differingPixelCount
				    <= self class devicePixelsAllowedToDifferPerCase
			description: each key.
		self
			assert: device bits
			= (self singleFloatFormOfExtent: extent drawnWith: each value) bits
			description: each key ].
	self assert: drawn equals: self class gradientFrameCount
]

{ #category : 'tests - gradients' }
VGTiledFillTest >> testEveryGradientFrameOfTheFixtureDrawsTheSameBytesAsTheSoftwareBackend [
	"The gate of the first step of unit 2.4 over the frames the corpus does not draw: the four
	 extend modes, three stops, a hard edge inside the ramp, the two degenerate gradients, a
	 pattern matrix, both radial geometries, and a gradient meeting an operator, a constant alpha
	 and a fractional clip. Each of them is in the subset, because a frame the subset refuses
	 would hold nothing here."

	self gradientFrames do: [ :each |
		| extent |
		extent := VGGradientFrameFixture extent.
		self assert:
			(VGTiledFillRasteriser supports:
				 (self displayListOfExtent: extent drawnWith: each value))
			description: each key.
		self
			assert:
			(self tiledFormOfExtent: extent drawnWith: each value) bits
			= (self softwareFormOfExtent: extent drawnWith: each value) bits
			description: each key ]
]

{ #category : 'tests' }
VGTiledFillTest >> testTheBufferOfABindingIsMappedOnceAndStaysMappedForTheSession [
	"A frame uploads fourteen buffers and reads one back, and the address of a buffer's memory
	 does not move while the buffer lives. So the mapping is made on the first ask and kept: the
	 memory is host coherent, which is what lets a write through a kept pointer reach the device
	 with no flush. Asked of the buffer itself here, because the pointer it hands out is the one
	 the copy really writes through."

	| encoding target dispatch buffer pointer |
	self hasDevice ifFalse: [ ^ self ].
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self mixedFillFrame.
	target := ByteArray new:
		          self caseExtent x * self caseExtent y
		          * VGTiledFillEncoding targetFormat bytesPerPixel.
	dispatch := VGVulkanDeviceSession default dispatchForEncoding: encoding.
	dispatch draw: encoding into: target.
	buffer := dispatch deviceBuffers at: #edges.
	pointer := buffer mappingOrNil.
	self assert: pointer notNil.
	self assert: buffer sessionPointer equals: pointer.
	dispatch draw: encoding into: target.
	self assert: buffer mappingOrNil equals: pointer
]

{ #category : 'tests' }
VGTiledFillTest >> testTheBuffersAreSizedByTheFrameAndByNothingElse [
	"A header, a clip rectangle and a paint block an entry, four floats an edge, five floats a
	 stop of a gradient, a record a tile the frame touches, and a reference and a shape block
	 word an entry binned into one. The edges and the shape records carry the band blocks after
	 the whole shapes, so a frame weighs its own edges plus the edges its rows of tiles name.
	 Nothing is reserved and nothing is rounded up, so a frame can be weighed from its own
	 counts. A frame of solid fills and a frame of a gradient are both weighed, because a solid
	 paint contributes a block and no stop at all."

	{
		self mixedFillFrame.
		VGGradientFrameFixture linearWithThreeStops } do: [ :draw |
		| list encoding binning edges stopCount bands shapes |
		list := self displayListOfExtent: self caseExtent drawnWith: draw.
		binning := VGTileBinning of: list extent: self caseExtent.
		encoding := VGTiledFillEncoding of: list extent: self caseExtent.
		bands := VGTiledFillBands
			         binning: binning
			         fills: (binning entries collect: [ :each | each asTiledFill ]).
		edges := list entries inject: 0 into: [ :sum :each |
			         sum
			         + (each segments coordinates size
					          / VGTiledFillLayout edgeFloats) ].
		shapes := (1 to: encoding entryCount) inject: 0 into: [ :sum :index |
			          sum + (encoding decoder shapesOfEntryAt: index) size ].
		stopCount := list entries inject: 0 into: [ :sum :each |
			             sum + (each paint hasStops
					              ifTrue: [ each paint stops size ]
					              ifFalse: [ 0 ]) ].
		self assert: encoding entryCount equals: list entries size.
		self
			assert: encoding headers size
			equals: list entries size * VGTiledFillLayout entryHeaderWords.
		self
			assert: encoding clips size
			equals: list entries size * VGTiledFillLayout clipFloats.
		self
			assert: encoding paints size
			equals: list entries size * VGTiledFillLayout paintBlockFloats.
		self assert: encoding edgeCount equals: edges + bands edgeCount.
		self
			assert: encoding edges size
			equals: edges + bands edgeCount * VGTiledFillLayout edgeFloats.
		self
			assert: encoding shapes size
			equals:
			shapes + bands blockCount * VGTiledFillLayout shapeRecordWords.
		self assert: encoding stopCount equals: stopCount.
		self
			assert: encoding stops size
			equals: stopCount * VGTiledFillLayout stopFloats.
		self
			assert: encoding tileTable size
			equals: binning touchedTileCount * VGTiledFillLayout tileRecordWords.
		self assert: encoding entryRefs size equals: binning binnedEntryCount.
		self assert: encoding refShapes size equals: binning binnedEntryCount ]
]

{ #category : 'tests' }
VGTiledFillTest >> testTheBuffersOfAFrameAreSizedByTheCountsOfThatFrame [
	"The sizes are the whole of what VGTiledFillBuffers knows, so they are what a test of it
	 states. A run of mask bytes that does not fill its last word still owes that word, because
	 a storage buffer of the kernel holds words."

	| buffers |
	buffers := VGTiledFillBuffers new.
	buffers allocateForEntries: 2 edges: 8 stops: 3 masks: 9.
	self
		assert: buffers headers size
		equals: 2 * VGTiledFillLayout entryHeaderWords.
	self assert: buffers clips size equals: 2 * VGTiledFillLayout clipFloats.
	self assert: buffers maskRects size equals: 2 * VGTiledFillLayout clipFloats.
	self
		assert: buffers paints size
		equals: 2 * VGTiledFillLayout paintBlockFloats.
	self assert: buffers edges size equals: 8 * VGTiledFillLayout edgeFloats.
	self assert: buffers stops size equals: 3 * VGTiledFillLayout stopFloats.
	self assert: buffers maskBytes size equals: 3.
	buffers allocateForTiles: 6 references: 9.
	self
		assert: buffers tileTable size
		equals: 6 * VGTiledFillLayout tileRecordWords.
	self assert: buffers entryRefs size equals: 9
]

{ #category : 'tests' }
VGTiledFillTest >> testTheBytesAndTheWordsOfABlockAreReadOffTheBlockItself [
	"A block of a binding is a WordArray, a Float32Array or the run of pixels of the target, and
	 the three count their elements differently while the device is given bytes. The bytes of a
	 block are therefore asked of the block, which knows its own element width, and the words are
	 those bytes over the stride of the kernel. An empty binding still owes the device a buffer,
	 so its word count is the floor and not nought."

	| dispatch |
	dispatch := VGTiledFillDispatch new.
	self
		assert: (dispatch byteCountOfBlock: (WordArray new: 5))
		equals: 5 * VGTiledFillKernel elementStride.
	self
		assert: (dispatch byteCountOfBlock: (Float32Array new: 5))
		equals: 5 * VGTiledFillKernel elementStride.
	self assert: (dispatch byteCountOfBlock: (ByteArray new: 5)) equals: 5.
	self assert: (dispatch wordCountOfBlock: (WordArray new: 5)) equals: 5.
	self
		assert: (dispatch wordCountOfBlock: (WordArray new: 0))
		equals: VGTiledFillDispatch emptyBufferWordCount
]

{ #category : 'tests - layout' }
VGTiledFillTest >> testTheChannelsOfAStopFollowItsPositionAndFillTheRecord [
	"A stop rides as its offset and then its four channels, and the kernel reads the channels as a
	 run from one index. They have to be consecutive and reach the end of the record, or a ramp
	 would read the position of the next stop as a colour."

	self
		assert: VGTiledFillLayout stopChannelFields first
		equals: VGTiledFillLayout stopPositionField + 1.
	self
		assert: VGTiledFillLayout stopChannelFields last
		equals: VGTiledFillLayout stopFloats.
	self
		assert: VGTiledFillLayout stopChannelFields asArray
		equals:
			(VGTiledFillLayout stopChannelFields first
				 to: VGTiledFillLayout stopChannelFields last) asArray
]

{ #category : 'tests' }
VGTiledFillTest >> testTheClearOperatorDrawsTheSameBytesAsTheSoftwareBackend [
	"Clear weighs the destination by what is left of the coverage and reads no source at all, and
	 the entries of a tile are composited in the order they were drawn."

	| draw |
	draw := [ :context |
	         context
		         sourceColorR: 0.1 g: 0.7 b: 0.2 a: 1.0;
		         rectangleX: 2 y: 2 width: 60 height: 60;
		         fill;
		         setOperatorClear;
		         circleCenterX: 30 y: 34 radius: 14.5;
		         fill ].
	self
		assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
		equals: (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
]

{ #category : 'tests' }
VGTiledFillTest >> testTheEdgesOfAnEncodedEntryAreItsOwnCoordinatesNarrowedToSingleFloats [
	"The edge buffer is the path and nothing else: two ends an edge, in the order the segments
	 hold them, each coordinate narrowed to a single float and widened again unchanged."
	| list encoding |
	list := self displayListOfExtent: self caseExtent drawnWith: self mixedFillFrame.
	encoding := VGTiledFillEncoding of: list extent: self caseExtent.
	list entries withIndexDo: [ :each :index |
		self
			assert: (encoding entryAt: index) segments coordinates asArray
			equals: (each segments coordinates collect: [ :coordinate |
					 self roundedToSingleFloat: coordinate ]) asArray ]
]

{ #category : 'tests' }
VGTiledFillTest >> testTheFrameDrawnFromTheBuffersAloneHoldsTheSameBytesAsItsSingleFloatFrame [
	"Four fills, three operators and a fractional clip, drawn once from the buffers and once
	 from the entries narrowed to the same single floats. The two agree byte for byte where the
	 encoding carries the frame and nothing of its own."
	self
		assert:
		(self encodedFormOfExtent: self caseExtent drawnWith: self mixedFillFrame)
			bits
		equals:
		(self
			 singleFloatFormOfExtent: self caseExtent
			 drawnWith: self mixedFillFrame) bits
]

{ #category : 'tests' }
VGTiledFillTest >> testTheFrameTheDeviceGateDrawsReallyCarriesMarkedReferences [
	"The interior fast path of the kernel is under test only where a frame marks a tile, so the
	 frame the gate above draws has to carry marks. The mixed fill frame does: its rectangles are
	 wider than a tile."

	| encoding marked |
	encoding := VGTiledFillEncoding
		            of: (self
				             displayListOfExtent: self caseExtent
				             drawnWith: self mixedFillFrame)
		            extent: self caseExtent.
	marked := (1 to: encoding entryRefs size) count: [ :index |
		          VGTiledFillLayout isInteriorReference:
			          (encoding entryRefs at: index) ].
	self assert: marked > 0
]

{ #category : 'tests' }
VGTiledFillTest >> testTheKernelWorkgroupIsOneTileOfTheGrid [
	"One workgroup owns one tile, so the local size is the tile's own extent and nothing else:
	 an invocation finds its pixel by adding its local id to the corner its tile record
	 carries."

	| grid |
	grid := VGTileGrid extent: self caseExtent.
	self
		assert: (PVSpirvValidator on:
				 (VGTiledFillKernel onTileExtent: grid tileExtent) spirv) localSizeFromWords
		equals: {
				grid tileExtent x.
				grid tileExtent y.
				1 }
]

{ #category : 'tests' }
VGTiledFillTest >> testTheReferenceOfATileAFillCoversWhollyCarriesItsFlagAndItsIdentifier [
	"The mark the binning made travels to the device in the reference word itself, in the bit no
	 identifier of a frame can reach: the kernel then takes the coverage of the pixel as one and
	 walks no edge there. A tile the fill cuts carries the identifier alone."

	| list encoding grid inside onTheEdge |
	grid := VGTileGrid extent: 64 @ 64 tileExtent: 16 @ 16.
	list := self
		        displayListOfExtent: 64 @ 64
		        drawnWith: [ :context |
			        context
				        rectangleX: 8 y: 8 width: 48 height: 48;
				        fill ].
	encoding := VGTiledFillEncoding of: list grid: grid.
	inside := (grid indexesIntersecting: (33 @ 33 corner: 34 @ 34)) anyOne.
	onTheEdge := (grid indexesIntersecting: (0 @ 0 corner: 1 @ 1)) anyOne.
	self assert: (VGTiledFillLayout isInteriorReference:
			 (self referenceOfTileAt: inside in: encoding)).
	self deny: (VGTiledFillLayout isInteriorReference:
			 (self referenceOfTileAt: onTheEdge in: encoding)).
	self
		assert: (VGTiledFillLayout identifierOfReference:
				 (self referenceOfTileAt: inside in: encoding))
		equals: 1.
	self assert: (encoding entriesOfTileAt: inside) size equals: 1
]

{ #category : 'tests - bands' }
VGTiledFillTest >> testTheShapeBlockAReferenceNamesHoldsTheEntrysShapesNarrowedToThatRowOfTiles [
	"A reference of a tile names a block of shape records, one a shape of its entry and in the
	 order the entry holds them, each naming only the edges of that shape that reach the rows of
	 that tile. The records are read back as scanners, so a field written into the wrong word or
	 a block named one record out shows as the wrong edges, the wrong fill rule or the wrong
	 antialiasing."

	| list encoding binning fills bands |
	list := self
		        displayListOfExtent: self caseExtent
		        drawnWith: self mixedFillFrame.
	binning := VGTileBinning of: list extent: self caseExtent.
	fills := binning entries collect: [ :each | each asTiledFill ].
	bands := VGTiledFillBands binning: binning fills: fills.
	encoding := VGTiledFillEncoding of: list extent: self caseExtent.
	binning touchedTileIndexes do: [ :tileIndex |
		| base offset count |
		base := (encoding rowOfTileAt: tileIndex) - 1
		        * VGTiledFillLayout tileRecordWords.
		offset := encoding tileTable
			          at: base + VGTiledFillLayout referenceOffsetField.
		count := encoding tileTable
			         at: base + VGTiledFillLayout referenceCountField.
		1 to: count do: [ :position |
			| identifier block |
			identifier := VGTiledFillLayout identifierOfReference:
				              (encoding entryRefs at: offset + position).
			block := encoding refShapes at: offset + position.
			(bands shapesOfEntry: identifier) withIndexDo: [ :shape :ordinal |
				| record expected |
				record := encoding decoder shapeAtOffset: block + ordinal - 1.
				expected := (bands
					             edgeIndexesOfEntry: identifier
					             shape: ordinal
					             inRow: (bands rowOfTilesAt: tileIndex))
					            inject: OrderedCollection new
					            into: [ :acc :each |
						            acc
							            addAll:
								            ((each to: each + VGTiledFillLayout edgeFloats - 1)
									             collect: [ :coordinate |
									             self roundedToSingleFloat:
											             (shape segments at: coordinate) ]);
							            yourself ].
				self assert: record segments asArray equals: expected asArray.
				self assert: record fillRule equals: shape fillRule.
				self assert: record isAliased equals: shape isAliased ] ] ]
]

{ #category : 'tests' }
VGTiledFillTest >> testTheSourceOperatorDrawsTheSameBytesAsTheSoftwareBackend [
	"The source operator mixes with the destination instead of scaling the source, so the edge
	 pixels of the second fill carry the first one's colour in proportion to the coverage."

	| draw |
	draw := [ :context |
	         context
		         sourceColorR: 0.9 g: 0.1 b: 0.1 a: 1.0;
		         rectangleX: 4 y: 4 width: 56 height: 56;
		         fill;
		         setOperatorSource;
		         sourceColorR: 0.0 g: 0.3 b: 0.8 a: 0.5;
		         circleCenterX: 32 y: 32 radius: 16;
		         fill ].
	self
		assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
		equals: (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
]

{ #category : 'tests' }
VGTiledFillTest >> testTheSubsetHoldsAFillOfASolidColourAGradientOrASurfaceAndNothingElse [
	"What the kernel can draw, which unit 2.4 widened from a solid colour to a gradient and unit
	 2.9 to a surface. A frame outside the subset is not drawn wrongly: it is refused here, so
	 that the backend can hand it to the failover whole. A clip cut out by shapes is in the subset
	 since unit 2.7, so the shaped frame here holds the fact that a shape in the clip refuses
	 nothing on its own; a mesh paint is what is left outside it."

	| solid gradient surfacePaint mesh shaped |
	solid := self
		         displayListOfExtent: self caseExtent
		         drawnWith: [ :context |
			         context
				         rectangleX: 1 y: 1 width: 10 height: 10;
				         fill ].
	gradient := self
		            displayListOfExtent: self caseExtent
		            drawnWith: [ :context |
			            context
				            sourcePattern: self twoStopGradient;
				            rectangleX: 1 y: 1 width: 10 height: 10;
				            fill ].
	surfacePaint := self
		                displayListOfExtent: self caseExtent
		                drawnWith: [ :context |
			                context
				                sourceSurface: (VGCairoImageSurface extent: 4 @ 4)
				                x: 0
				                y: 0;
				                rectangleX: 1 y: 1 width: 10 height: 10;
				                fill ].
	mesh := self
		        displayListOfExtent: self caseExtent
		        drawnWith: [ :context |
			        context
				        sourcePattern: VGTiledFillExamples meshPatternOutsideTheSubset;
				        rectangleX: 1 y: 1 width: 10 height: 10;
				        fill ].
	shaped := self
		          displayListOfExtent: self caseExtent
		          drawnWith: [ :context |
			          context
				          circleCenterX: 32 y: 32 radius: 20;
				          clip;
				          rectangleX: 1 y: 1 width: 10 height: 10;
				          fill ].
	self assert: (VGTiledFillRasteriser supports: solid).
	self assert: (VGTiledFillRasteriser supports: gradient).
	self assert: (VGTiledFillRasteriser supports: surfacePaint).
	self deny: (VGTiledFillRasteriser supports: mesh).
	self assert: (VGTiledFillRasteriser supports: shaped)
]

{ #category : 'tests' }
VGTiledFillTest >> testTheTileSizeDoesNotChangeOneByte [
	"A tile is a way of cutting the work up and not a part of the picture: a shape that crosses
	 several tiles has to come out the same whatever the size of a tile."

	| draw small large |
	draw := [ :context |
	         context
		         sourceColorR: 0.8 g: 0.5 b: 0.0 a: 0.75;
		         circleCenterX: 32 y: 32 radius: 25.5;
		         fill ].
	small := self
		         tiledFormOfExtent: self caseExtent
		         tileExtent: 8 @ 8
		         drawnWith: draw.
	large := self
		         tiledFormOfExtent: self caseExtent
		         tileExtent: 48 @ 48
		         drawnWith: draw.
	self assert: small bits equals: large bits.
	self
		assert: small bits
		equals: (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
]

{ #category : 'fixtures' }
VGTiledFillTest >> twoStopGradient [
	"A paint the kernel cannot evaluate yet, built the way the gradient cases of the corpus build
	 one: through the pattern facade, because that is what a context takes as its source."

	^ VGCairoLinearGradientPattern
		  from: 0 @ 0
		  to: self caseExtent
		  addStopsFrom: VGConformanceCorpus twoStopRamp
]
