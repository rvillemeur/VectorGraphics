Extension { #name : 'VGBlitEntry' }

{ #category : '*VectorGraphics-Vulkan' }
VGBlitEntry >> newTiledFill [
	"The fill the tiled rasteriser draws in my place. VGSoftwareBackend >> maskWith:... walks the
	 coverage of my clip, narrowed to the rectangle of my mask under a bounded operator, and
	 scales that coverage by the alpha of the mask; VGClip >> coverageRasteriser answers that
	 coverage by filling the rectangle of its own extents through itself. So the walk is a fill of
	 that rectangle inside that clip, and what is left of me is one byte a pixel."
	"I am an extension of a Cairo class carried by the Vulkan backend, because I name
	 VGMaskedFillEntry: the engine has to load where no Vulkan driver does, so the Cairo package
	 may not name a class of this one."

	| mask narrowed rectangle |
	mask := VGCairoSurfaceMask surface: surface at: origin.
	narrowed := operator isUnbounded
		            ifTrue: [ clip ]
		            ifFalse: [ clip narrowedTo: mask boundsRectangle ].
	rectangle := narrowed extents.
	^ VGMaskedFillEntry
		  fill: (VGFillEntry
				   segments: (VGSegments rectangle: rectangle)
				   paint: paint
				   clip: narrowed
				   operator: operator)
		  sampling: mask
		  over: rectangle
]
