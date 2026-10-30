"
I hold the fact that makes a Bloc window possible while PharoVulkan's driver is installed: an SDL2 host is still offered.

Bloc decides whether its SDL2 host can run by comparing the installed OSWindow driver's class name with #OSSDL2Driver, so a subclass of that driver — which PVVulkanDriver is — hides the host and leaves a Bloc space with the Morphic host instead. VGVulkanDriverSdl2Host stands in for exactly that case. I hold both halves of the swap: Bloc's own host goes away, mine appears, and the two are never supported at once.
"
Class {
	#name : 'VGVulkanDriverSdl2HostTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
VGVulkanDriverSdl2HostTest >> tearDown [
	"Asking a registry which hosts are available builds the singleton of every supported host,
	 and BlOSWindowSDL2Host class >> default registers that singleton in the image's own
	 registry too. Mine must not stay there once the driver it answers to is gone."

	VGVulkanDriverSdl2Host cleanUp.
	super tearDown
]

{ #category : 'tests' }
VGVulkanDriverSdl2HostTest >> testAnSdl2HostIsAvailableWhileTheVulkanDriverIsInstalled [
	"What all of this is for: a space opened while the Vulkan driver is installed still finds a
	 window host, not the Morphic fallback. The registry is built fresh rather than refreshed,
	 because refreshing the image's own registry stops the hosts it then prunes."

	| hosts |
	hosts := PVVulkanDriver installDuring: [ BlHostRegistry new availableHostClasses ].
	self assert: (hosts anySatisfy: [ :each | each includesBehavior: BlOSWindowSDL2Host ])
]

{ #category : 'tests' }
VGVulkanDriverSdl2HostTest >> testBlocsOwnSdl2HostIsLostWhileTheVulkanDriverIsInstalled [
	"The reason my subject exists, held as a fact rather than written in a comment. If Bloc ever
	 asks whether the driver is a kind of OSSDL2Driver instead of comparing its class name, this
	 test fails and VGVulkanDriverSdl2Host can go."

	PVVulkanDriver installDuring: [
		self deny: BlOSWindowSDL2Host isSupported ]
]

{ #category : 'tests' }
VGVulkanDriverSdl2HostTest >> testExactlyOneSdl2HostIsSupportedUnderEitherDriver [
	"Which SDL2 host the registry picks must never be a coin toss, so the two cases partition:
	 under the stock driver Bloc's host answers supported, under PharoVulkan's driver mine does."

	| sdl2Hosts supported |
	sdl2Hosts := BlOSWindowSDL2Host withAllSubclasses.
	supported := [ sdl2Hosts select: [ :each | each isSupported ] ].
	self
		withDriverClass: OSSDL2Driver
		during: [ self assert: supported value asArray equals: { BlOSWindowSDL2Host } ].
	PVVulkanDriver installDuring: [
		self assert: supported value asArray equals: { VGVulkanDriverSdl2Host } ]
]

{ #category : 'tests' }
VGVulkanDriverSdl2HostTest >> testTheHostIsNotSupportedWhileTheStockDriverIsInstalled [
	"The degenerate case. Bloc's own host covers the stock driver, so mine must stand back."

	self withDriverClass: OSSDL2Driver during: [
		self deny: VGVulkanDriverSdl2Host isSupported.
		self assert: BlOSWindowSDL2Host isSupported ]
]

{ #category : 'tests' }
VGVulkanDriverSdl2HostTest >> testTheHostIsSupportedWhileTheVulkanDriverIsInstalled [

	PVVulkanDriver installDuring: [
		self assert: VGVulkanDriverSdl2Host isSupported ]
]

{ #category : 'running' }
VGVulkanDriverSdl2HostTest >> withDriverClass: aDriverClass during: aBlock [
	"Swap the OSWindow driver the way PVVulkanDriver class >> installDuring: does, for the one
	 driver class it cannot install: the stock one. The swap runs non-interactively because
	 OSWindowDriver class >> driverClass: ends with a dialog telling the user to restart the
	 image, advice that does not apply when the same method nils the cached driver instance."

	| previous |
	previous := OSWindowDriver driverClass.
	UIManager nonInteractiveDuring: [ OSWindowDriver driverClass: aDriverClass ].
	^ aBlock ensure: [
		  UIManager nonInteractiveDuring: [ OSWindowDriver driverClass: previous ] ]
]
