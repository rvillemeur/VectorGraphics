"
I hold the example of the SDL2 host a Bloc space finds while PharoVulkan's driver is installed.

Bloc's own SDL2 host compares the installed driver's class name with `#OSSDL2Driver`, so it stands down while `PVVulkanDriver` — a subclass of that driver — is installed, and a space opened then falls back to the Morphic host. One click answers the host that stands in for it, and its `Host` tab names the rule and what holds in the image now.

The click builds a registry of its own and restores the driver and the host singleton, so it leaves the image as it found it.

See `VGVulkanDriverSdl2Host` and `PVVulkanDriver`.
"
Class {
	#name : 'VGVulkanDriverSdl2HostExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGVulkanDriverSdl2HostExamples class >> hostOfferedWhileTheVulkanDriverIsInstalled [
	<sampleInstance>
	"One click: the SDL2 host a Bloc space finds while PharoVulkan's driver is installed. The
	 Host tab is the point of the click — it names the driver this host answers to, the driver
	 installed now, and which of the two SDL2 hosts a space would be given.
	 The registry asked is a fresh one and the driver is put back when the block ends, so the
	 click does not change the driver, the registry or the host singleton of this image."

	| host |
	host := PVVulkanDriver installDuring: [
		        BlHostRegistry new availableHosts detect: [ :each |
			        each isKindOf: BlOSWindowSDL2Host ] ].
	VGVulkanDriverSdl2Host cleanUp.
	^ host
]
