"
I am unit 7.6's measurement: the path that ends on the device against the path that ends in the host's own pixels, on the three frames of VGFrameDeviceBenchmark, at the extent those frames are drawn at and at the extent a window uses. Both paths draw through one dispatch a frame, alternating round by round, so neither is measured on a device state the other warmed. I time no window: the swapchain of this project is created FIFO, so a presented frame is pinned to the refresh period and would measure the display rather than the work; what a real window does is shown by VGVulkanPresentRendererExamples class >> openWindowAndPresentTheBenchmarkFrames instead. run answers me whether or not a device answers, and unavailableReason says why where one does not. comparisonRows holds one VGPresentPathComparison a frame an extent a path.
"
Class {
	#name : 'VGPresentPathBenchmark',
	#superclass : 'Object',
	#instVars : [
		'roundCount',
		'timedDrawCount',
		'rows',
		'unavailableReason',
		'backend',
		'hostCopies'
	],
	#category : 'VectorGraphics-Benchmarks',
	#package : 'VectorGraphics-Benchmarks'
}

{ #category : 'constants' }
VGPresentPathBenchmark class >> defaultRoundCount [
	^ 3
]

{ #category : 'constants' }
VGPresentPathBenchmark class >> defaultTimedDrawCount [
	^ 40
]

{ #category : 'constants' }
VGPresentPathBenchmark class >> discardedDrawCount [
	"The draws at the head of a pass that are thrown away. The first draw of a pass pays for
	 whatever the other path left in the buffers and in the caches, which is the one thing an
	 alternating comparison must not carry into its figures."
	^ 1
]

{ #category : 'constants' }
VGPresentPathBenchmark class >> extents [
	"The extents every frame is measured at: the one the device benchmark draws its frames at,
	 so every figure is comparable with units 3.0, 3.8 and 3.9, and the one a window uses."
	^ { VGFrameDeviceBenchmark extentOfItsFrames. self windowExtent }
]

{ #category : 'instance creation' }
VGPresentPathBenchmark class >> onTheThreeFrames [
	"The verdict run: three rounds of forty timed draws a path, which is the protocol unit 3.9
	 measured with."
	^ self rounds: self defaultRoundCount timedDraws: self defaultTimedDrawCount
]

{ #category : 'constants' }
VGPresentPathBenchmark class >> pathNames [
	"The two paths compared, in the order a round draws them."
	^ { self presentedPathName. self readBackPathName }
]

{ #category : 'constants' }
VGPresentPathBenchmark class >> pixelsOfStageName [
	"The stage where the readback path packs the pixels of the target into a ByteArray of their
	 own, which is a copy the device never sees."
	^ #pixelsOf
]

{ #category : 'constants' }
VGPresentPathBenchmark class >> presentedPathName [
	"The path that ends on the device, in an image a swapchain can present."
	^ #presented
]

{ #category : 'constants' }
VGPresentPathBenchmark class >> readBackPathName [
	"The path that ends in the host's own pixels, which is what a surface and an SDL texture
	 need."
	^ #readBack
]

{ #category : 'instance creation' }
VGPresentPathBenchmark class >> rounds: aRoundCount timedDraws: aDrawCount [
	"A benchmark of that many rounds of that many timed draws a path. A gate asks for a short
	 one, since the shape of a run does not depend on how many draws it holds."
	^ self new setRounds: aRoundCount timedDraws: aDrawCount
]

{ #category : 'constants' }
VGPresentPathBenchmark class >> windowExtent [
	"The second extent every frame is measured at: the one a real window uses here, where the
	 destination this phase stopped carrying is eight megabytes a frame rather than the 1.83 of
	 the benchmark extent."
	^ 1920 @ 1080
]

{ #category : 'constants' }
VGPresentPathBenchmark class >> writeIntoStageName [
	"The stage where the readback path writes the frame back into the rows of the target, the
	 second copy the device never sees."
	^ #writeInto
]

{ #category : 'accessing' }
VGPresentPathBenchmark >> comparisonOfFrameNamed: aName at: anExtent path: aPathName [
	"The one comparison of that frame at that extent on that path, or nil where a run stopped
	 before it reached it."
	^ rows
		  detect: [ :each |
			  each frameName = aName and: [
				  each extent = anExtent and: [ each pathName = aPathName ] ] ]
		  ifNone: [ nil ]
]

{ #category : 'accessing' }
VGPresentPathBenchmark >> comparisonRows [
	"One comparison a frame an extent a path."
	^ rows asArray
]

{ #category : 'running' }
VGPresentPathBenchmark >> comparisonsOfFrameNamed: aName at: anExtent [
	"One comparison a path, keyed by the name of that path."
	| answer |
	answer := Dictionary new.
	self class pathNames do: [ :pathName |
		answer
			at: pathName
			put:
			(VGPresentPathComparison
				 frameName: aName
				 extent: anExtent
				 path: pathName) ].
	^ answer
]

{ #category : 'running' }
VGPresentPathBenchmark >> discardDrawsOf: aBlock [
	"The draws at the head of a round, which are thrown away. A round follows the other path,
	 and what that path left in the buffers, in the caches and in the host's own heap is paid by
	 the draw after it and by no other."
	self class discardedDrawCount timesRepeat: [ aBlock value ]
]

{ #category : 'running' }
VGPresentPathBenchmark >> drawsOf: anEncoding through: aDispatch endingIn: anImage orInto: aSurface [
	"The one draw each path pays, as a block of no arguments, so that a round times the two of
	 them the same way. The presented path ends in the image and names no destination at all;
	 the readback path is the frame VGVulkanBackend draws into a surface."
	^ Dictionary new
		  at: self class presentedPathName
		  put: [ aDispatch draw: anEncoding endingIn: anImage ];
		  at: self class readBackPathName
		  put: [ self readBack: anEncoding through: aDispatch into: aSurface ];
		  yourself
]

{ #category : 'accessing' }
VGPresentPathBenchmark >> drawsOfARound [
	"The draws of one round of one path that are both timed and recorded in its stages. The
	 discarded draws are neither: the tables of stages are emptied after them."
	^ timedDrawCount
]

{ #category : 'running' }
VGPresentPathBenchmark >> encodingOf: aSurface at: anExtent [
	"The frame of that surface written out as buffers, once for both paths: what they differ by
	 is where the frame ends, not how it is encoded. The display list is reset afterwards, so
	 that reading the pixels of the surface does not replay the frame on the software backend."
	| encoding |
	encoding := VGTiledFillEncoding of: aSurface displayList extent: anExtent.
	aSurface displayList reset.
	^ encoding
]

{ #category : 'accessing' }
VGPresentPathBenchmark >> factorOf: aComparison [
	"How many times faster the presented path is than the readback path on that frame, read off
	 the two fastest draws each of them ever paid. Nil where either side has nothing to divide,
	 so a run that stopped early reports a gap rather than a figure it did not measure."
	| other mine |
	other := self readBackOf: aComparison.
	other ifNil: [ ^ nil ].
	mine := aComparison minimumMicroseconds.
	(mine isNil or: [ mine = 0 ]) ifTrue: [ ^ nil ].
	^ other minimumMicroseconds ifNotNil: [ :theirs | theirs / mine ]
]

{ #category : 'printing' }
VGPresentPathBenchmark >> factorStringOf: aComparison [
	"The verdict of one frame, in times rather than in milliseconds, since that is what unit 7.6
	 asks: how much of a frame the host copies and the readback were."
	^ (self factorOf: aComparison)
		  ifNil: [ '-' ]
		  ifNotNil: [ :factor |
		  (factor asFloat printShowingDecimalPlaces: 2) , ' times' ]
]

{ #category : 'accessing' }
VGPresentPathBenchmark >> hasRun [
	"Whether anything was measured. A machine with no device answers no rows and a reason."
	^ rows isNotEmpty
]

{ #category : 'running' }
VGPresentPathBenchmark >> hostCopiesOf: aPathName [
	"The copies that path made in the host during this round, summed by stage. Made on the
	 first copy of that path and empty for a path that makes none."
	^ hostCopies at: aPathName ifAbsentPut: [ Dictionary new ]
]

{ #category : 'running' }
VGPresentPathBenchmark >> imageOfExtent: anExtent on: aSession [
	"The image a presented frame ends in: of the format a frame is encoded for and written by
	 the copy of the dispatch. Nothing reads it here — what a swapchain does with such an image
	 is unit 7.4's — so it is a transfer destination and nothing else."
	^ VkImage
		  on: aSession context device
		  format: VkFormat b8g8r8a8Unorm
		  extent: anExtent
		  usage: VkImageUsage transferDstBit
]

{ #category : 'views' }
VGPresentPathBenchmark >> inspectorDraws: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Draws'>
	"Every comparison of the run, both paths among them, with the fastest draw beside the middle
	 one and beside the first that was timed. The three read together say how much of a figure
	 is the work and how much is the state the image was in when it was measured."
	^ aBuilder newTable
		  items: self comparisonRows;
		  addColumn:
			  (SpStringTableColumn title: 'Frame' evaluated: [ :each |
					   each frameName ]);
		  addColumn: (SpStringTableColumn title: 'Extent' evaluated: [ :each |
					   each extent printString ]);
		  addColumn:
			  (SpStringTableColumn title: 'Path' evaluated: [ :each |
					   each pathName ]);
		  addColumn:
			  (SpStringTableColumn title: 'Fastest ms' evaluated: [ :each |
					   each fastestMillisecondString ]);
		  addColumn:
			  (SpStringTableColumn title: 'Median ms' evaluated: [ :each |
					   each medianMillisecondString ]);
		  addColumn:
			  (SpStringTableColumn title: 'First ms' evaluated: [ :each |
					   each firstDrawMillisecondString ]);
		  yourself
]

{ #category : 'inspector' }
VGPresentPathBenchmark >> inspectorDrawsContext: aContext [
	"A benchmark that measured nothing has no draws to show."
	aContext active: rows isNotEmpty
]

{ #category : 'views' }
VGPresentPathBenchmark >> inspectorVerdict: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Verdict'>
	"The two paths side by side, one row a frame an extent, read off the fastest draw each of
	 them ever paid. The factor is computed from those two figures and from nothing else, so the
	 tab cannot claim a speed the run did not measure. Nothing is measured here: opening the tab
	 opens no device."
	^ aBuilder newTable
		  items: self presentedComparisons;
		  addColumn:
			  (SpStringTableColumn title: 'Frame' evaluated: [ :each |
					   each frameName ]);
		  addColumn: (SpStringTableColumn title: 'Extent' evaluated: [ :each |
					   each extent printString ]);
		  addColumn:
			  (SpStringTableColumn title: 'Presented ms' evaluated: [ :each |
					   each fastestMillisecondString ]);
		  addColumn:
			  (SpStringTableColumn title: 'Read back ms' evaluated: [ :each |
					   self readBackStringOf: each ]);
		  addColumn:
			  (SpStringTableColumn title: 'Faster by' evaluated: [ :each |
					   self factorStringOf: each ]);
		  yourself
]

{ #category : 'inspector' }
VGPresentPathBenchmark >> inspectorVerdictContext: aContext [
	"A benchmark that measured nothing has no verdict to show."
	aContext active: rows isNotEmpty
]

{ #category : 'accessing' }
VGPresentPathBenchmark >> isAvailable [
	"Whether this machine could be measured on a device at all."
	^ unavailableReason isNil
]

{ #category : 'running' }
VGPresentPathBenchmark >> measureFrameNamed: aName at: anExtent on: aSession [
	"One frame at one extent on both paths. The frame is encoded once, outside every timing:
	 what is compared is the device trip and the host copies around it, not the binning of a
	 display list, which units 3.0 and 3.8 already measure. Both paths draw through the one
	 dispatch of that tile extent and alternate round by round, so neither is measured on a
	 device the other warmed.
	 A round discards its first draws, then empties both tables of stages, then times the rest:
	 each table sums the draws it was given, so a table that was not emptied here would hold the
	 draws of the other path and the discarded draws of this one beside the timed ones."
	| surface encoding dispatch image comparisons draws |
	surface := self surfaceOfFrameNamed: aName at: anExtent.
	encoding := self encodingOf: surface at: anExtent.
	dispatch := aSession dispatchForEncoding: encoding.
	image := self imageOfExtent: anExtent on: aSession.
	comparisons := self comparisonsOfFrameNamed: aName at: anExtent.
	draws := self
		         drawsOf: encoding
		         through: dispatch
		         endingIn: image
		         orInto: surface.
	[
	1 to: roundCount do: [ :round |
		self class pathNames do: [ :pathName |
			self discardDrawsOf: (draws at: pathName).
			dispatch recordStages.
			hostCopies := Dictionary new.
			(comparisons at: pathName)
				addRound: (self timedDrawsOf: (draws at: pathName))
				stages: (self stagesOf: dispatch on: pathName) ] ] ] ensure: [
		image destroy ].
	rows addAll: (self class pathNames collect: [ :each | comparisons at: each ])
]

{ #category : 'running' }
VGPresentPathBenchmark >> microsecondsOf: aBlock [
	"The wall clock of one evaluation. The clock is read twice a draw, which is why only a
	 benchmark asks a dispatch to record its stages."
	| started |
	started := Time microsecondClockValue.
	aBlock value.
	^ Time microsecondClockValue - started
]

{ #category : 'accessing' }
VGPresentPathBenchmark >> presentedComparisons [
	"One comparison a frame an extent: the presented side of each pair, which is what a verdict
	 is read along."
	^ self comparisonRows select: [ :each |
		  each pathName = self class presentedPathName ]
]

{ #category : 'printing' }
VGPresentPathBenchmark >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ' ';
		print: roundCount;
		nextPutAll: ' x ';
		print: timedDrawCount.
	unavailableReason ifNotNil: [ :reason |
		aStream
			nextPutAll: ' unavailable: ';
			nextPutAll: reason ]
]

{ #category : 'running' }
VGPresentPathBenchmark >> readBack: anEncoding through: aDispatch into: aSurface [
	"The frame as VGVulkanBackend draws a recorded one into a surface: the pixels of the target
	 packed into a ByteArray of their own, the frame dispatched into it, and the pixels written
	 back into the rows of the target. The two host copies are timed here and nowhere else,
	 because they are the part of this path the device never sees."
	| pixels |
	pixels := self
		          timed: self class pixelsOfStageName
		          of: self class readBackPathName
		          during: [ backend pixelsOf: aSurface ].
	aDispatch draw: anEncoding into: pixels.
	self
		timed: self class writeIntoStageName
		of: self class readBackPathName
		during: [ backend write: pixels into: aSurface ]
]

{ #category : 'accessing' }
VGPresentPathBenchmark >> readBackOf: aComparison [
	"The comparison of the other path on the same frame at the same extent."
	^ self
		  comparisonOfFrameNamed: aComparison frameName
		  at: aComparison extent
		  path: self class readBackPathName
]

{ #category : 'reporting' }
VGPresentPathBenchmark >> readBackStringOf: aComparison [
	"The fastest readback draw of the same frame, printed, or a dash where a run stopped before
	 it reached that side of the pair."
	^ (self readBackOf: aComparison)
		  ifNil: [ '-' ]
		  ifNotNil: [ :other | other fastestMillisecondString ]
]

{ #category : 'running' }
VGPresentPathBenchmark >> run [
	"Every frame at every extent on both paths, or the reason this machine cannot be measured.
	 Answers self in both cases, because a machine with no device still has a report to give and
	 that report is not a failure. The session is mine: a benchmark that borrowed the image's own
	 would measure buffers somebody else had already grown."
	| session |
	rows := OrderedCollection new.
	backend := VGVulkanBackend new.
	session := VGVulkanDeviceSession new.
	session contextOrNil ifNil: [
		unavailableReason := session unavailableReason.
		^ self ].
	[
	[
	self class extents do: [ :extent |
		VGFrameDeviceBenchmark frameNames do: [ :frameName |
			self measureFrameNamed: frameName at: extent on: session ] ] ]
		on: Error
		do: [ :each |
		unavailableReason := each messageText ifNil: [ each class name ] ] ]
		ensure: [ session releaseDevice ].
	^ self
]

{ #category : 'initialization' }
VGPresentPathBenchmark >> setRounds: aRoundCount timedDraws: aDrawCount [
	roundCount := aRoundCount.
	timedDrawCount := aDrawCount.
	rows := OrderedCollection new
]

{ #category : 'running' }
VGPresentPathBenchmark >> stagesOf: aDispatch on: aPathName [
	"What one draw of that round was made of, stage by stage. A dispatch sums each stage over
	 every frame it drew since it was told to record, and the host copies of each path are
	 summed the same way, so both sides are divided by the draws of the round and the table
	 reads as the mean draw of it. The copies of the path alone are added: a path that makes
	 none has an empty table and shows the stages of the dispatch and nothing else."
	| answer drawsOfRound |
	drawsOfRound := self drawsOfARound.
	answer := Dictionary new.
	aDispatch stageMicroseconds keysAndValuesDo: [ :stage :total |
		answer at: stage put: (total / drawsOfRound) rounded ].
	(self hostCopiesOf: aPathName) keysAndValuesDo: [ :stage :total |
		answer at: stage put: (total / drawsOfRound) rounded ].
	^ answer
]

{ #category : 'running' }
VGPresentPathBenchmark >> surfaceOfFrameNamed: aName at: anExtent [
	"A surface of that extent with that frame drawn on it and nothing drained. No backend is
	 named on it: the frame is encoded by hand here, so the display list must stay where the
	 drawing left it."
	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	(VGFrameDeviceBenchmark drawBlockNamed: aName) value: surface newContext.
	^ surface
]

{ #category : 'running' }
VGPresentPathBenchmark >> timed: aStageName of: aPathName during: aBlock [
	"The block evaluated, its wall clock added to that stage of that path, and its value
	 answered, so that a copy is timed where it is used rather than around it. The clock is
	 added and not stored, as a dispatch adds its own stages: a round sums every draw it made
	 and divides once, at the end. The table is kept a path at a time because the stages a
	 dispatch times are shared by both paths and these are not: a path that never copies in the
	 host has an empty table, which is what makes it the path it is."
	| started answer table |
	table := self hostCopiesOf: aPathName.
	started := Time microsecondClockValue.
	answer := aBlock value.
	table
		at: aStageName
		put: (table at: aStageName ifAbsent: [ 0 ])
			+ (Time microsecondClockValue - started).
	^ answer
]

{ #category : 'running' }
VGPresentPathBenchmark >> timedDrawsOf: aBlock [
	"The timed draws of one round of one path, every one of them recorded in the stages of that
	 round as well."
	^ (1 to: timedDrawCount) collect: [ :each | self microsecondsOf: aBlock ]
]

{ #category : 'accessing' }
VGPresentPathBenchmark >> unavailableReason [
	"Why this machine could not be measured, or nil where it could."
	^ unavailableReason
]
