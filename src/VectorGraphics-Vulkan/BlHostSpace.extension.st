Extension { #name : 'BlHostSpace' }

{ #category : '*VectorGraphics-Vulkan' }
BlHostSpace >> presentsFramesOnDevice [
	"False: a host space of Bloc's own has its frames drawn on the processor and handed to a
	 surface it locks. The extension is here rather than upstream because the question belongs
	 to this project, and it is asked of the host space rather than tested for a class so that
	 VGVulkanPresentRenderer, which Bloc's renderer setting can pick for any window, needs no
	 edit when another host space of this project starts presenting frames itself."

	^ false
]
