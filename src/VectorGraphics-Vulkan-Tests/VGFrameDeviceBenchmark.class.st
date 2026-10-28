"
I measure what a whole window sized frame costs on the Vulkan device against what the same frame costs on the software backend, which is the question the gate of unit 2.3 leaves open: the tiled rasteriser is gated on conformance cases of sixty four pixels square, and a frame of a real window is two hundred times that area.
Two frames are measured, both of them inside the subset the device draws today: the background frame, one solid fill over the whole extent, and the cards frame, the twelve cards of VGFrameProfile with a rectangular clip, a vertical gradient and a stroked border each.
Three times a frame are recorded without a device: the encoding, the SPIR-V the kernel builds for the tile extent, and the counts of the frame. The fourth, the whole dispatch, needs one, and it holds the build, the upload, the wait and the readback. measureSoftwareFrame adds the fifth, and pixelsEqual records that both paths drew the same bytes, because a fast frame that draws the wrong picture is not a measurement.
What the device cannot draw at all is counted by VGTiledFillSupportCensus and not here.
"
Class {
	#name : 'VGFrameDeviceBenchmark',
	#superclass : 'Object',
	#instVars : [
		'frameName',
		'repeats',
		'encoding',
		'uploadedByteCount',
		'milliseconds',
		'deviceForm',
		'pixelsEqual',
		'deviceName',
		'unavailableReason'
	],
	#category : 'VectorGraphics-Vulkan-Tests-Budget',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Budget'
}

{ #category : 'frames' }
VGFrameDeviceBenchmark class >> cardBoxAt: anIndex [
	"Where the card of this index sits. The grid is the one VGFrameProfile lays its own cards out
	 in, read from its constants rather than restated, so that the frame the device draws covers
	 the pixels the profiled frame covers."

	| gap columns column row |
	gap := VGFrameProfile cardGap.
	columns := self extentOfItsFrames x // (VGFrameProfile cardExtent x + gap)
	           max: 1.
	column := anIndex - 1 \\ columns.
	row := anIndex - 1 // columns.
	^ gap + (column * (VGFrameProfile cardExtent x + gap))
	  @ (gap + (row * (VGFrameProfile cardExtent y + gap)))
	  extent: VGFrameProfile cardExtent
]

{ #category : 'constants' }
VGFrameDeviceBenchmark class >> defaultRepeats [
	"Three passes a frame, the first of them thrown away as warm-up. A whole frame costs tens of
	 milliseconds on the device and seconds on the software path, so the ten repeats unit 2.1
	 measures a buffer copy over would buy a little less noise for half a minute of waiting."

	^ 3
]

{ #category : 'frames' }
VGFrameDeviceBenchmark class >> drawBackgroundOn: aContext using: aKit [
	"The background of the reference scene in the colour it uses, filled as a rectangle and not
	 painted, because a fill is what the subset holds. The kit is not asked for anything here:
	 a colour and a rectangle are verbs of either side's context, which is what makes this frame
	 the cheapest one the budget measures."

	aContext sourceColor: Color veryVeryLightGray.
	aContext rectangle: (0 @ 0 extent: self extentOfItsFrames).
	aContext fill
]

{ #category : 'frames' }
VGFrameDeviceBenchmark class >> drawBlockNamed: aSymbol [
	"The named frame drawn with this project's own classes, which is what a device measurement
	 draws."

	^ self drawBlockNamed: aSymbol using: VGFrameDrawingKit ours
]

{ #category : 'frames' }
VGFrameDeviceBenchmark class >> drawBlockNamed: aSymbol using: aKit [
	"A one argument block that draws the named frame on a context, with the classes of that kit.
	 A name no frame answers is an error and not an empty frame: an empty frame touches no tile,
	 dispatches nothing, and would be reported as the fastest measurement of the set."

	aSymbol = #background ifTrue: [
		^ [ :context | self drawBackgroundOn: context using: aKit ] ].
	aSymbol = #cards ifTrue: [
		^ [ :context | self drawCardsOn: context using: aKit ] ].
	aSymbol = #reference ifTrue: [
		^ [ :context | self drawReferenceOn: context using: aKit ] ].
	^ self error: 'no frame of that name'
]

{ #category : 'frames' }
VGFrameDeviceBenchmark class >> drawCardsOn: aContext using: aKit [
	"The background, and then every card: clipped to itself, filled with a vertical gradient from
	 white to light blue and bordered in grey, which are the colours and the width VGFrameProfile
	 gives its own cards. The clip is kept although the fill is the shape of it, because a card
	 of a real tool clips what it holds and the clip is what the encoding carries a rectangle
	 for. The gradient is the one class of this frame that differs between the two sides, so the
	 kit answers it."

	self drawBackgroundOn: aContext using: aKit.
	1 to: VGFrameProfile referenceCards do: [ :index |
		| box |
		box := self cardBoxAt: index.
		aContext saveState.
		aContext rectangle: box.
		aContext clip.
		aContext sourcePattern: (aKit
				 linearGradientFrom: box topLeft
				 to: box bottomLeft
				 addStopsFrom: {
						 (0 -> Color white).
						 (1 -> Color lightBlue) }).
		aContext rectangle: box.
		aContext fill.
		aContext sourceColor: Color gray.
		aContext strokeSize: VGFrameProfile cardBorderWidth.
		aContext rectangle: box.
		aContext stroke.
		aContext restoreState ]
]

{ #category : 'frames' }
VGFrameDeviceBenchmark class >> drawReferenceOn: aContext using: aKit [
	"The frame unit 1.11 profiles, drawn through the kit's renderer onto the surface that context
	 records on: eight hundred by six hundred, with gradients, strokes, glyphs and blits in it,
	 which is the frame a backend is really asked to draw. A scene draws on a canvas and not on a
	 context, so the canvas is built over the surface the context was made for and the entries
	 reach the one display list either way.
	 The scene is laid out through the kit's renderer class, because a text span measured on one
	 backend keeps that backend's scaled font and the other backend cannot draw it."

	| canvas |
	canvas := aKit canvasOn: aContext surface.
	canvas clippingRectangle: (0 @ 0 extent: self extentOfItsFrames).
	(VGFrameProfile new sceneForRendererClass: aKit rendererClass)
		aeFullDrawOn: canvas
]

{ #category : 'constants' }
VGFrameDeviceBenchmark class >> extentOfItsFrames [
	"The extent unit 1.11 profiles, so that the device, the software path and the numbers already
	 in the plan all speak about one picture."

	^ VGFrameProfile referenceExtent
]

{ #category : 'instance creation' }
VGFrameDeviceBenchmark class >> frameName: aSymbol [
	^ self frameName: aSymbol repeats: self defaultRepeats
]

{ #category : 'instance creation' }
VGFrameDeviceBenchmark class >> frameName: aSymbol repeats: anInteger [
	^ self new setFrameName: aSymbol repeats: anInteger
]

{ #category : 'constants' }
VGFrameDeviceBenchmark class >> frameNames [
	"The frames I measure, cheapest first. The last of them is the scene unit 1.11 profiles
	 itself, which unit 2.7 made drawable on the device."

	^ #( #background #cards #reference )
]

{ #category : 'instance creation' }
VGFrameDeviceBenchmark class >> onTheBackgroundFrame [
	"One solid fill over the whole extent: the cheapest frame the subset can draw, and the one
	 that says what a tile costs where the coverage of every pixel is full and the paint is read
	 once."

	^ self frameName: #background
]

{ #category : 'instance creation' }
VGFrameDeviceBenchmark class >> onTheCardsFrame [
	"The reference scene of unit 1.11 with the two things the device cannot draw yet taken out of
	 it: the corners of a card are square, so its clip is a rectangle, and the cards carry no
	 labels, so the frame holds no glyph blit. What is left is the work a real window of lists
	 and palettes is mostly made of."

	^ self frameName: #cards
]

{ #category : 'instance creation' }
VGFrameDeviceBenchmark class >> onTheReferenceFrame [
	"The reference scene of unit 1.11 as it really is, with its rounded cards, its gradients and
	 its labels: the first frame of a real window the device draws whole, which is what unit 2.7
	 bought."

	^ self frameName: #reference
]

{ #category : 'reporting' }
VGFrameDeviceBenchmark class >> phaseLabels [
	"The phases a frame is measured in, in the order a frame pays them, each with the label the
	 report shows. A phase that was not measured is left out of the report, so this table is the
	 only place that names one. The module build is paid once a session since the kernel cached
	 it by tile extent, and the label says so, because a reader adding the rows up would
	 otherwise count that build against every frame."

	^ {
		  (#encode -> 'encode').
		  (#buildSpirv -> 'build SPIR-V, once a session').
		  (#dispatch -> 'dispatch').
		  (#software -> 'software frame') }
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> binnedEntryCount [
	^ encoding ifNotNil: [ encoding binnedEntryCount ]
]

{ #category : 'reporting' }
VGFrameDeviceBenchmark >> countRows [
	"What the frame is and what it weighs, which is known without a device."

	| rows |
	rows := OrderedCollection new.
	rows add: 'frame' -> frameName asString.
	rows add: 'extent'
		-> (self extent x printString , ' x ' , self extent y printString
			 , ' pixels').
	rows add: 'repeats' -> repeats printString.
	encoding ifNotNil: [
		rows add: 'tiles touched' -> self touchedTileCount printString.
		rows add: 'entries drawn' -> self entryCount printString.
		rows add: 'entries binned' -> self binnedEntryCount printString ].
	uploadedByteCount ifNotNil: [
		rows add: 'uploaded' -> (uploadedByteCount printString , ' bytes') ].
	^ rows asArray
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> deviceForm [
	^ deviceForm
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> deviceMilliseconds [
	^ self millisecondsOf: #dispatch
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> deviceName [
	^ deviceName
]

{ #category : 'reporting' }
VGFrameDeviceBenchmark >> deviceRows [
	"Which device drew the frame, or why none did, and whether what came back is the picture the
	 software path draws."

	| rows |
	rows := OrderedCollection new.
	self isAvailable
		ifTrue: [ deviceName ifNotNil: [ rows add: 'device' -> deviceName ] ]
		ifFalse: [
			rows add: 'device' -> 'none'.
			rows add: 'reason' -> unavailableReason ].
	pixelsEqual ifNotNil: [
		rows add: 'same pixels' -> pixelsEqual printString ].
	^ rows asArray
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> encodeMilliseconds [
	^ self millisecondsOf: #encode
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> encoding [
	^ encoding
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> entryCount [
	^ encoding ifNotNil: [ encoding entryCount ]
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> extent [
	^ self class extentOfItsFrames
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> frameName [
	^ frameName
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> hasRun [
	"Whether the frame was dispatched on a device. The encoding is measured without one, so a
	 benchmark can carry times and counts and still not have run."

	^ self deviceMilliseconds isNotNil
]

{ #category : 'inspector' }
VGFrameDeviceBenchmark >> inspectorBenchmark: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Benchmark'>
	"What one whole frame costs on the device against what it costs on the software path. Every
	 row is read from the report, which is computed from the measurement, so the tab cannot show
	 a time the benchmark did not measure. Nothing is measured here: opening the tab opens no
	 device."

	^ aBuilder newTable
		  items: self reportRows;
		  addColumn:
			  (SpStringTableColumn
				   title: 'Measurement'
				   evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  yourself
]

{ #category : 'inspector' }
VGFrameDeviceBenchmark >> inspectorBenchmarkContext: aContext [
	"A benchmark with no frame named has nothing to report."

	aContext active: frameName isNotNil
]

{ #category : 'inspector' }
VGFrameDeviceBenchmark >> inspectorDeviceFrame: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Device frame'>
	"The picture the device drew, so that a frame measured fast and drawn wrong is visible as
	 such and not only reported as a false in the rows above."

	^ aBuilder newImage image: deviceForm
]

{ #category : 'inspector' }
VGFrameDeviceBenchmark >> inspectorDeviceFrameContext: aContext [
	"A benchmark that has not been dispatched has no picture of its own."

	aContext active: deviceForm isNotNil
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> isAvailable [
	"Whether this machine could be measured on a device at all. A device that is missing, or a
	 driver that faults, records why instead."

	^ unavailableReason isNil
]

{ #category : 'measuring' }
VGFrameDeviceBenchmark >> measureEncoding [
	"Everything a frame costs off the device: the encoding of its entries and the SPIR-V the
	 kernel builds for the tile extent. The module is built here and not read from the cache,
	 because what is worth reporting is the build a session pays once and a frame used to pay
	 every time. The encoding itself is kept, so that a machine with no driver still reports what
	 the frame weighs and what it would dispatch."

	| surface |
	surface := self newSurface.
	milliseconds
		at: #encode
		put: (self millisecondsPerRepeatOf: [
				 VGTiledFillEncoding of: surface displayList extent: self extent ]).
	encoding := VGTiledFillEncoding of: surface displayList extent: self extent.
	milliseconds
		at: #buildSpirv
		put: (self millisecondsPerRepeatOf: [
				 (VGTiledFillKernel onTileExtent: encoding grid tileExtent) spirv ]).
	^ self
]

{ #category : 'running' }
VGFrameDeviceBenchmark >> measureOn: aSession [
	"One frame through the dispatch, averaged over the repeats. Everything draw:into: does is
	 inside the number — every binding uploaded, one workgroup dispatched a tile, the wait, and
	 the target read back — because that is what a frame really costs and no part of it can be
	 skipped by a caller. The module, the pipeline and the buffers are the session's and are
	 built on the first of the repeats, which is why a warm-up frame is drawn before the clock
	 starts: a resident frame is what a tool really pays after the first.
	 The pixels are packed by the backend itself, which is how a drained surface hands a frame to
	 one, and the form is kept so that the software measurement has something to compare."

	| surface pixels backend dispatch |
	deviceName := aSession contextOrNil chosenDeviceName.
	surface := self newSurface.
	encoding := VGTiledFillEncoding of: surface displayList extent: self extent.
	surface displayList reset.
	backend := VGVulkanBackend new.
	pixels := backend pixelsOf: surface.
	dispatch := aSession dispatchForEncoding: encoding.
	dispatch draw: encoding into: pixels.
	milliseconds
		at: #dispatch
		put: (self millisecondsPerRepeatOf: [ dispatch draw: encoding into: pixels ]).
	uploadedByteCount := dispatch bytes values inject: 0 into: [ :sum :each |
		                     sum + each size ].
	backend write: pixels into: surface.
	deviceForm := surface asForm
]

{ #category : 'measuring' }
VGFrameDeviceBenchmark >> measureSoftwareFrame [
	"The other side of the comparison, measured on this machine and in this session rather than
	 quoted from unit 1.11, and drained by the failover backend by name: a preference set
	 elsewhere in the session would otherwise send this frame to the device and the comparison
	 would be of the device with itself.
	 The two pictures are compared here and the software one is not kept, because what the
	 comparison is read for is whether the device drew the frame and not what software drew."

	| surface |
	surface := self newSurfaceOnBackend: VGBackend failover.
	milliseconds at: #software put: (self millisecondsDuring: [ surface flush ]).
	deviceForm ifNotNil: [ pixelsEqual := deviceForm bits = surface asForm bits ].
	^ self
]

{ #category : 'reporting' }
VGFrameDeviceBenchmark >> millisecondStringFor: aNumber [
	^ (aNumber asFloat printShowingDecimalPlaces:
		   VGVulkanRoundTrip millisecondDecimalPlaces) , ' ms'
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> milliseconds [
	^ milliseconds
]

{ #category : 'measuring' }
VGFrameDeviceBenchmark >> millisecondsDuring: aBlock [
	"The time one pass of the block took. A software frame of this size costs a second or two, so
	 it is measured once: a second pass would buy three decimal places of a number read for its
	 order of magnitude."

	| start |
	start := Time microsecondClockValue.
	aBlock value.
	^ (Time microsecondClockValue - start
	   / VGVulkanRoundTrip microsecondsPerMillisecond) asFloat
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> millisecondsOf: aPhase [
	"What one pass of the named phase cost, or nil where the phase was not measured. The phases
	 are kept in one table rather than in a variable each, so that the report walks them and
	 neither the rows nor the view name a phase the measurement does not have."

	^ milliseconds at: aPhase ifAbsent: [ nil ]
]

{ #category : 'measuring' }
VGFrameDeviceBenchmark >> millisecondsPerRepeatOf: aBlock [
	"One pass is run and thrown away before the clock starts, because the first dispatch of a
	 session pays for the first touch of the pages and the warm-up of the pipeline. The
	 microsecond clock is read rather than millisecondsToRun:, since the encoding of a frame can
	 finish inside a millisecond."

	| start |
	aBlock value.
	start := Time microsecondClockValue.
	repeats timesRepeat: [ aBlock value ].
	^ (Time microsecondClockValue - start / repeats
	   / VGVulkanRoundTrip microsecondsPerMillisecond) asFloat
]

{ #category : 'running' }
VGFrameDeviceBenchmark >> newSession [
	"A device session of my own, or nil with the reason recorded. A machine with no driver, no
	 device or a device that refuses the features this project asks for records the reason here,
	 and the gate reports the machine rather than failing.
	 The session is mine and not VGVulkanDeviceSession default, because what I measure includes
	 the cost of opening a device and the first frame of a session: a benchmark that borrowed the
	 image's own session would measure a device somebody else had already opened."

	| session |
	session := VGVulkanDeviceSession new.
	session contextOrNil ifNotNil: [ ^ session ].
	unavailableReason := session unavailableReason.
	^ nil
]

{ #category : 'measuring' }
VGFrameDeviceBenchmark >> newSurface [
	"A surface of the frame extent with the frame recorded on it and nothing drained: the
	 encoding of the display list is what is measured next."

	^ self newSurfaceOnBackend: nil
]

{ #category : 'measuring' }
VGFrameDeviceBenchmark >> newSurfaceOnBackend: aBackendOrNil [
	"A surface of the frame extent with the frame recorded on it, to be drained by the given
	 backend or by whichever one selection chose. The backend is named before the frame is drawn,
	 because the setter flushes what is already recorded: naming it afterwards drains the frame
	 on the backend being replaced and leaves an empty list behind, which measures as a frame
	 drawn in two microseconds."

	| surface |
	surface := VGCairoImageSurface extent: self extent.
	aBackendOrNil ifNotNil: [ surface backend: aBackendOrNil ].
	(self class drawBlockNamed: frameName) value: surface newContext.
	^ surface
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> pixelsEqual [
	^ pixelsEqual
]

{ #category : 'printing' }
VGFrameDeviceBenchmark >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: frameName asString.
	self isAvailable ifFalse: [
		^ aStream
			  nextPutAll: ', ';
			  nextPutAll: unavailableReason;
			  nextPut: $) ].
	self hasRun ifFalse: [ ^ aStream nextPutAll: ', not dispatched)' ].
	aStream
		nextPutAll: ', ';
		nextPutAll: (self millisecondStringFor: self deviceMilliseconds);
		nextPut: $)
]

{ #category : 'measuring' }
VGFrameDeviceBenchmark >> reasonFrom: anError [
	"A driver fault arrives as several classes of error and not all of them carry a message, so
	 the class name stands where there is no text."

	^ anError messageText ifNil: [ anError class name ]
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> repeats [
	^ repeats
]

{ #category : 'reporting' }
VGFrameDeviceBenchmark >> reportRows [
	"Label and value for everything measured, so that the view and the printed form read one
	 report and neither restates the arithmetic."

	^ self countRows , self timeRows , self deviceRows
]

{ #category : 'running' }
VGFrameDeviceBenchmark >> run [
	"Measure the frame off the device and then on it, or record why the device cannot be
	 measured. Answers self in both cases, because a machine with no device still has a report to
	 give and that report is not a failure."

	| session |
	self measureEncoding.
	session := self newSession.
	session ifNil: [ ^ self ].
	[
	[ self measureOn: session ]
		on: Error
		do: [ :each | unavailableReason := self reasonFrom: each ] ] ensure: [
		session releaseDevice ].
	^ self
]

{ #category : 'initialization' }
VGFrameDeviceBenchmark >> setFrameName: aSymbol repeats: anInteger [
	frameName := aSymbol.
	repeats := anInteger.
	milliseconds := Dictionary new
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> softwareMilliseconds [
	^ self millisecondsOf: #software
]

{ #category : 'reporting' }
VGFrameDeviceBenchmark >> speedupOverSoftware [
	"How many times faster the device drew this frame than the software path did, or nil while
	 either number is missing."

	(self hasRun and: [ self softwareMilliseconds isNotNil ]) ifFalse: [ ^ nil ].
	^ self softwareMilliseconds / self deviceMilliseconds
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> spirvMilliseconds [
	^ self millisecondsOf: #buildSpirv
]

{ #category : 'reporting' }
VGFrameDeviceBenchmark >> timeRows [
	"One row for every phase that was measured, in the order a frame pays them, and the factor
	 between the device and the software path where both were measured."

	| rows |
	rows := OrderedCollection new.
	self class phaseLabels do: [ :each |
		(self millisecondsOf: each key) ifNotNil: [ :measured |
			rows add: each value -> (self millisecondStringFor: measured) ] ].
	self speedupOverSoftware ifNotNil: [ :factor |
		rows add: 'faster by'
			-> ((factor asFloat printShowingDecimalPlaces: 1) , ' times') ].
	^ rows asArray
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> touchedTileCount [
	^ encoding ifNotNil: [ encoding touchedTileCount ]
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> unavailableReason [
	^ unavailableReason
]

{ #category : 'accessing' }
VGFrameDeviceBenchmark >> uploadedByteCount [
	^ uploadedByteCount
]
