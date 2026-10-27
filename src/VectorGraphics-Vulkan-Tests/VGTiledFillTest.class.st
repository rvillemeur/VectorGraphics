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
	"Counted over the corpus: twenty-five of the forty-one cases are fills of a solid colour or of
	 a gradient, which is the subset units 2.3, 2.4 and 2.7 draw. Unit 2.3 drew twenty-two of
	 them inside a rectangular clip, unit 2.4 added the two gradient cases and unit 2.7 added
	 clip-circle by drawing a clip cut out by shapes. The other sixteen carry a surface or a mesh
	 paint or record a blit, and wait for units 2.8 and after."

	^ 25
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
VGTiledFillTest >> testADispatchSendsOneRunOfBytesForEveryBindingTheKernelReads [
	"What a dispatch uploads: one run of bytes for every binding the kernel declares, each as
	 wide as the words behind it, and a frame record holding the extent the kernel indexes a
	 pixel by. None of this needs a device, so it is held on every machine."

	| encoding target bytes word |
	word := VGTiledFillKernel elementStride.
	encoding := VGTiledFillEncoding
		            of: (self
				             displayListOfExtent: self caseExtent
				             drawnWith: self mixedFillFrame)
		            extent: self caseExtent.
	target := ByteArray new:
		          self caseExtent x * self caseExtent y
		          * VGTiledFillEncoding targetFormat bytesPerPixel.
	bytes := VGTiledFillDispatch new bytesOf: encoding target: target.
	self
		assert: bytes keys asSortedCollection asArray
		equals: VGTiledFillKernel bindingNames asSortedCollection asArray.
	self
		assert: (bytes at: #tileTable) size
		equals: encoding tileTable size * word.
	self assert: (bytes at: #edges) size equals: encoding edges size * word.
	self assert: (bytes at: #target) identicalTo: target.
	self
		assert: ((bytes at: #frame) uint32AtOffset:
				 VGTiledFillKernel frameWidthField - 1 * word)
		equals: self caseExtent x.
	self
		assert: ((bytes at: #frame) uint32AtOffset:
				 VGTiledFillKernel frameHeightField - 1 * word)
		equals: self caseExtent y.
	self
		assert: ((bytes at: #edges) float32AtOffset: 0)
		equals: (encoding edges at: 1).
	self
		assert: ((bytes at: #tileTable) uint32AtOffset: 0)
		equals: (encoding tileTable at: 1)
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
	self assert: dispatch bytes notNil
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

{ #category : 'tests' }
VGTiledFillTest >> testEveryFillCaseOfTheCorpusDrawsOnTheDeviceWhatTheSoftwareBackendDraws [
	"The gate of unit 2.3. Every case of the corpus the subset draws, drawn on the device and by
	 the software backend on the same frame and compared premultiplied: no pixel farther than the
	 tolerance in any channel, and at most the measured count of pixels differing at all.
	 One context draws all of them, because a device costs 72 ms to open and a frame does not. A
	 machine with no device has nothing to compare and holds nothing."

	| context |
	context := [ VkContext computeContext ]
		           on: Error
		           do: [ :failure | nil ].
	context ifNil: [ ^ self ].
	[
	self fillCasesDo: [ :case :draw |
		self
			assertDeviceDrawsCase: case
			with: draw
			on: context ] ] ensure: [ context destroy ]
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
	 One context draws all of them. A machine with no device holds nothing."
	| context drawn |
	context := [ VkContext computeContext ]
		           on: Error
		           do: [ :failure | nil ].
	context ifNil: [ ^ self ].
	drawn := 0.
	[
	self gradientFrames do: [ :each |
		| extent device comparison |
		extent := VGGradientFrameFixture extent.
		drawn := drawn + 1.
		device := self
			          deviceFormOfExtent: extent
			          drawnWith: each value
			          on: context.
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
			description: each key ] ] ensure: [ context destroy ].
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

{ #category : 'tests - encoding' }
VGTiledFillTest >> testTheBuffersAreSizedByTheFrameAndByNothingElse [
	"A header, a clip rectangle and a paint block an entry, four floats an edge, five floats a
	 stop of a gradient, a record a tile the frame touches and a reference an entry binned into
	 one. Nothing is reserved and nothing is rounded up, so a frame can be weighed from its own
	 counts. A frame of solid fills and a frame of a gradient are both weighed, because a solid
	 paint contributes a block and no stop at all."

	{
		self mixedFillFrame.
		VGGradientFrameFixture linearWithThreeStops } do: [ :draw |
		| list encoding binning edges stopCount |
		list := self displayListOfExtent: self caseExtent drawnWith: draw.
		binning := VGTileBinning of: list extent: self caseExtent.
		encoding := VGTiledFillEncoding of: list extent: self caseExtent.
		edges := list entries inject: 0 into: [ :sum :each |
			         sum
			         + (each segments coordinates size
					          / VGTiledFillLayout edgeFloats) ].
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
		self assert: encoding edgeCount equals: edges.
		self
			assert: encoding edges size
			equals: edges * VGTiledFillLayout edgeFloats.
		self assert: encoding stopCount equals: stopCount.
		self
			assert: encoding stops size
			equals: stopCount * VGTiledFillLayout stopFloats.
		self
			assert: encoding tileTable size
			equals: binning touchedTileCount * VGTiledFillLayout tileRecordWords.
		self assert: encoding entryRefs size equals: binning binnedEntryCount ]
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

{ #category : 'tests - subset' }
VGTiledFillTest >> testTheSubsetHoldsAFillOfASolidColourOrAGradientAndNothingElse [
	"What the kernel can draw, which unit 2.4 widened from a solid colour to a gradient. A frame
	 outside the subset is not drawn wrongly: it is refused here, so that the backend can hand it
	 to the failover whole. A clip cut out by shapes is in the subset since unit 2.7, so
	 the shaped frame here holds the fact that a shape in the clip refuses nothing on its own."

	| solid gradient surfacePaint blit shaped |
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
	blit := self
		        displayListOfExtent: self caseExtent
		        drawnWith: [ :context |
			        context
				        sourceSurface: (VGCairoImageSurface extent: 4 @ 4) x: 0 y: 0;
				        paint ].
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
	self deny: (VGTiledFillRasteriser supports: surfacePaint).
	self deny: (VGTiledFillRasteriser supports: blit).
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
