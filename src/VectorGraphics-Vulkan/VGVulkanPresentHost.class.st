"
I am the Bloc host that opens a window PharoVulkan can present a swapchain into, and I answer for exactly one case: the Vulkan driver is installed and a caller has asked for presenting. §8 of the present plan is why the second half of that is needed — Bloc's default stays Cairo, so presenting is something a caller opts into with enableDuring: and never something an image starts doing by itself.

My superclass answers for the Vulkan driver without presenting, and the two of us together with Bloc's own host partition the three cases exactly. The partition has to be exact because BlHostRegistry >> registerHost: sorts hosts by order alone, and all three of us answer 10, so two supported SDL2 hosts would make the registry's choice between them arbitrary.

What I do differently: newAttributesFor: builds a PVWindowAttributes carrying vulkanAttributes, which is what makes PVVulkanDriver create an OSSDL2VulkanBackendWindow with SDL_WINDOW_VULKAN in its flags; newHostSpaceFor: builds a VGVulkanPresentHostSpace; and newHostRenderer answers a VGVulkanPresentRenderer. The trait is declared again here for the reason my superclass's comment gives: TBlSingletonHost users does not include subclasses, and a registry only offers the singleton of a class in that set.
"
Class {
	#name : 'VGVulkanPresentHost',
	#superclass : 'VGVulkanDriverSdl2Host',
	#traits : 'TBlSingletonHost',
	#classTraits : 'TBlSingletonHost classTrait',
	#classInstVars : [
		'enabled'
	],
	#category : 'VectorGraphics-Vulkan-Present',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Present'
}

{ #category : 'enabling' }
VGVulkanPresentHost class >> enableDuring: aBlock [
	"Presenting is opted into for the duration of a block and put back whatever the block does,
	 the way PVVulkanDriver class >> installDuring: installs its driver. The previous value is
	 restored rather than cleared, so that nesting two of these is harmless. Nothing enables it
	 for good on purpose: a host that stayed supported would change which host every window of
	 the image is given, which is what §8 of the present plan rules out."

	| previous |
	previous := enabled.
	enabled := true.
	^ aBlock ensure: [ enabled := previous ]
]

{ #category : 'testing' }
VGVulkanPresentHost class >> isEnabled [
	"Whether a caller has opted into presenting. Nil until one has, which is why this reads the
	 value rather than negating it."

	^ enabled == true
]

{ #category : 'testing' }
VGVulkanPresentHost class >> isSupported [
	"Two things at once: the driver that makes a Vulkan window possible, and a caller that has
	 asked for one. §8 of the present plan is the second half — Bloc's default stays on the
	 software path, so an image never starts presenting by itself, and every window opened inside
	 a plain PVVulkanDriver installDuring: keeps the host my superclass answers with."

	^ self respondsToVulkanDriver and: [ self isEnabled ]
]

{ #category : 'inspector' }
VGVulkanPresentHost >> inspectorPresentHost: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Present'>
	"The three-way partition this host joins, read live rather than restated: under the stock
	 driver Bloc's own SDL2 host answers, under PharoVulkan's driver with me disabled
	 `VGVulkanDriverSdl2Host` answers, and under that driver with me enabled I answer. The
	 registry sorts by `order` alone and all three answer 10, so exactly one of the three rows
	 may be true at a time. Nothing here installs, enables or registers anything; the renderer
	 row builds a renderer and drops it."

	^ aBuilder newTable
		  items: {
				  ('Driver installed' -> OSWindowDriver current class).
				  ('I am enabled' -> self class isEnabled).
				  ('I am supported now' -> self class isSupported).
				  ('CPU SDL2 host under this driver supported now'
				   -> VGVulkanDriverSdl2Host isSupported).
				  ('Bloc''s own SDL2 host supported now' -> BlOSWindowSDL2Host isSupported).
				  ('Host a space would find now'
				   -> (BlHostRegistry default defaultHost ifNotNil: [ :each | each class ])).
				  ('Renderer I build' -> self newHostRenderer class).
				  ('Spaces open on me' -> self spaces size) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGVulkanPresentHost >> inspectorPresentHostContext: aContext [
	aContext active: true
]

{ #category : 'private' }
VGVulkanPresentHost >> newAttributesFor: aSpace [
	"The attributes my superclass builds, as a PVWindowAttributes carrying vulkanAttributes: that
	 is the one thing PVVulkanDriver reads to decide whether a window is created with
	 SDL_WINDOW_VULKAN in its flags and answered as an OSSDL2VulkanBackendWindow.
	 The GL attributes the inherited method sets are dropped, because the driver adds
	 SDL_WINDOW_OPENGL to the flags of any attributes that carry them and a window presenting a
	 Vulkan swapchain has no GL context to configure. The window starts hidden for the reason
	 upstream gives: the OS must not dispatch expose or focus events before the event handler and
	 the renderer are attached."

	| theAttributes |
	theAttributes := PVWindowAttributes new
		                 title: aSpace title;
		                 extent: aSpace extent;
		                 resizable: aSpace isResizable;
		                 borderless: aSpace isBorderless;
		                 fullscreen: aSpace isFullscreen;
		                 visible: false;
		                 vulkanAttributes: OSVulkanAttributes new;
		                 yourself.
	aSpace knowsPosition
		ifTrue: [ theAttributes position: aSpace position ]
		ifFalse: [ theAttributes windowCentered: true ].
	^ theAttributes
]

{ #category : 'host space - accessing' }
VGVulkanPresentHost >> newHostRenderer [
	"Named here rather than taken from BlHostRenderer preferableClass, which is one global choice
	 for every window of the image: a presenting window is a choice made by this host, and the
	 setting that decides the others is left alone."

	^ VGVulkanPresentRenderer new
]

{ #category : 'host - api' }
VGVulkanPresentHost >> newHostSpaceFor: aSpace [
	"The cascade my superclass builds, with my own host space. The space is read for the window
	 properties alone, as upstream says, and no reference to it is kept here."

	^ VGVulkanPresentHostSpace new
		  keyboardKeyTable: self keyboardKeyTable;
		  host: self;
		  space: aSpace;
		  initializeWithAttributes: (self newAttributesFor: aSpace);
		  renderer: self newHostRenderer;
		  yourself
]
