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
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'constants' }
VGTiledFillTest class >> fillCaseCount [
	"Counted over the corpus: twenty-two of the forty-one cases are fills of a solid paint inside
	 a rectangular clip, which is the subset unit 2.3 draws. The other nineteen carry a gradient,
	 a surface or a mesh paint, a blit or a shaped clip, and wait for units 2.4 to 2.6."

	^ 22
]

{ #category : 'fixtures' }
VGTiledFillTest >> caseExtent [
	"The extent of every case of the conformance corpus, and of every frame I draw myself."

	^ VGConformanceCorpus caseExtent
]

{ #category : 'fixtures' }
VGTiledFillTest >> displayListOfExtent: anExtent drawnWith: aBlock [
	"The recorded frame itself, read before anything drains it."

	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	^ surface displayList
]

{ #category : 'fixtures' }
VGTiledFillTest >> encodedFormOfExtent: anExtent drawnWith: aBlock [
	"The same frame drawn from the buffers alone: the rasteriser of step one reads the encoding
	 and never the display list it came from."
	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	(VGTiledFillRasteriser on:
		 (VGTiledFillEncoding of: surface displayList extent: anExtent))
		drawOn: surface.
	surface displayList reset.
	^ surface asForm
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

{ #category : 'fixtures' }
VGTiledFillTest >> roundedToSingleFloat: aNumber [
	"The number as a buffer of single floats keeps it, widened again so that the oracle of this
	 step computes in the values the buffers hold. Read through the bit pattern rather than
	 through a Float32Array, so that the oracle narrows by its own route and not by the
	 encoding's."
	^ Float fromIEEE32Bit: aNumber asFloat asIEEE32BitWord
]

{ #category : 'fixtures' }
VGTiledFillTest >> singleFloatCopyOf: aDisplayList [
	"A display list of my own, holding the same frame in single floats. It is built before the
	 frame is drained, because draining resets the list."
	| copied |
	copied := VGDisplayList new.
	aDisplayList entries do: [ :each |
		copied add: (self singleFloatEntryOf: each) ].
	^ copied
]

{ #category : 'fixtures' }
VGTiledFillTest >> singleFloatEntryOf: anEntry [
	"The entry with its coordinates and its clip narrowed to single floats and everything else
	 its own: the paint, the operator, the fill rule, the antialiasing mode and the alpha are
	 carried by the encoding without arithmetic, so this step gates the layout alone."
	| segments |
	segments := (VGSegments
		             coordinates:
			             (anEntry segments coordinates collect: [ :each |
				              self roundedToSingleFloat: each ])
		             fillRule: anEntry segments fillRule
		             antialias: anEntry segments antialias) withAlpha:
		            anEntry segments alpha.
	^ VGFillEntry
		  segments: segments
		  paint: anEntry paint
		  clip: (VGClip bounds: (self singleFloatRectangleOf: anEntry clip bounds))
		  operator: anEntry operator
]

{ #category : 'fixtures' }
VGTiledFillTest >> singleFloatFormOfExtent: anExtent drawnWith: aBlock [
	"The oracle of this step: the same frame narrowed to single floats and drawn through the
	 entries themselves. Where the buffers hold the frame and nothing more, the two agree byte
	 for byte."
	| surface list |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	list := self singleFloatCopyOf: surface displayList.
	surface displayList reset.
	(VGTiledFillRasteriser of: list extent: anExtent) drawOn: surface.
	^ surface asForm
]

{ #category : 'fixtures' }
VGTiledFillTest >> singleFloatRectangleOf: aRectangle [
	^ Rectangle
		  left: (self roundedToSingleFloat: aRectangle left)
		  right: (self roundedToSingleFloat: aRectangle right)
		  top: (self roundedToSingleFloat: aRectangle top)
		  bottom: (self roundedToSingleFloat: aRectangle bottom)
]

{ #category : 'fixtures' }
VGTiledFillTest >> softwareFormOfExtent: anExtent drawnWith: aBlock [
	"The frame the software backend draws, which is the oracle of every test of mine."

	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	surface flush.
	^ surface asForm
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
VGTiledFillTest >> testEveryFillCaseOfTheCorpusDrawsTheSameBytesAsTheSoftwareBackend [
	"The gate of this step. The oracle is the software backend and not Cairo: that backend already
	 held against Cairo on all forty-one cases in phase one, so matching it is both necessary and
	 sufficient. Every case the subset refuses belongs to a later unit, and the count is asserted
	 so that a subset quietly narrowed by a later change fails here."

	| drawn |
	drawn := 0.
	VGConformanceCorpus cases do: [ :case |
		| draw |
		draw := [ :context | case drawOn: context ].
		(VGTiledFillRasteriser supports:
			 (self displayListOfExtent: case extent drawnWith: draw)) ifTrue: [
			drawn := drawn + 1.
			self
				assert: (self tiledFormOfExtent: case extent drawnWith: draw) bits
				equals: (self softwareFormOfExtent: case extent drawnWith: draw) bits ] ].
	self assert: drawn equals: self class fillCaseCount
]

{ #category : 'tests' }
VGTiledFillTest >> testEveryFillCaseOfTheCorpusDrawsTheSameBytesFromTheBuffersAsFromItsOwnEntries [
	"The gate of this step, over the same twenty-two cases the first step holds against the
	 software backend. The oracle is the frame narrowed to single floats, because that is what
	 the buffers can hold; what a single float costs against the software backend is measured in
	 the last step of this unit and not here."
	| drawn |
	drawn := 0.
	VGConformanceCorpus cases do: [ :case |
		| draw |
		draw := [ :context | case drawOn: context ].
		(VGTiledFillRasteriser supports:
			 (self displayListOfExtent: case extent drawnWith: draw)) ifTrue: [
			drawn := drawn + 1.
			self
				assert: (self encodedFormOfExtent: case extent drawnWith: draw) bits
				equals:
				(self singleFloatFormOfExtent: case extent drawnWith: draw) bits ] ].
	self assert: drawn equals: self class fillCaseCount
]

{ #category : 'tests' }
VGTiledFillTest >> testTheBuffersAreSizedByTheFrameAndByNothingElse [
	"A header and a clip rectangle an entry, four floats an edge, a record a tile the frame
	 touches and a reference an entry binned into one. Nothing is reserved and nothing is
	 rounded up, so a frame can be weighed from its own counts."
	| list encoding binning edges |
	list := self displayListOfExtent: self caseExtent drawnWith: self mixedFillFrame.
	binning := VGTileBinning of: list extent: self caseExtent.
	encoding := VGTiledFillEncoding of: list extent: self caseExtent.
	edges := list entries inject: 0 into: [ :sum :each |
		         sum + (each segments coordinates size / VGTiledFillEncoding edgeFloats) ].
	self assert: encoding entryCount equals: list entries size.
	self
		assert: encoding headers size
		equals: list entries size * VGTiledFillEncoding entryHeaderWords.
	self
		assert: encoding clips size
		equals: list entries size * VGTiledFillEncoding clipFloats.
	self assert: encoding edgeCount equals: edges.
	self
		assert: encoding edges size
		equals: edges * VGTiledFillEncoding edgeFloats.
	self
		assert: encoding tileTable size
		equals: binning touchedTileCount * VGTiledFillEncoding tileRecordWords.
	self assert: encoding entryRefs size equals: binning binnedEntryCount
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
VGTiledFillTest >> testTheSubsetHoldsASolidFillAndNothingElse [
	"What the kernel will be able to draw. A frame outside the subset is not drawn wrongly: it is
	 refused here, so that the backend can hand it to the failover whole."

	| solid gradient blit shaped |
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
	self deny: (VGTiledFillRasteriser supports: gradient).
	self deny: (VGTiledFillRasteriser supports: blit).
	self deny: (VGTiledFillRasteriser supports: shaped)
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
VGTiledFillTest >> tiledFormOfExtent: anExtent drawnWith: aBlock [
	"The same frame drawn through the tiles. The display list is read before anything drains it and
	 reset afterwards, so that reading the pixels does not replay the frame on the software
	 backend as well."

	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	(VGTiledFillRasteriser of: surface displayList extent: anExtent) drawOn: surface.
	surface displayList reset.
	^ surface asForm
]

{ #category : 'fixtures' }
VGTiledFillTest >> tiledFormOfExtent: anExtent tileExtent: aTileExtent drawnWith: aBlock [
	"The same frame over a grid of that tile size. A tile owns its pixels alone, so the size of a
	 tile may change how the work is cut up and may not change one byte of the result."

	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	aBlock value: surface newContext.
	(VGTiledFillRasteriser
		 of: surface displayList
		 grid: (VGTileGrid extent: anExtent tileExtent: aTileExtent)) drawOn: surface.
	surface displayList reset.
	^ surface asForm
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
