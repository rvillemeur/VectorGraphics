"
I am the clock of one half of a frame: the three methods a class needs in order to say where its own milliseconds went, kept over a VGStageTimings of its own.
A user of mine declares stageNames on its class side, which is the one place that names its phases, and sends timeStage:during: around each of them. It reads no clock at all until a caller sends recordStages, because the clock is read twice a phase and a phase of a frame can be shorter than the reading; the benchmarks and the censuses ask for the phases, and a running tool never does.
My users are VGTiledFillEncoding and VGTileBinning for the host half of a frame and VGTiledFillDispatch for the device half. I am a trait and not a superclass because the three have nothing else in common.
"
Trait {
	#name : 'TVGStageRecording',
	#instVars : [
		'stages'
	],
	#category : 'VectorGraphics-Vulkan-Budget',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Budget'
}

{ #category : 'measuring' }
TVGStageRecording >> isRecordingStages [
	"Whether a caller asked for my phases. A view of them reads this rather than the table
	 itself, so no user of mine names my slot."
	^ stages notNil
]

{ #category : 'measuring' }
TVGStageRecording >> recordStages [
	"Time every phase of the work I do from here on, under the names my class side's stageNames
	 gives. Sent before the work starts, since the phases run inside it."
	stages := VGStageTimings new.
	^ self
]

{ #category : 'measuring' }
TVGStageRecording >> stageMicroseconds [
	"What each phase cost, keyed by phase name. A phase that was never reached is absent rather
	 than nought, so work that returned early can be told from work whose phase was too fast to
	 measure."
	^ stages ifNil: [ Dictionary new ] ifNotNil: [ stages microseconds ]
]

{ #category : 'measuring' }
TVGStageRecording >> timeStage: aSymbol during: aBlock [
	"The block, answering what it answers, with the microseconds it took added to that phase
	 where a caller asked for the phases. Asked of nobody, I evaluate the block and read no
	 clock at all, so the phases cost a running tool nothing."
	stages ifNil: [ ^ aBlock value ].
	^ stages time: aSymbol during: aBlock
]
