"
I hold the examples of VGVulkanBackend: the backend that draws on a Vulkan device.
One click probes this machine for real, and one click draws a frame through the backend and lets the
failover finish it, which is what the recovery of unit 2.0 looks like from the outside.
Both examples put the selection state of VGBackend back as they found it, because probing and
failing are what change it.
"
Class {
	#name : 'VGVulkanBackendExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples - constants' }
VGVulkanBackendExamples class >> frameExtent [
	"Big enough that the rectangle covers many pixels and small enough that the tab draws at
	 once."

	^ 40 @ 30
]

{ #category : 'examples' }
VGVulkanBackendExamples class >> frameRecoveredFromTheVulkanBackend [
	<sampleInstance>
	"One click: a surface forced onto the Vulkan backend, drawn and flushed. The backend raises
	 before it writes a pixel, so the frame is replayed on the failover and the surface answered
	 carries the picture the software backend draws — the recovery of unit 2.0 seen from the
	 outside, in the Pixels tab of the surface.
	 The selection state is put back, because the recovery rejects the backend that failed and
	 that would otherwise hold for the rest of the session."

	| savedPreference savedRejections surface context |
	savedPreference := VGBackend preferredClassOrNil.
	savedRejections := VGBackend rejectedClasses.
	^ [ surface := VGCairoImageSurface extent: self frameExtent.
	  surface backend: VGVulkanBackend new.
	  context := surface newContext.
	  context
		  sourceColorR: 0.1 g: 0.5 b: 0.9;
		  rectangleX: 4 y: 4 width: 32 height: 22;
		  fill.
	  surface flush.
	  surface ] ensure: [
		  VGBackend
			  restorePreference: savedPreference
			  rejections: savedRejections ]
]

{ #category : 'examples' }
VGVulkanBackendExamples class >> probedOnThisMachine [
	<sampleInstance>
	"One click: the Vulkan backend probed for real. The probe compiles the compute path's own
	 example kernel, adds two vectors on the device and reads the sums back, so it answers an
	 instance where a device computes and nil where none does. Where it answers nothing this
	 answers a plain instance instead, which is what a machine with no driver would draw through
	 if anything forced one on it. The probe changes no selection state: it opens a device of its
	 own and destroys it again."

	^ VGVulkanBackend probe ifNil: [ VGVulkanBackend new ]
]
