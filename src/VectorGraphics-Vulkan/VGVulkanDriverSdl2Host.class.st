"
I am Bloc's SDL2 host, offered while PharoVulkan's Vulkan driver is installed.

`BlOSWindowSDL2Host class >> isSupported` compares the installed OSWindow driver's class name with `#OSSDL2Driver`. `PVVulkanDriver` is a subclass of that driver, so while it is installed Bloc believes SDL2 is gone, and a space opened then falls back silently to the Morphic host. SDL2 is in fact still there and every window my superclass builds works, so I answer supported in exactly that case and in no other: two SDL2 hosts supported at once would leave the registry picking between them by order alone.

I use `TBlSingletonHost` because `BlHostRegistry >> refreshAvailableHosts` registers the singleton of each class in `TBlSingletonHost users`, and that collection holds the classes that use the trait, not their subclasses. My superclass uses it too, so Renraku reports the nine class-side methods the trait copies into me — `default`, `cleanUp`, `start`, `stop` and the rest — as equivalently defined in my superclass. They are copies of the same trait, not code written here, and Tonel does not write them out.

I add nothing else. The attributes, the host space and the renderer are the ones my superclass builds.
"
Class {
	#name : 'VGVulkanDriverSdl2Host',
	#superclass : 'BlOSWindowSDL2Host',
	#traits : 'TBlSingletonHost',
	#classTraits : 'TBlSingletonHost classTrait',
	#category : 'VectorGraphics-Vulkan-Backend',
	#package : 'VectorGraphics-Vulkan',
	#tag : 'Backend'
}

{ #category : 'driver selection' }
VGVulkanDriverSdl2Host class >> isSupported [
	"Exactly the case my superclass misses: SDL2 is there and driving windows, but the installed
	 driver is PharoVulkan's subclass of OSSDL2Driver rather than that class itself, and the
	 superclass compares class names. Answering true any wider than this would leave two SDL2
	 hosts supported at once, and the registry would then pick between them by order alone."

	^ OSWindowDriver current isKindOf: PVVulkanDriver
]

{ #category : 'inspector' }
VGVulkanDriverSdl2Host >> inspectorHost: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Host'>
	"The rule I exist for, and what holds in the image at the moment the tab is drawn. Every row
	 asks the live predicate rather than restating it, so the table cannot drift from the rule.
	 Nothing here installs or registers anything: the driver and the registry are only read."

	^ aBuilder newTable
		  items: {
				  ('Driver I answer to' -> PVVulkanDriver).
				  ('Driver installed' -> OSWindowDriver current class).
				  ('I am supported now' -> self class isSupported).
				  ('Bloc''s own SDL2 host supported now' -> BlOSWindowSDL2Host isSupported).
				  ('Host a space would find now'
				   -> (BlHostRegistry default defaultHost ifNotNil: [ :each | each class ])).
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
VGVulkanDriverSdl2Host >> inspectorHostContext: aContext [

	aContext active: true
]
