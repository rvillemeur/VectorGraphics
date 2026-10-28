"
I am the gate of unit 2.9: a fill whose paint is another surface, which is Cairo's cairo_set_source_surface, drawn by the tiled rasteriser and by the device. A surface paint samples the nearest pixel of its source under its own extend mode, so what travels to the device is the pixels of that surface and not a formula, and what I hold is that the three ways of drawing one - the software backend, the buffers of an encoding and the device - agree byte for byte.
"
Class {
	#name : 'VGTiledSurfacePaintTest',
	#superclass : 'VGTiledFrameTestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'constants' }
VGTiledSurfacePaintTest class >> pixelsSampledOutsideTheSource [
	"How far outside a source surface a test samples a paint over it. Every extend mode is
	 arithmetic on the pixel index, and a mode that folds reads a different pixel on either side,
	 so a few pixels off each edge is where a fold that runs the wrong way shows."

	^ 3
]

{ #category : 'constants' }
VGTiledSurfacePaintTest class >> smallTileExtent [
	"The extent of a source smaller than the frame. Neither side divides the frame, so a mode
	 that repeats or reflects shows a partial tile at the far edge."

	^ 21 @ 18
]

{ #category : 'constants' }
VGTiledSurfacePaintTest class >> surfaceCaseCount [
	"The cases of the conformance corpus that fill through a surface paint and that the subset
	 draws: source-surface-pattern, source-surface-directly, group-painted-with-alpha and the
	 two figure-outskirts cases. All five sample a 64 by 64 argb32 source one to one under the
	 identity and the extend mode none, which is why the frames of this class carry the offsets,
	 the other three extend modes and the shaped clip instead. The number is asserted wherever
	 the corpus is walked, so a capability lost by a later change cannot pass as a case quietly
	 skipped."

	^ 5
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfaceCasesDo: aBlock [
	"Every case the subset draws that fills through a surface paint, with the block that draws
	 it. The count is asserted here, so that a subset quietly narrowed by a later change fails in
	 every test that walks the corpus."

	| drawn |
	drawn := 0.
	self supportedCasesDo: [ :case :draw :entries |
		(entries anySatisfy: [ :each |
			 each paint isNotNil and: [ each paint isKindOf: VGSurfacePaint ] ]) ifTrue: [
			drawn := drawn + 1.
			aBlock value: case value: draw ] ].
	self assert: drawn equals: self class surfaceCaseCount
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfacePaintEntryOfFrame: aBlock [
	"The one entry of that frame whose paint is a surface, which is what every fact about a
	 surface paint is asked of."

	^ (self displayListOfExtent: self caseExtent drawnWith: aBlock) entries 
		  detect: [ :each | each paint isKindOf: VGSurfacePaint ]
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfacePaintFrame [
	"One fill of the whole frame out of a source surface of the same extent, laid down at one to
	 one, which is what the two source cases of the corpus draw and what Cairo's
	 cairo_set_source_surface does."

	^ [ :context |
	  context sourceSurface: (self surfaceTileOfExtent: self caseExtent).
	  context
		  rectangleX: 0
		  y: 0
		  width: self caseExtent x
		  height: self caseExtent y.
	  context fill ]
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfacePaintFrameAtAnOffset [
	"A source smaller than the frame, laid down at an offset under the default extend mode, so
	 every pixel the tile does not reach is painted by nothing at all. The offset goes through
	 the very message Cairo's cairo_set_source_surface takes one in, which composes a
	 translation into the matrix of the pattern."

	^ [ :context |
	  context
		  sourceSurface: (self surfaceTileOfExtent: self class smallTileExtent)
		  x: 7
		  y: 5.
	  context
		  rectangleX: 0
		  y: 0
		  width: self caseExtent x
		  height: self caseExtent y.
	  context fill ]
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfacePaintFrameExtendedBy: aSymbol [
	"A source smaller than the frame painted over the whole of it under that extend mode. All
	 four modes are arithmetic on the pixel index of each axis, and only none leaves a pixel
	 unpainted, so the four frames together say whether the fold runs the right way."

	^ [ :context |
	  context sourcePattern: ((VGCairoSurfacePattern surface:
			    (self surfaceTileOfExtent: self class smallTileExtent))
			   extend: aSymbol;
			   yourself).
	  context paint ]
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfacePaintFrameInAShapedClip [
	"The small source repeated over a disc, so that the pixels of a source and the shapes of a
	 clip are walked for the same pixel. The clip is cut out by a path and not by a rectangle,
	 which is the one geometry that was refused before unit 2.7."

	^ [ :context |
	  context circleCenterX: 32 y: 32 radius: 26.
	  context clip.
	  context sourcePattern: ((VGCairoSurfacePattern surface:
			    (self surfaceTileOfExtent: self class smallTileExtent))
			   extend: #repeat;
			   yourself).
	  context paint ]
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfacePaintFrameNames [
	"Every frame of my own, by the name of the method that answers it, so that a test holds all
	 of them and a frame added here is gated without the test being edited."

	^ #( #surfacePaintFrame #surfacePaintFrameAtAnOffset
	     #surfacePaintFrameUnpaintedOutsideItsSource
	     #surfacePaintFrameRepeatingItsSource
	     #surfacePaintFrameReflectingItsSource #surfacePaintFramePaddingItsSource
	     #surfacePaintFrameInAShapedClip #surfacePaintFrameUnderSourceAndClear )
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfacePaintFramePaddingItsSource [
	"The small source over the whole frame under the pad extend mode."

	^ self surfacePaintFrameExtendedBy: #pad
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfacePaintFrameReflectingItsSource [
	"The small source over the whole frame under the reflect extend mode."

	^ self surfacePaintFrameExtendedBy: #reflect
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfacePaintFrameRepeatingItsSource [
	"The small source over the whole frame under the repeat extend mode."

	^ self surfacePaintFrameExtendedBy: #repeat
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfacePaintFrameUnderSourceAndClear [
	"A flat colour, then the source surface written over it under the source operator, then a
	 band cleared. Source writes the pixels of the paint where it lays nothing down as well,
	 which is where a paint that answers nothing and a paint that answers a transparent pixel
	 part company."

	^ [ :context |
	  context sourceColorR: 0.9 g: 0.9 b: 0.2 a: 1.0.
	  context paint.
	  context setOperatorSource.
	  context
		  sourceSurface: (self surfaceTileOfExtent: self class smallTileExtent)
		  x: 10
		  y: 12.
	  context rectangleX: 4 y: 4 width: 40 height: 40.
	  context fill.
	  context setOperatorClear.
	  context rectangleX: 0 y: 50 width: 64 height: 6.
	  context fill ]
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfacePaintFrameUnpaintedOutsideItsSource [
	"The small source over the whole frame under the none extend mode."

	^ self surfacePaintFrameExtendedBy: #none
]

{ #category : 'fixtures' }
VGTiledSurfacePaintTest >> surfaceTileOfExtent: anExtent [
	"A source surface carrying all three alphas a pixel can carry: transparent over the top half,
	 half opaque over a band of the bottom half and opaque under a disc, so that a paint over it
	 proves more than a copy of one colour. A translucent pixel is what makes the sampling a
	 round trip through an unpremultiplied colour and not a copy of a word."

	| tile context |
	tile := VGCairoImageSurface extent: anExtent.
	context := tile newContext.
	context clearTransparent.
	context sourceColorR: 0.1 g: 0.6 b: 0.8 a: 0.5.
	context
		rectangleX: 0
		y: anExtent y / 2
		width: anExtent x
		height: anExtent y / 2.
	context fill.
	context sourceColorR: 1.0 g: 0.5 b: 0.0 a: 1.0.
	context
		circleCenterX: anExtent x / 2
		y: anExtent y / 2
		radius: anExtent x / 4.
	context fill.
	tile flush.
	^ tile
]

{ #category : 'tests - subset' }
VGTiledSurfacePaintTest >> testASurfaceOfAnotherFormatIsRefusedForItsPaintAndNamedSo [
	"A source of another format is refused, because its pixels are read by the kernel as the
	 words of the one format a frame is encoded for. The census names the clause, so a frame a
	 device cannot draw says why."

	| entry census |
	entry := self surfacePaintEntryOfFrame: [ :context |
		         context sourceSurface: (VGCairoImageSurface
				          extent: self caseExtent
				          format: VGCairoSurfaceFormat a8).
		         context
			         rectangleX: 0
			         y: 0
			         width: self caseExtent x
			         height: self caseExtent y.
		         context fill ].
	self deny: (VGTiledFillRasteriser supportsPaint: entry paint).
	self deny: (VGTiledFillRasteriser supportsEntry: entry).
	census := VGTiledFillSupportCensus
		          of: (Array with: entry)
		          named: self class name.
	self deny: census isFrameSupported.
	self
		assert: (census countByReason at: #paintNotSupported)
		equals: 1
]

{ #category : 'tests' }
VGTiledSurfacePaintTest >> testASurfacePaintDecodesToAPaintThatSamplesTheSamePixels [
	"One entry out of the buffers and nothing else, which is what lets a test hold the layout
	 before a kernel exists. A surface paint decodes to a surface paint over a surface rebuilt
	 from the pixel buffer, and the two answer the same pixel everywhere a fill could ask: at
	 every pixel of the frame and outside the source on all four sides, where the extend mode
	 decides."

	| encoding decoded original margin |
	original := (self surfacePaintEntryOfFrame: self surfacePaintFrame) paint.
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self surfacePaintFrame.
	decoded := (encoding entryAt: 1) paint.
	self assert: decoded class equals: VGSurfacePaint.
	self assert: decoded coefficients equals: original coefficients.
	self assert: decoded extend equals: original extend.
	self assert: decoded surface extent equals: original surface extent.
	self assert: decoded surface format equals: original surface format.
	margin := self class pixelsSampledOutsideTheSource.
	margin negated to: self caseExtent y + margin do: [ :y |
		margin negated to: self caseExtent x + margin do: [ :x |
			self
				assert: (decoded
						 pixelIn: VGTiledFillEncoding targetFormat
						 atX: x
						 y: y)
					    = (original
							     pixelIn: VGTiledFillEncoding targetFormat
							     atX: x
							     y: y)
				description: x printString , '@' , y printString ] ]
]

{ #category : 'tests' }
VGTiledSurfacePaintTest >> testAnEncodedSurfacePaintCarriesEveryPixelOfItsSource [
	"The pixels of the source ride in a buffer of their own, row by row from its top left and
	 packed to its width, and the header of the entry names the first of them. A fill of any
	 other paint carries none at all, so the buffer of a frame with no surface paint in it is
	 empty."

	| entry encoding source offset |
	entry := self surfacePaintEntryOfFrame: self surfacePaintFrame.
	source := entry paint surface.
	encoding := self
		            encodingOfExtent: self caseExtent
		            drawnWith: self surfacePaintFrame.
	offset := encoding headers
		          at: VGTiledFillLayout pixelOffsetField.
	self assert: offset equals: 0.
	self
		assert: encoding sourcePixels size
		equals: source width * source height.
	0 to: source height - 1 do: [ :y |
		0 to: source width - 1 do: [ :x |
			self
				assert: (encoding sourcePixels at: offset + (y * source width) + x + 1)
				equals: (source pixelAtX: x y: y) ] ].
	self
		assert: (self
				 encodingOfExtent: self caseExtent
				 drawnWith: [ :context |
					 context sourceColorR: 0.2 g: 0.4 b: 0.9 a: 1.0.
					 context paint ]) sourcePixels size
		equals: 0
]

{ #category : 'tests' }
VGTiledSurfacePaintTest >> testEveryFrameOfMineDrawsOnTheDeviceWhatTheSoftwareBackendDraws [
	"The same gate over the frames of my own, which carry what the corpus does not: a source at
	 an offset, the four extend modes, a source inside a shaped clip and the source and clear
	 operators. The extend arithmetic of a surface runs on the device in single floats, so these
	 are the frames that say whether a pixel index off the end of a source reads the pixel the
	 oracle reads, or no pixel at all."

	| context |
	context := [ VkContext computeContext ]
		           on: Error
		           do: [ :failure | nil ].
	context ifNil: [ ^ self ].
	[ self surfacePaintFrameNames do: [ :name |
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
VGTiledSurfacePaintTest >> testEveryFrameOfMineDrawsTheSameBytesAsTheSoftwareBackend [
	"Every frame of my own through the tiles against the software backend: the plain one to one
	 fill, a source at an offset, the four extend modes, a shaped clip and the source and clear
	 operators. The oracle is the software backend, which held against live Cairo on the two
	 source cases of the corpus in phase one."

	self surfacePaintFrameNames do: [ :name |
		| draw |
		draw := self perform: name.
		self
			assert: (self tiledFormOfExtent: self caseExtent drawnWith: draw) bits
				    = (self softwareFormOfExtent: self caseExtent drawnWith: draw) bits
			description: name ]
]

{ #category : 'tests' }
VGTiledSurfacePaintTest >> testEveryFrameOfMineDrawsTheSameBytesFromTheBuffersAsFromItsOwnEntries [
	"The same frames drawn from the buffers alone against the frames drawn from the entries
	 themselves, which is what holds the pixel buffer and the decode of it to the layout: a
	 source rebuilt from the wrong run, at the wrong width or at the wrong offset shows here
	 before any device is asked."

	self surfacePaintFrameNames do: [ :name |
		| draw |
		draw := self perform: name.
		self
			assert: (self encodedFormOfExtent: self caseExtent drawnWith: draw) bits
				    = (self singleFloatFormOfExtent: self caseExtent drawnWith: draw) bits
			description: name ]
]

{ #category : 'tests' }
VGTiledSurfacePaintTest >> testEverySurfaceCaseOfTheCorpusDrawsOnTheDeviceWhatTheSoftwareBackendDraws [
	"The gate of this unit over the corpus: every case the subset draws that fills through a
	 surface paint, drawn on the device and by the software backend on the same frame, holds to
	 the tolerance the fill cases set. The pixels of the source travel to the device as the words
	 they are and are sampled there, so these are the cases that say whether the kernel reads the
	 pixel the oracle reads. One context draws all of them. A machine with no device holds
	 nothing."

	| context |
	context := [ VkContext computeContext ]
		           on: Error
		           do: [ :failure | nil ].
	context ifNil: [ ^ self ].
	[ self surfaceCasesDo: [ :case :draw |
		  self assertDeviceDrawsCase: case with: draw on: context ] ]
		ensure: [ context destroy ]
]

{ #category : 'tests' }
VGTiledSurfacePaintTest >> testEverySurfaceCaseOfTheCorpusDrawsTheSameBytesAsTheSoftwareBackend [
	"The gate of this unit on the corpus. The oracle is the software backend and not Cairo: that
	 backend already held against Cairo on all forty-one cases in phase one, so matching it here
	 is both necessary and sufficient."

	self surfaceCasesDo: [ :case :draw |
		self
			assert: (self tiledFormOfExtent: case extent drawnWith: draw) bits
				    = (self softwareFormOfExtent: case extent drawnWith: draw) bits
			description: case name ]
]

{ #category : 'tests' }
VGTiledSurfacePaintTest >> testEverySurfaceCaseOfTheCorpusDrawsTheSameBytesFromTheBuffersAsFromItsOwnEntries [
	"The same cases drawn from the buffers alone against the frames drawn from the entries
	 themselves, which holds the pixel buffer, the header field that names a source and the
	 decode of both back to a paint that samples the same pixels."

	self surfaceCasesDo: [ :case :draw |
		self
			assert: (self encodedFormOfExtent: case extent drawnWith: draw) bits
				    = (self singleFloatFormOfExtent: case extent drawnWith: draw) bits
			description: case name ]
]

{ #category : 'tests' }
VGTiledSurfacePaintTest >> testTheSourceRunsNameWhereEachEntryPixelsStartAndHowManyItHas [
	"The runs of source pixels of a frame, which is what VGTiledFillSources holds: one offset
	 an entry and the total after them, a run as long as the extent of the entry's own source and
	 none at all for an entry that paints from no surface, and every pixel of a run the pixel the
	 source carries at that place. A frame of three entries is enough to hold all three facts:
	 a solid fill between two surfaces makes the second source start after the first and not at
	 its own index."

	| surface entries sources pixels tile |
	tile := self surfaceTileOfExtent: self class smallTileExtent.
	surface := VGCairoImageSurface extent: self caseExtent.
	surface newContext
		sourceSurface: tile x: 0 y: 0;
		rectangleX: 0 y: 0 width: 8 height: 8;
		fill;
		sourceColorR: 0.1 g: 0.2 b: 0.3 a: 1.0;
		rectangleX: 8 y: 8 width: 8 height: 8;
		fill;
		sourceSurface: tile x: 4 y: 4;
		rectangleX: 16 y: 16 width: 8 height: 8;
		fill.
	entries := surface displayList entries collect: [ :each | each asTiledFill ].
	surface displayList reset.
	sources := VGTiledFillSources of: entries.
	self
		assert: sources offsets
		equals: {
				0.
				(tile width * tile height).
				(tile width * tile height).
				(2 * (tile width * tile height)) }.
	self assert: sources pixelCount equals: 2 * (tile width * tile height).
	pixels := WordArray new: sources pixelCount.
	sources writeInto: pixels.
	0 to: tile height - 1 do: [ :y |
		0 to: tile width - 1 do: [ :x |
			| word |
			word := tile pixelAtX: x y: y.
			self
				assert: (pixels at: y * tile width + x + 1)
				equals: word.
			self
				assert: (pixels at: sources offsets third + (y * tile width) + x + 1)
				equals: word ] ]
]

{ #category : 'tests - subset' }
VGTiledSurfacePaintTest >> testTheSubsetHoldsAFillOfASurfaceOfTheTargetFormat [
	"What this unit widens the subset by. A surface paint is the pixels of another surface under
	 a matrix, an extend mode, a clip and an operator, and the pixels travel as they stand, so
	 the source has to be of the one format a frame is encoded for."

	| entry |
	entry := self surfacePaintEntryOfFrame: self surfacePaintFrame.
	self
		assert: entry paint surface format
		equals: VGTiledFillEncoding targetFormat.
	self assert: (VGTiledFillRasteriser supportsPaint: entry paint).
	self assert: (VGTiledFillRasteriser supportsEntry: entry).
	self assert: (VGTiledFillRasteriser supports:
			 (self displayListOfExtent: self caseExtent drawnWith: self surfacePaintFrame))
]
