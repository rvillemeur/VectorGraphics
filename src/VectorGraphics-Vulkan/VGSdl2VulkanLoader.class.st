"
The one SDL function this project needs and PharoVulkan does not declare: SDL_Vulkan_LoadLibrary.
SDL loads the Vulkan loader by itself when the first SDL_WINDOW_VULKAN window is created, and
until it is loaded SDL_Vulkan_GetInstanceExtensions answers false. VGVulkanDeviceSession reads
the surface extension names before any window exists, so it sends #ensureDefaultLibraryLoaded
first. The call is reference counted inside SDL and nothing here unloads it, because the loader
is wanted for the rest of the image run.
"
Class {
	#name : 'VGSdl2VulkanLoader',
	#superclass : 'Object',
	#category : 'VectorGraphics-Vulkan-Backend',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Backend'
}

{ #category : 'accessing' }
VGSdl2VulkanLoader class >> ensureDefaultLibraryLoaded [
	"Whether SDL holds the Vulkan loader now. SDL loads it when the first SDL_WINDOW_VULKAN
	 window is created, so a read of the instance extensions before any window exists has to
	 ask for it. The call is reference counted inside SDL and nothing here unloads it, because
	 the loader is wanted for the rest of the image run. False where SDL cannot find a loader
	 at all, which is a machine that cannot present."

	^ [ (self loadLibraryNamed: ExternalAddress null) = self loadLibrarySuccess ]
		  on: Error
		  do: [ :failure | false ]
]

{ #category : 'ffiLibrary' }
VGSdl2VulkanLoader class >> ffiLibrary [

	^ SDL2Library
]

{ #category : 'private' }
VGSdl2VulkanLoader class >> loadLibraryNamed: aPathOrNull [
	"A null path asks SDL for its own default Vulkan loader, which is what this project wants:
	 the loader the window system will use for a surface."

	^ self ffiCall: #( int SDL_Vulkan_LoadLibrary ( void* aPathOrNull ) )
]

{ #category : 'constants' }
VGSdl2VulkanLoader class >> loadLibrarySuccess [
	"SDL_Vulkan_LoadLibrary answers 0 on success and -1 on failure."

	^ 0
]
