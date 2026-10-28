"
I hold the Vulkan backend to the contract VGBackend freezes.

It offers itself for selection ahead of the software backend, its probe answers an instance of it or nothing at all on whichever machine the suite runs, and a frame of the tiled fill subset drawn through it holds the same bytes as the same frame drawn by the software backend, where a device computes at all.

What it cannot draw it refuses rather than drawing wrongly: an entry outside the subset fails while the frame is recorded, a surface blit fails the same way, and a target of another format fails while the frame is drained. A frame the subset refuses draws the picture the software backend draws, which is the proof that the failover is arranged and not merely described.

The pixels of a target go out packed row after row whatever its stride is, because the kernel indexes a pixel by its row and its column alone.

I keep and restore the selection state of VGBackend, because forcing a backend or failing one is class-side state that would otherwise leak into the next test.
"
Class {
	#name : 'VGVulkanBackendTest',
	#superclass : 'TestCase',
	#instVars : [
		'savedPreference',
		'savedRejections'
	],
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'fixtures' }
VGVulkanBackendTest >> displayListOfTheFixtureFrame [
	"The fixture frame recorded and read before anything drains it."

	| surface list |
	surface := VGCairoImageSurface extent: self frame extent.
	self frame drawOn: surface.
	list := surface displayList.
	^ list
]

{ #category : 'fixtures' }
VGVulkanBackendTest >> formOfExtent: anExtent drawnWith: aBlock on: aBackend [
	"A frame of my own drawn through that backend and answered as a Form, the way the fixture
	 answers its own, so that a picture is held against another picture."

	| surface |
	surface := VGCairoImageSurface extent: anExtent.
	surface backend: aBackend.
	aBlock value: surface newContext.
	surface flush.
	^ surface asForm
]

{ #category : 'running' }
VGVulkanBackendTest >> frame [
	"The frame the backend tests draw, the same fixture the selection tests of the engine use, so
	 that a picture drawn here is held against the same picture."

	^ VGBackendFrameFixture new
]

{ #category : 'fixtures' }
VGVulkanBackendTest >> recordTheFrameOn: aBackend [
	"The fixture frame recorded on that backend and not drained, which is what a surface does to
	 the backend it holds: it replays its display list and drains afterwards."

	| surface |
	surface := VGCairoImageSurface extent: self frame extent.
	self frame drawOn: surface.
	surface displayList replayOn: aBackend.
	surface displayList reset
]

{ #category : 'fixtures' }
VGVulkanBackendTest >> refusedEntry [
	"One recorded entry outside the subset, read out of a frame nothing has drained. The list is
	 reset afterwards, so that nothing replays the frame when the surface is collected."

	| surface entry |
	surface := VGCairoImageSurface extent: self frame extent.
	self unsupportedFrame value: surface newContext.
	entry := surface displayList entries first.
	surface displayList reset.
	^ entry
]

{ #category : 'running' }
VGVulkanBackendTest >> setUp [
	"The preference and the rejections are class-side state of VGBackend, so a test that forces a
	 backend or fails one would leak into the next. Keep both and put them back."

	super setUp.
	savedPreference := VGBackend preferredClassOrNil.
	savedRejections := VGBackend rejectedClasses
]

{ #category : 'running' }
VGVulkanBackendTest >> tearDown [
	VGBackend restorePreference: savedPreference rejections: savedRejections.
	super tearDown
]

{ #category : 'tests' }
VGVulkanBackendTest >> testABlitOutsideTheSubsetFailsTheFrame [
	"A blit is refused for the same reasons a fill is, and for no other: here the paint is a mesh
	 pattern, which no block, stop list or run of pixels describes, so the frame fails while it is
	 recorded and the surface replays the whole of it on the failover."

	| backend raised |
	backend := VGVulkanBackend new.
	raised := [ backend
		           blitSurface: (VGCairoImageSurface extent: 8 @ 6)
		           at: 2 @ 3
		           paint: VGTiledFillExamples meshPatternOutsideTheSubset paint
		           clip: (VGClip bounds: (0 @ 0 corner: self frame extent))
		           operator: VGCairoOperator over.
	          nil ]
		          on: VGBackendFailure
		          do: [ :failure | failure ].
	self assert: raised notNil.
	self assert: raised backend identicalTo: backend
]

{ #category : 'tests' }
VGVulkanBackendTest >> testADrainWithNothingRecordedLeavesTheTargetAlone [
	"A surface flushed with no frame recorded asks nothing of a device: there is no dispatch, no
	 failure and no pixel written."

	| backend target |
	target := VGCairoImageSurface extent: self frame extent.
	backend := VGVulkanBackend new.
	backend drainInto: target.
	self
		assert: target asForm bits
		equals: (VGCairoImageSurface extent: self frame extent) asForm bits
]

{ #category : 'tests' }
VGVulkanBackendTest >> testAFrameOutsideTheSubsetIsDrawnBySoftwareAnyway [
	"The failover with the real backend and not a stub: a frame the subset refuses draws the
	 picture the software backend draws, and the Vulkan backend is out of selection afterwards."

	| expected drawn |
	expected := self
		            formOfExtent: self frame extent
		            drawnWith: self unsupportedFrame
		            on: VGSoftwareBackend new.
	VGBackend clearPreference.
	drawn := self
		         formOfExtent: self frame extent
		         drawnWith: self unsupportedFrame
		         on: VGVulkanBackend new.
	self assert: drawn bits equals: expected bits.
	self assert: (VGBackend rejectedClasses includes: VGVulkanBackend).
	self assert: VGBackend preferredClass equals: VGSoftwareBackend
]

{ #category : 'tests' }
VGVulkanBackendTest >> testAGradientFillIsRecordedAndDrawnRatherThanRefused [
	"Unit 2.4 widens the subset to a gradient, so a gradient fill inside a rectangular clip is
	 recorded here and not refused. The pixels of a gradient frame are held against the software
	 backend in VGTiledFillTest, where one context draws all fifteen of them; what is held here
	 is that the frame reaches the device at all and comes back with ink in it. The ink is
	 counted against a surface nothing has drawn on, because a new ARGB32 surface reads as
	 transparent white and not as zero."
	| backend surface drawn blank |
	VGVulkanBackend probe ifNil: [ ^ self ].
	VGBackend restorePreference: nil rejections: #( ).
	backend := VGVulkanBackend new.
	surface := VGCairoImageSurface extent: VGGradientFrameFixture extent.
	surface backend: backend.
	VGGradientFrameFixture linearWithThreeStops value: surface newContext.
	surface flush.
	drawn := surface asForm.
	blank := (VGCairoImageSurface extent: VGGradientFrameFixture extent) asForm.
	self deny: (VGBackend rejectedClasses includes: VGVulkanBackend).
	self
		assert:
		(VGFormComparison between: drawn and: blank) differingPixelCount > 0
]

{ #category : 'tests' }
VGVulkanBackendTest >> testAPaintTheKernelCannotEvaluateFailsTheFrame [
	"The widening of unit 2.4 reaches a block and a stop list, and that of unit 2.9 a run of
	 pixels. A mesh paint carries patches, which are none of the three, so a fill of one fails the
	 frame while it is recorded, and the surface replays the whole frame on the failover."

	| backend raised |
	backend := VGVulkanBackend new.
	raised := [
	          backend
		          fillSegments: self refusedEntry segments
		          paint: VGTiledFillExamples meshPatternOutsideTheSubset paint
		          clip: (VGClip bounds: (0 @ 0 corner: self frame extent))
		          operator: VGCairoOperator over.
	          nil ]
		          on: VGBackendFailure
		          do: [ :failure | failure ].
	self assert: raised notNil.
	self assert: raised backend identicalTo: backend
]

{ #category : 'tests' }
VGVulkanBackendTest >> testASurfaceBlitIsRecordedAndDrawnRatherThanRefused [
	"Unit 2.6 draws a blit, so a blit of a solid paint through a mask inside a rectangular clip is
	 recorded here and not refused. What is recorded is the blit itself and not the fill it is
	 drawn as: the rasteriser rewrites it when it draws it, and the surface may still replay the
	 recorded frame on the software backend, which needs the mask and not a flattened copy of it.
	 The pixels of a blit are held against the software backend in VGTiledBlitTest."

	| backend mask |
	backend := VGVulkanBackend new.
	mask := VGCairoImageSurface extent: 8 @ 6.
	backend
		blitSurface: mask
		at: 2 @ 3
		paint: (VGColorPaint r: 0.2 g: 0.4 b: 0.9 alpha: 1.0)
		clip: (VGClip bounds: (0 @ 0 corner: self frame extent))
		operator: VGCairoOperator over.
	self assert: backend recordedFrame entries size equals: 1.
	self assert: (backend recordedFrame entries first isKindOf: VGBlitEntry)
]

{ #category : 'tests' }
VGVulkanBackendTest >> testATargetOfAnotherFormatFailsTheFrame [
	"A frame is encoded for one surface format, so a target of any other belongs to the software
	 backend. The refusal comes while the frame is drained and before its first pixel, which is
	 what lets the surface replay it whole."

	| backend target raised |
	backend := VGVulkanBackend new.
	target := VGCairoImageSurface
		          extent: self frame extent
		          format: VGCairoSurfaceFormat a8.
	self recordTheFrameOn: backend.
	raised := [
	          backend drainInto: target.
	          nil ]
		          on: VGBackendFailure
		          do: [ :failure | failure ].
	self assert: raised notNil.
	self assert: raised backend identicalTo: backend
]

{ #category : 'tests' }
VGVulkanBackendTest >> testAnEntryOfTheSubsetIsRecordedAndDrawnLater [
	"A fill the kernel can draw is recorded and nothing is asked of a device while the frame is
	 still being read: the drawing waits for the drain, which is what lets the whole frame be
	 checked before its first pixel."

	| backend entry |
	backend := VGVulkanBackend new.
	entry := (self displayListOfTheFixtureFrame) entries first.
	backend
		fillSegments: entry segments
		paint: entry paint
		clip: entry clip
		operator: entry operator.
	self assert: backend recordedFrame entries size equals: 1
]

{ #category : 'tests' }
VGVulkanBackendTest >> testAnEntryOutsideTheSubsetFailsTheFrame [
	"The subset is checked entry by entry while the frame is recorded, so a frame holding one
	 entry the kernel cannot draw fails before any pixel of it is written. The failure names the
	 backend, because the recovery rejects a backend by class."

	| backend entry raised |
	backend := VGVulkanBackend new.
	entry := self refusedEntry.
	raised := [
	          backend
		          fillSegments: entry segments
		          paint: entry paint
		          clip: entry clip
		          operator: entry operator.
	          nil ]
		          on: VGBackendFailure
		          do: [ :failure | failure ].
	self assert: raised notNil.
	self assert: raised backend identicalTo: backend
]

{ #category : 'tests' }
VGVulkanBackendTest >> testTheBackendIsProbedBeforeTheSoftwareOne [
	"It stands for selection, and it stands ahead of the failover, or a machine with a device
	 would still draw every pixel on the processor. A failover earlier in the session leaves this
	 backend out of selection on purpose, and the fact stated here is the order and not the
	 state, so the state is cleared first."

	VGBackend restorePreference: nil rejections: #( ).
	self assert: VGVulkanBackend isCandidate.
	self
		assert: VGVulkanBackend preferenceRank < VGSoftwareBackend preferenceRank.
	self assert: (VGBackend candidateClasses includes: VGVulkanBackend).
	self
		assert: (VGBackend candidateClasses indexOf: VGVulkanBackend)
		< (VGBackend candidateClasses indexOf: VGSoftwareBackend)
]

{ #category : 'tests' }
VGVulkanBackendTest >> testTheDeviceDrawsTheFrameTheSoftwareBackendDraws [
	"The device and the processor on one frame, byte for byte. The fixture frame is two
	 rectangles of whole pixels, so every coverage in it is nothing or everything and the single
	 floats of the device answer what the Float64 of the rasteriser answer. A machine with no
	 device has nothing to compare, so the fact is held where the probe answers a backend. Both
	 the preference and the rejections are cleared first: a failover earlier in the session would
	 otherwise keep this backend out of selection and make the fact below say nothing."

	| expected drawn |
	VGVulkanBackend probe ifNil: [ ^ self ].
	expected := self frame drawnBy: VGSoftwareBackend new.
	VGBackend restorePreference: nil rejections: #( ).
	drawn := self frame drawnBy: VGVulkanBackend new.
	self assert: drawn bits equals: expected bits.
	self deny: (VGBackend rejectedClasses includes: VGVulkanBackend)
]

{ #category : 'tests' }
VGVulkanBackendTest >> testThePixelsOfATargetArePackedRowAfterRowWhateverItsStrideIs [
	"The kernel indexes a pixel by its row and its column alone, so what it is given holds no
	 padding between the rows. A target whose stride is wider than its row keeps that padding:
	 the rows go out packed, and they come back into the rows they came from with every padding
	 byte of the target still as it was."

	| backend width height stride data surface packed |
	backend := VGVulkanBackend new.
	width := 3.
	height := 2.
	stride := width * VGTiledFillEncoding targetFormat bytesPerPixel + 8.
	data := ByteArray new: stride * height.
	1 to: data size do: [ :index | data at: index put: 255 ].
	surface := VGCairoImageSurface
		           unownedNewForData: data
		           format: VGTiledFillEncoding targetFormat
		           width: width
		           height: height
		           stride: stride.
	0 to: height - 1 do: [ :row |
		0 to: width - 1 do: [ :column |
			surface primitivePixelAtX: column y: row put: row * width + column ] ].
	packed := backend pixelsOf: surface.
	self
		assert: packed size
		equals: width * height * VGTiledFillEncoding targetFormat bytesPerPixel.
	0 to: width * height - 1 do: [ :index |
		self
			assert: (packed uint32AtOffset: index * VGTiledFillEncoding targetFormat bytesPerPixel)
			equals: index ].
	0 to: width * height - 1 do: [ :index |
		packed
			uint32AtOffset: index * VGTiledFillEncoding targetFormat bytesPerPixel
			put: index + 100 ].
	backend write: packed into: surface.
	0 to: height - 1 do: [ :row |
		0 to: width - 1 do: [ :column |
			self
				assert: (surface primitivePixelAtX: column y: row)
				equals: row * width + column + 100 ] ].
	1 to: height do: [ :row |
		(width * VGTiledFillEncoding targetFormat bytesPerPixel + 1 to: stride) do: [ :offset |
			self assert: (data at: row - 1 * stride + offset) equals: 255 ] ]
]

{ #category : 'tests' }
VGVulkanBackendTest >> testTheProbeAnswersTheBackendOrNothing [
	"The probe runs a real dispatch, so its answer depends on the machine the suite runs on: an
	 instance of the backend where a device computes, nil where none does. What may never happen
	 is a raise, because selection probes a candidate without a handler of its own."

	| probed |
	probed := VGVulkanBackend probe.
	probed ifNotNil: [ self assert: probed class equals: VGVulkanBackend ]
]

{ #category : 'fixtures' }
VGVulkanBackendTest >> unsupportedFrame [
	"A frame the subset refuses: the paint is a mesh pattern, whose patches are in neither a
	 coefficient block, a stop list nor a run of pixels, so the one entry it records is a fill the
	 kernel cannot draw. The failover is held to this frame rather than to the fixture one,
	 because the fixture frame is a solid fill inside a rectangular clip and the device draws that
	 from unit 2.3 on. A shaped clip stopped refusing a frame at unit 2.7 and a surface pattern at
	 unit 2.9, so the refusal here is the mesh and nothing else."

	^ [ :context |
	  context
		  sourcePattern: VGTiledFillExamples meshPatternOutsideTheSubset;
		  rectangleX: 2 y: 2 width: 36 height: 26;
		  fill ]
]
