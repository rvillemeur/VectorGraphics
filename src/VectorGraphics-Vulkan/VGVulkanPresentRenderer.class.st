"
I am the renderer of a window that presents from the device. I override render:, because it is BARenderer >> render: that sends lockSurfaceFor:scaleFactor:during:, and the point of this path is that no CPU surface is ever locked.

I answer for a VGVulkanPresentHostSpace and fall back to the inherited CPU frame for every other host space. The fallback is not politeness: BlHostRenderer class >> availableClasses is self allSubclasses, so I appear in Bloc's renderer setting and preferableClass can pick me for an ordinary window, and drawing that window through the inherited path is better than failing to draw it. The test is a kind-of test on the host space rather than a question asked of it, because no method of this project may be installed on a Bloc class and VGRendererTest holds that rule.

In unit 7.1 my presenting branch counts the frame and draws nothing: the window, the absence of an SDL accelerated renderer and the route a frame takes are what that unit holds. The swapchain arrives in 7.2 and the drawing in 7.4.
"
Class {
	#name : 'VGVulkanPresentRenderer',
	#superclass : 'VGRenderer',
	#instVars : [
		'frameCount',
		'backend',
		'recordingSurface'
	],
	#category : 'VectorGraphics-Vulkan-Present',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Present'
}

{ #category : 'accessing' }
VGVulkanPresentRenderer class >> label [
	"What Bloc calls this engine in its renderer setting, where availableClasses offers every
	 subclass of BlHostRenderer. Distinct from my superclass's label, which names the software
	 path that draws every other window."

	^ 'VectorGraphics on a Vulkan swapchain'
]

{ #category : 'accessing' }
VGVulkanPresentRenderer >> backend [
	"The backend every frame of mine is computed on. One instance for the life of the renderer:
	 it probes the device session per frame, so nothing is cached across a device that goes away."

	^ backend
]

{ #category : 'accessing' }
VGVulkanPresentRenderer >> backend: aBackend [
	"Draw my frames on that backend instead of the one I built. The tests of the presented path
	 substitute a backend that refuses host pixels, which is how they prove a frame reaches the
	 swapchain image without a copy through host memory."

	backend := aBackend
]

{ #category : 'drawing' }
VGVulkanPresentRenderer >> dispatchOfSpace: aSpace forExtent: anExtent [
	"The frame of that space computed on the device, answered as the dispatch that holds it.
	 The whole space is drawn and the damaged rectangle ignored: an acquired image is not the
	 frame before it, so a partial frame would leave the rest of it undefined.
	 A device that fails takes the frame with it — the backend class is rejected, as a surface
	 rejects it on a failover, and nil is answered, which the host space presents as the frame
	 with nothing drawn. Nothing is drawn on the processor instead: a window of this host has no
	 surface to lock, and the frame after this one probes the device again."

	| surface |
	surface := self recordingSurfaceForExtent: anExtent.
	aeCanvas prepareForSurface: surface.
	aeCanvas clippingRectangle: (0 @ 0 extent: anExtent / scaleFactor).
	scaleFactor > 1.0 ifTrue: [ aeCanvas setLowQualityOptions ].
	aSpace aeFullDrawOn: aeCanvas.
	aeCanvas removeSurface.
	^ [
	  surface displayList replayOn: backend.
	  backend dispatchOfRecordedFrameForExtent: anExtent ]
		  on: VGBackendFailure
		  do: [ :failure |
			  VGBackend reject: failure backend class.
			  nil ]
]

{ #category : 'accessing' }
VGVulkanPresentRenderer >> frameCount [
	"How many frames I have presented since I was last initialised for a host space. Unit 7.1
	 reads it to see which route a frame took, because that unit presents nothing yet."

	^ frameCount
]

{ #category : 'initialization' }
VGVulkanPresentRenderer >> initialize [
	"A renderer is initialised again on every window resize, so the surface of the frame before
	 is released here and not left behind."

	super initialize.
	frameCount := 0.
	self releaseRecordingSurface.
	backend := VGVulkanBackend new
]

{ #category : 'inspector' }
VGVulkanPresentRenderer >> inspectorPresent: aBuilder [
	"What this renderer has drawn and what it would draw the next frame with: the frames it
	 took, the backend of those frames and whether selection still holds it, and the surface the
	 frame is recorded on with the device scale it carries. Reads presentReport, so it cannot
	 drift from what the renderer answers, and writes nothing."

	<inspectorPresentationOrder: 10 title: 'Present'>
	^ aBuilder newTable
		  addColumn:
			  (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn:
			  (SpStringTableColumn title: 'Value' evaluated: [ :each | each value ]);
		  items: self presentReport;
		  yourself
]

{ #category : 'inspector' }
VGVulkanPresentRenderer >> inspectorPresentContext: aContext [
	"Always: a renderer that has drawn no frame yet is exactly what the tab is read for, and a
	 renderer whose device has gone answers every row as well."

	aContext active: true
]

{ #category : 'reporting' }
VGVulkanPresentRenderer >> presentReport [
	"What this renderer is and what it has drawn, each row asking the live object. The backend
	 is asked whether it can draw at all, because a renderer whose device has gone answers
	 frames of nothing and the count alone would not say so."

	| surface |
	surface := recordingSurface.
	^ {
		  ('frames taken' -> frameCount printString).
		  ('backend' -> backend class name asString).
		  ('backend is candidate' -> backend class isCandidate printString).
		  ('backend in selection'
		   -> (VGBackend rejectedClasses includes: backend class) not
				   printString).
		  ('recording surface' -> (surface
			    ifNil: [ 'none yet' ]
			    ifNotNil: [ :each | each extent printString ])).
		  ('device scale' -> (surface
			    ifNil: [ 'none yet' ]
			    ifNotNil: [ :each | each deviceScale printString ])).
		  ('scale factor' -> scaleFactor printString).
		  ('valid' -> self isValid printString) }
]

{ #category : 'private' }
VGVulkanPresentRenderer >> recordingSurfaceForExtent: anExtent [
	"The surface the frame is recorded on, one per drawable and kept between frames: a frame
	 of a window is recorded on it and replayed on the device, so its own pixels are never
	 drawn and never read. It carries the scale factor as a device scale, which is what turns
	 a frame drawn in space coordinates into the device-space segments the encoding bins.
	 A drawable of another extent or another scale is another surface, and the one before it is
	 finished here for the same reason as in initialize."

	| scale |
	scale := scaleFactor @ scaleFactor.
	(recordingSurface notNil and: [
		 recordingSurface extent = anExtent and: [
			 recordingSurface deviceScale = scale ] ]) ifTrue: [
		^ recordingSurface ].
	self releaseRecordingSurface.
	recordingSurface := VGCairoImageSurface extent: anExtent.
	recordingSurface deviceScale: scale.
	^ recordingSurface
]

{ #category : 'private' }
VGVulkanPresentRenderer >> releaseRecordingSurface [
	"The surface of the frame before holds Cairo memory of the size of a drawable, so it is
	 finished here rather than left to the garbage collector. The slot is cleared as well: a
	 finished surface answers its extent as it did, so a surface left in the slot would be
	 handed back to the next frame of that extent and drawn on after it was finished."

	recordingSurface ifNotNil: [ :surface | surface finish ].
	recordingSurface := nil
]

{ #category : 'frames' }
VGVulkanPresentRenderer >> render: aHostSpace [
	"A frame of a presenting window: the space drawn on the device and the result presented
	 through the host space, where BARenderer locks a surface and draws on the processor. A host
	 space whose frames do not come from the device is drawn by the inherited CPU frame, because
	 BlHostRenderer class >> availableClasses is self allSubclasses: I appear in Bloc's renderer
	 setting and preferableClass can pick me for an ordinary window, which has to be drawn
	 rather than refused.
	 The three early answers are my superclass's — an invalid renderer, a host space with no
	 space, and a space with nothing dirty — and the dirty elements are cleared whatever the
	 frame does. The frame is counted before it is drawn, so that a frame the device refuses is
	 counted too: the count is of frames this renderer took, not of frames the device drew."

	| space |
	aHostSpace presentsFramesOnDevice ifFalse: [ ^ super render: aHostSpace ].
	self isValid ifFalse: [ ^ self ].
	space := aHostSpace space.
	space ifNil: [ ^ self ].
	space hasDirtyElements ifFalse: [ ^ self ].
	[
	frameCount := frameCount + 1.
	aHostSpace
		presentFrameFor: space damagedRectangle
		scaleFactor: scaleFactor
		during: [ :image | self dispatchOfSpace: space forExtent: image extent ] ]
		ensure: [ space clearDirtyElements ]
]
