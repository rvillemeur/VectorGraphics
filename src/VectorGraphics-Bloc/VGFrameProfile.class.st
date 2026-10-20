"
I measure where the time of one frame goes, so that phase two has a target and can be judged against a number rather than an impression.

I build a scene of Bloc elements — rounded cards with a vertical gradient, a stroked border and a text label each — and draw it twice: through this project, and through the canvas Bloc already has, which draws with Cairo. The two frames are the same scene at the same extent, so the two times can be read next to each other.

A frame here has two phases. The element tree records a display list into the canvas, which is the build phase, and the flush of the surface drains that list into pixels, which is the drain phase. They are timed apart because a hardware backend replaces them separately.

Inside the frame the time is attributed per stage by sampling. A sample is credited to the stage of the deepest class of this project on the stack, so arithmetic in a kernel class is charged to the code of ours that asked for it, and time in a class we did not write is charged to the scene. The stage of a class is read from the package and the tag it lives in, through `stageByPackageAndTag`, so a class moved from one tag to another changes stage with it.

Send `run` to measure and `report` for the table to paste into the plan; `slowestStage` names the stage to attack first. The scene is built under `BlHostRenderer preferableClass:`, because Bloc measures text during layout through that class and a span measured on the other backend carries a scaled font of that backend into our canvas.
"
Class {
	#name : 'VGFrameProfile',
	#superclass : 'Object',
	#instVars : [
		'extent',
		'cards',
		'frames',
		'ourMilliseconds',
		'cairoMilliseconds',
		'phaseMilliseconds',
		'stageSamples',
		'ourForm',
		'cairoForm'
	],
	#category : 'VectorGraphics-Bloc-Profiling',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Profiling'
}

{ #category : 'constants' }
VGFrameProfile class >> cardBorderWidth [
	"A visible border, so that every card is stroked as well as filled."

	^ 2
]

{ #category : 'constants' }
VGFrameProfile class >> cardCornerRadius [
	"Rounded corners, so that the rasteriser is given curves and not only axis aligned edges."

	^ 8
]

{ #category : 'constants' }
VGFrameProfile class >> cardExtent [
	"A card the size of a row of a list or a tile of a palette."

	^ 180 @ 90
]

{ #category : 'constants' }
VGFrameProfile class >> cardGap [
	"The space between two cards and between a card and the edge of the frame."

	^ 20
]

{ #category : 'stages' }
VGFrameProfile class >> keyForClass: aClass [
	"The key a class is looked up in the stage table under: the package it is defined in and the
	 tag it is filed under."

	| instanceSide |
	instanceSide := aClass instanceSide.
	^ instanceSide package name , '/'
	  , (instanceSide packageTag ifNil: [ '' ] ifNotNil: [ :tag | tag name ])
]

{ #category : 'constants' }
VGFrameProfile class >> labelInset [
	"Where the label of a card sits inside it."

	^ 12 @ 12
]

{ #category : 'stages' }
VGFrameProfile class >> packageAndTagKeys [
	"Every package and tag pair of this project, read from the organiser. These are the keys the
	 stage table has to have and the only ones it may have. The list of packages is the one the
	 static proof of unit 1.10 scans, so the test packages are left out: nothing in a test runs
	 inside a profiled frame."

	^ (VGCairoReferenceScanner projectPackageNames flatCollect: [ :packageName |
		   (PackageOrganizer default packageNamed: packageName) definedClasses
			   collect: [ :each | self keyForClass: each ] ]) asSet asArray
]

{ #category : 'instance creation' }
VGFrameProfile class >> reference [
	"The profile the plan's numbers were measured with: the reference extent, the reference number
	 of cards and the reference number of frames, already run."

	| profile |
	profile := self new.
	profile run.
	^ profile
]

{ #category : 'constants' }
VGFrameProfile class >> referenceCards [
	"Twelve cards fill the reference frame without overlapping, which is what a list or a palette
	 of a real tool looks like."

	^ 12
]

{ #category : 'constants' }
VGFrameProfile class >> referenceExtent [
	"The extent of the frame the plan's numbers were measured at: a window, not a thumbnail."

	^ 800 @ 600
]

{ #category : 'constants' }
VGFrameProfile class >> referenceFrames [
	"Each timed number is the mean of this many frames, so that one scheduling hiccup does not
	 become the measurement."

	^ 3
]

{ #category : 'constants' }
VGFrameProfile class >> sceneStage [
	"Time spent in a class this project did not write: Bloc walking the element tree, laying it
	 out and asking the canvas to draw. It is a stage of the frame like any other, and naming it
	 keeps the shares summing to one."

	^ #sceneAndLayout
]

{ #category : 'stages' }
VGFrameProfile class >> stageByPackageAndTag [
	"The stage each package and tag of this project belongs to, keyed by `'<package>/<tag>'`. The
	 tag is the unit rather than the class, so a class moved between tags moves stage with it and
	 nothing here has to be touched; `VGFrameProfileTest` holds these keys against the organiser.

	 The stages are the frame read as a pipeline. `canvasApi` is the drawing verbs and the state
	 they keep, `transforms` the matrices they multiply, `pathAndStroke` the flattening and the
	 stroke outlines, `displayList` the recording and the draining of a frame, `coverage` the
	 rasteriser that says how much of a pixel a shape covers, `paintSource` the colour a pattern
	 answers at a pixel, `compositing` the operators, and `pixelAccess` the surface and its pixel
	 format, which is both the reading and writing of a pixel and the byte arithmetic that
	 quantises a colour or a coverage into one. Then `text`, `blur` and `handover`. `harness` is this class, which runs
	 inside the frame it measures. `notInTheFrame` is code that cannot appear in a frame: the
	 exporters, the reflection and inventory helpers, the examples, and the classes this project
	 inherited from the earlier pure Pharo VectorGraphics package."

	^ Dictionary newFrom: {
			  ('VectorGraphics-Cairo/Context' -> #canvasApi).
			  ('VectorGraphics-Cairo/Skeleton' -> #canvasApi).
			  ('VectorGraphics-Bloc/Backend' -> #canvasApi).
			  ('VectorGraphics-Cairo/Matrix' -> #transforms).
			  ('VectorGraphics-Cairo/Path' -> #pathAndStroke).
			  ('VectorGraphics-Cairo/Backend' -> #displayList).
			  ('VectorGraphics-Cairo/Display list' -> #displayList).
			  ('VectorGraphics-Cairo/Rasterising' -> #coverage).
			  ('VectorGraphics-Cairo/Paint' -> #paintSource).
			  ('VectorGraphics-Cairo/Pattern' -> #paintSource).
			  ('VectorGraphics-Cairo/Compositing' -> #compositing).
			  ('VectorGraphics-Cairo/Surface' -> #pixelAccess).
			  ('VectorGraphics-Cairo/Text' -> #text).
			  ('VectorGraphics/TrueType' -> #text).
			  ('VectorGraphics-Cairo/Blur' -> #blur).
			  ('VectorGraphics-Bloc/Hosts' -> #handover).
			  ('VectorGraphics-Bloc/Profiling' -> #harness).
			  ('VectorGraphics-Cairo/Export' -> #notInTheFrame).
			  ('VectorGraphics-Cairo/Inventory' -> #notInTheFrame).
			  ('VectorGraphics-Cairo/Reflection' -> #notInTheFrame).
			  ('VectorGraphics-Bloc/Exporters' -> #notInTheFrame).
			  ('VectorGraphics-Bloc-Examples/Uncategorized' -> #notInTheFrame).
			  ('VectorGraphics-Cairo-Examples/Examples' -> #notInTheFrame).
			  ('VectorGraphics/Examples' -> #notInTheFrame).
			  ('VectorGraphics/Kernel' -> #notInTheFrame).
			  ('VectorGraphics/Manifest' -> #notInTheFrame).
			  ('VectorGraphics/PathCommands' -> #notInTheFrame).
			  ('VectorGraphics/SVG' -> #notInTheFrame).
			  ('VectorGraphics/Tests' -> #notInTheFrame) }
]

{ #category : 'stages' }
VGFrameProfile class >> stageOfClass: aClass [
	"The stage a sample taken inside this class belongs to. A class this project did not write is
	 the scene stage, which is how the shares of the stages account for the whole frame instead of
	 leaving an unattributed remainder."

	| instanceSide |
	instanceSide := aClass instanceSide.
	instanceSide package ifNil: [ ^ self sceneStage ].
	^ self stageByPackageAndTag
		  at: (self keyForClass: instanceSide)
		  ifAbsent: [ self sceneStage ]
]

{ #category : 'measuring' }
VGFrameProfile >> attribute: aTally [
	"Walk the tree of the sampler and answer how many samples each stage holds.

	 The stage travels down the tree: a node of a class of this project sets the stage for
	 everything it calls, so the arithmetic a kernel class does is charged to the code of ours that
	 asked for it rather than to the kernel. A node above every class of ours is the scene stage,
	 which is Bloc walking and laying out the element tree. The table is read once here because a
	 frame has thousands of nodes."

	| table samples pending |
	table := self class stageByPackageAndTag.
	samples := Dictionary new.
	pending := OrderedCollection with: aTally -> self class sceneStage.
	[ pending isEmpty ] whileFalse: [
		| pair node stage |
		pair := pending removeLast.
		node := pair key.
		stage := self stageOf: node within: pair value using: table.
		samples
			at: stage
			put: (samples at: stage ifAbsent: [ 0 ]) + (self ownSamplesOf: node).
		(node sonsOver: 0) do: [ :each | pending addLast: each -> stage ] ].
	^ samples
]

{ #category : 'accessing' }
VGFrameProfile >> cairoForm [
	"The last frame the other backend drew of the same scene."

	^ cairoForm
]

{ #category : 'accessing' }
VGFrameProfile >> cairoMilliseconds [
	"The mean time of the same frame drawn by the canvas Bloc already has, in milliseconds."

	^ cairoMilliseconds
]

{ #category : 'accessing' }
VGFrameProfile >> cards [
	^ cards
]

{ #category : 'accessing' }
VGFrameProfile >> cards: anInteger [
	cards := anInteger
]

{ #category : 'accessing' }
VGFrameProfile >> extent [
	^ extent
]

{ #category : 'accessing' }
VGFrameProfile >> extent: aPoint [
	extent := aPoint
]

{ #category : 'accessing' }
VGFrameProfile >> frames [
	^ frames
]

{ #category : 'accessing' }
VGFrameProfile >> frames: anInteger [
	frames := anInteger
]

{ #category : 'reading' }
VGFrameProfile >> hasRun [
	"Whether this profile has measured anything."

	^ ourMilliseconds notNil
]

{ #category : 'initialization' }
VGFrameProfile >> initialize [
	"A fresh profile is the reference configuration and has measured nothing yet."

	super initialize.
	extent := self class referenceExtent.
	cards := self class referenceCards.
	frames := self class referenceFrames.
	phaseMilliseconds := Dictionary new.
	stageSamples := Dictionary new
]

{ #category : 'inspector' }
VGFrameProfile >> inspectorCairoFrame: aBuilder [
	<inspectorPresentationOrder: 13 title: 'Cairo frame'>
	"The same scene as the other backend drew it. The two frames are not expected to be identical
	 — the conformance corpus is where that is held — but a scene that drew on one backend and not
	 on the other makes the two times meaningless."

	^ aBuilder newImage image: cairoForm
]

{ #category : 'inspector' }
VGFrameProfile >> inspectorCairoFrameContext: aContext [
	aContext active: cairoForm notNil
]

{ #category : 'inspector' }
VGFrameProfile >> inspectorFrame: aBuilder [
	<inspectorPresentationOrder: 12 title: 'Frame'>
	"The frame this project drew, so that a profile of a scene that drew nothing is visible as
	 such."

	^ aBuilder newImage image: ourForm
]

{ #category : 'inspector' }
VGFrameProfile >> inspectorFrameContext: aContext [
	"A form over nothing would raise rather than show an empty tab."

	aContext active: ourForm notNil
]

{ #category : 'inspector' }
VGFrameProfile >> inspectorStages: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Stages'>
	"Where the frame went, largest share first. The rows are asked of the measurement rather than
	 listed, so a stage that stops being measured stops appearing, and the stage named first is
	 the one `slowestStage` answers."

	^ aBuilder newTable
		  items: self stagesByShare;
		  addColumn: (SpStringTableColumn
				   title: 'Stage'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Share'
				   evaluated: [ :each |
					   ((each value * 100) asFloat printShowingDecimalPlaces: 1) , '%' ]);
		  addColumn: (SpStringTableColumn
				   title: 'Milliseconds'
				   evaluated: [ :each |
					   self millisecondsPrintString: (self stageMilliseconds at: each key) ]);
		  addColumn: (SpStringTableColumn
				   title: 'Samples'
				   evaluated: [ :each | (stageSamples at: each key) printString ]);
		  yourself
]

{ #category : 'inspector' }
VGFrameProfile >> inspectorStagesContext: aContext [
	"A profile that has not run has nothing to show."

	aContext active: stageSamples notEmpty
]

{ #category : 'inspector' }
VGFrameProfile >> inspectorTimes: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Times'>
	"The frame times of the two backends for the same scene, our two phases, and how many times
	 slower this project is. The ratio is divided here rather than written down, so it cannot
	 disagree with the two numbers above it."

	^ aBuilder newTable
		  items: {
				  ('Cards' -> cards printString).
				  ('Extent' -> extent printString).
				  ('Frames each' -> frames printString).
				  ('This project' -> (self millisecondsPrintString: ourMilliseconds)).
				  ('Build' -> (self millisecondsPrintString: (phaseMilliseconds at: #build))).
				  ('Drain' -> (self millisecondsPrintString: (phaseMilliseconds at: #drain))).
				  ('Cairo' -> (self millisecondsPrintString: cairoMilliseconds)).
				  ('Times slower' -> ((ourMilliseconds / cairoMilliseconds) asFloat
					    printShowingDecimalPlaces: 1)).
				  ('Slowest stage' -> self slowestStage) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGFrameProfile >> inspectorTimesContext: aContext [
	"Nothing was timed until the profile ran."

	aContext active: self hasRun
]

{ #category : 'private' }
VGFrameProfile >> millisecondsDuring: aBlock [
	"The time the block took, in milliseconds, read from the microsecond clock: a phase of a frame
	 can be well under a millisecond and the millisecond clock would answer zero for it."

	| start |
	start := Time microsecondClockValue.
	aBlock value.
	^ (Time microsecondsSince: start) / 1000.0
]

{ #category : 'private' }
VGFrameProfile >> millisecondsPrintString: aNumber [
	"A time in milliseconds, to one decimal place and with its unit, as the report and the
	 inspector both show it."

	^ (aNumber asFloat printShowingDecimalPlaces: 1) , ' ms'
]

{ #category : 'private' }
VGFrameProfile >> newCanvas [
	"A canvas of this project over a surface of the frame's extent, clipped to the whole frame as
	 a window would clip it."

	| canvas |
	canvas := VGCanvas extent: extent.
	canvas clippingRectangle: (0 @ 0 extent: extent).
	^ canvas
]

{ #category : 'scene' }
VGFrameProfile >> newCardAt: anIndex [
	"The card of this index, placed in a grid as wide as the frame allows. A card that falls past
	 the edge of the frame is clipped, which is also what a scrolled list does."

	| card label columns column row gap |
	gap := self class cardGap.
	columns := extent x // (self class cardExtent x + gap) max: 1.
	column := anIndex - 1 \\ columns.
	row := anIndex - 1 // columns.
	card := BlElement new
		        geometry:
			        (BlRoundedRectangleGeometry cornerRadius:
					         self class cardCornerRadius);
		        background: (BlLinearGradientPaint vertical stops: {
						         (0 -> Color white).
						         (1 -> Color lightBlue) });
		        border:
			        (BlBorder
				         paint: Color gray
				         width: self class cardBorderWidth);
		        extent: self class cardExtent;
		        position: gap + (column * (self class cardExtent x + gap))
			        @ (gap + (row * (self class cardExtent y + gap)));
		        yourself.
	label := BlTextElement new
		         text: ('Card ' , anIndex printString) asRopedText;
		         position: self class labelInset;
		         yourself.
	card addChild: label.
	^ card
]

{ #category : 'scene' }
VGFrameProfile >> newScene [
	"A frame of what a real tool draws: a filled background, and cards in a grid, each a rounded
	 rectangle with a vertical gradient, a stroked border and a text label. Between them the four
	 things that cost in a software rasteriser are all present — curved edges, a gradient read per
	 pixel, a stroke outline, and glyphs through the atlas.

	 The layout is forced rather than settled by a space, because this tree is never attached to
	 one: that is also what `BlElement >> aeAsForm` does with a detached element, so the critique
	 Renraku raises here is the same one that method carries."

	| root |
	root := BlElement new
		        extent: extent;
		        background: Color veryVeryLightGray;
		        yourself.
	1 to: cards do: [ :index | root addChild: (self newCardAt: index) ].
	root forceLayout.
	^ root
]

{ #category : 'accessing' }
VGFrameProfile >> ourForm [
	"The last frame this project drew."

	^ ourForm
]

{ #category : 'accessing' }
VGFrameProfile >> ourMilliseconds [
	"The mean time of one frame drawn by this project, in milliseconds."

	^ ourMilliseconds
]

{ #category : 'private' }
VGFrameProfile >> ownSamplesOf: aTally [
	"The samples taken in this node itself: its tally less the tallies of the nodes it called."

	^ (aTally tally - ((aTally sonsOver: 0) inject: 0 into: [ :sum :each |
		    sum + each tally ])) max: 0
]

{ #category : 'accessing' }
VGFrameProfile >> phaseMilliseconds [
	"The two phases of our frame, `#build` and `#drain`, in milliseconds."

	^ phaseMilliseconds
]

{ #category : 'reading' }
VGFrameProfile >> report [
	"The table to paste into the plan: the configuration, the frame time of each backend, our two
	 phases, and every stage with its share and its milliseconds, largest share first. The lines
	 are separated with a carriage return built at run time, because this project's source holds
	 no line feed."

	self hasRun ifFalse: [ ^ 'Not run yet.' ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: cards printString;
			  nextPutAll: ' cards at ';
			  nextPutAll: extent x printString;
			  nextPutAll: ' by ';
			  nextPutAll: extent y printString;
			  nextPutAll: ', mean of ';
			  nextPutAll: frames printString;
			  nextPutAll: ' frames';
			  nextPut: Character cr;
			  nextPutAll: 'this project ';
			  nextPutAll: (self millisecondsPrintString: ourMilliseconds);
			  nextPutAll: ' (build ';
			  nextPutAll:
				  (self millisecondsPrintString: (phaseMilliseconds at: #build));
			  nextPutAll: ', drain ';
			  nextPutAll:
				  (self millisecondsPrintString: (phaseMilliseconds at: #drain));
			  nextPutAll: ')';
			  nextPut: Character cr;
			  nextPutAll: 'Cairo ';
			  nextPutAll: (self millisecondsPrintString: cairoMilliseconds);
			  nextPut: Character cr.
		  self stagesByShare do: [ :each |
			  stream
				  nextPutAll: each key;
				  nextPutAll: ' ';
				  nextPutAll:
					  ((each value * 100) asFloat printShowingDecimalPlaces: 1);
				  nextPutAll: '% ';
				  nextPutAll:
					  (self millisecondsPrintString: (self stageMilliseconds at: each key));
				  nextPut: Character cr ] ]
]

{ #category : 'measuring' }
VGFrameProfile >> run [
	"Measure the frame three times over: our own frame timed in its two phases, the same scene
	 timed through the backend Bloc already has, and one more of our frames under the sampler so
	 that the time can be split per stage. The sampled frame is not one of the timed ones, because
	 the sampler costs time of its own and would be counted as our frame."

	| scene |
	scene := self sceneForRendererClass: VGRenderer.
	self timeOurFramesOf: scene.
	self timeCairoFramesOf: (self sceneForRendererClass: BARenderer).
	self sampleOneFrameOf: scene.
	^ self
]

{ #category : 'measuring' }
VGFrameProfile >> sampleOneFrameOf: aScene [
	"One of our frames under the sampling profiler, whose tree is then attributed per stage."

	| profiler canvas |
	profiler := AndreasSystemProfiler new.
	canvas := self newCanvas.
	profiler spyOn: [
		aScene aeFullDrawOn: canvas.
		canvas privateAeCairoSurface flush ].
	stageSamples := self attribute: profiler tallyRoot
]

{ #category : 'scene' }
VGFrameProfile >> sceneForRendererClass: aRendererClass [
	"The reference scene, laid out, with every text span measured through the renderer class given.
	 Bloc measures text during layout through `BlHostRenderer preferableClass`, and a span measured
	 on one backend keeps that backend's scaled font, which the other backend cannot draw. The
	 class is put back whatever happens, because it decides how the whole image draws."

	| previous |
	previous := BlHostRenderer preferableClass.
	^ [
	  BlHostRenderer preferableClass: aRendererClass.
	  self newScene ] ensure: [ BlHostRenderer preferableClass: previous ]
]

{ #category : 'reading' }
VGFrameProfile >> slowestStage [
	"The stage that holds the largest share of the frame: the one a faster backend has to attack
	 first. A profile that has not run names none."

	stageSamples ifEmpty: [ ^ nil ].
	^ (stageSamples associations detectMax: [ :each | each value ]) key
]

{ #category : 'reading' }
VGFrameProfile >> stageMilliseconds [
	"Each stage's share of the frame that was timed, in milliseconds, so that a stage can be read
	 next to the Cairo number for the whole scene."

	| milliseconds |
	milliseconds := Dictionary new.
	self stageShares keysAndValuesDo: [ :stage :share |
		milliseconds at: stage put: share * ourMilliseconds ].
	^ milliseconds
]

{ #category : 'private' }
VGFrameProfile >> stageOf: aTally within: aStage using: aTable [
	"The stage a node belongs to: its own, if the method it stands for belongs to a package of this
	 project, and otherwise the stage of whatever called it."

	| method class |
	method := aTally originMethod.
	method ifNil: [ ^ aStage ].
	class := method methodClass instanceSide.
	class package ifNil: [ ^ aStage ].
	^ aTable at: (self class keyForClass: class) ifAbsent: [ aStage ]
]

{ #category : 'accessing' }
VGFrameProfile >> stageSamples [
	"How many samples of the profiled frame were credited to each stage."

	^ stageSamples
]

{ #category : 'reading' }
VGFrameProfile >> stageShares [
	"What share of the profiled frame each stage holds. A profile that has not run holds none."

	| total shares |
	total := stageSamples inject: 0 into: [ :sum :each | sum + each ].
	total = 0 ifTrue: [ ^ Dictionary new ].
	shares := Dictionary new.
	stageSamples keysAndValuesDo: [ :stage :count |
		shares at: stage put: count / total ].
	^ shares
]

{ #category : 'reading' }
VGFrameProfile >> stagesByShare [
	"The stages as associations to their share, largest first, which is the order the report and
	 the inspector read them in."

	^ (self stageShares associations asSortedCollection: [ :a :b |
		   a value >= b value ]) asArray
]

{ #category : 'measuring' }
VGFrameProfile >> timeCairoFramesOf: aScene [
	"The same scene through the canvas Bloc already has, which draws with Cairo. That canvas draws
	 as it is asked rather than recording, so it has one phase and not two. `AeCanvas` is a class
	 of Alexandrie's canvas package and not of its Cairo package, which is why naming it here
	 leaves the rule that no package of this project names a Cairo class intact."

	| total |
	total := 0.
	frames timesRepeat: [
		| canvas |
		canvas := AeCanvas extent: extent.
		canvas clippingRectangle: (0 @ 0 extent: extent).
		total := total + (self millisecondsDuring: [
			          aScene aeFullDrawOn: canvas.
			          canvas privateAeCairoSurface flush ]).
		cairoForm := canvas asForm ].
	cairoMilliseconds := total / frames
]

{ #category : 'measuring' }
VGFrameProfile >> timeOurFramesOf: aScene [
	"Our frame, as many times as asked, each on a canvas of its own. The two phases are timed
	 apart: drawing the element tree records a display list, and flushing the surface drains it
	 into pixels."

	| build drain |
	build := 0.
	drain := 0.
	frames timesRepeat: [
		| canvas |
		canvas := self newCanvas.
		build := build
		         + (self millisecondsDuring: [ aScene aeFullDrawOn: canvas ]).
		drain := drain + (self millisecondsDuring: [
			          canvas privateAeCairoSurface flush ]).
		ourForm := canvas asForm ].
	phaseMilliseconds := Dictionary newFrom: {
			                     (#build -> (build / frames)).
			                     (#drain -> (drain / frames)) }.
	ourMilliseconds := (phaseMilliseconds at: #build)
	                   + (phaseMilliseconds at: #drain)
]
