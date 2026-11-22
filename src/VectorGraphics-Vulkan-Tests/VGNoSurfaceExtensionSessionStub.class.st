"
I am a session on a machine whose window system names no surface instance extension, by
construction: no display at all, or an SDL that finds no Vulkan loader. Host selection must
refuse the presenting host on such a machine, and a test holds that here without depending on
the machine it runs on.
"
Class {
	#name : 'VGNoSurfaceExtensionSessionStub',
	#superclass : 'VGVulkanDeviceSession',
	#category : 'VectorGraphics-Vulkan-Tests-Fixtures',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Fixtures'
}

{ #category : 'private' }
VGNoSurfaceExtensionSessionStub >> surfaceInstanceExtensionNames [
	"Nothing, which is what SDL answers where it cannot name the extensions a surface needs."

	^ nil
]
