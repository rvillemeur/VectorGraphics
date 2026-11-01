"
I hold the example of the host whose window carries a Vulkan swapchain and no SDL accelerated renderer.

`VGVulkanPresentHost` is the third SDL2 host of this project. Bloc's own host answers under the stock driver; `VGVulkanDriverSdl2Host` answers under `PVVulkanDriver` and still draws its frames into a CPU surface; this one answers under that driver while it is enabled, and its host space refuses the CPU surface lock altogether. One click answers the host a fresh registry offers in that state, and its `Present` tab names which of the three answers now.

The click builds a registry of its own, and restores the driver, the enabling flag and the host singleton, so it leaves the image as it found it.

See `VGVulkanPresentHost`, `VGVulkanPresentHostSpace` and `VGVulkanDriverSdl2Host`.
"
Class {
	#name : 'VGVulkanPresentHostExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Examples-Examples',
	#package : 'VectorGraphics-Vulkan-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGVulkanPresentHostExamples class >> hostOfferedWhileThePresentHostIsEnabled [
	<sampleInstance>
	"One click: the SDL2 host a Bloc space finds while PharoVulkan's driver is installed and this
	 project's presenting host is enabled. The Present tab is the point of the click — it names
	 which of the three SDL2 hosts answers now and which renderer the one answering builds.
	 The registry asked is a fresh one, and the driver, the flag and the host singleton are put
	 back when the blocks end, so the click changes nothing in this image."

	| host |
	host := PVVulkanDriver installDuring: [
		        VGVulkanPresentHost enableDuring: [
			        BlHostRegistry new availableHosts detect: [ :each |
				        each isKindOf: VGVulkanPresentHost ] ] ].
	VGVulkanPresentHost cleanUp.
	^ host
]
