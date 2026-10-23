Extension { #name : 'VGDisplayListEntry' }

{ #category : '*VectorGraphics-Vulkan' }
VGDisplayListEntry >> asTiledFill [
	"The fill the tiled rasteriser draws in my place. I am already one, so I am my own: the
	 conversion is here and not in VectorGraphics-Cairo because it is the tiled rasteriser that
	 needs every entry of a frame to carry a path, and nothing else in the engine does."

	^ self
]

{ #category : '*VectorGraphics-Vulkan' }
VGDisplayListEntry >> tiledMaskByteAtX: anX y: aRow [
	"The byte the tiled rasteriser scales my coverage by, which for every entry but a blit is
	 full alpha: scaling by it changes no byte, so both paths can scale without asking what kind
	 of entry they hold. See VGMaskedFillEntry, which answers the alpha of its mask here."

	^ VGTiledFillEncoding fullAlphaByte
]

{ #category : '*VectorGraphics-Vulkan' }
VGDisplayListEntry >> tiledMaskBytes [
	"The alpha of my mask over that rectangle, one byte a pixel, which for every entry but a
	 blit is no byte at all."

	^ #[  ]
]

{ #category : '*VectorGraphics-Vulkan' }
VGDisplayListEntry >> tiledMaskRectangle [
	"The rectangle the tiled rasteriser reads my mask over, which for every entry but a blit is
	 the empty one: I have no mask, and an empty rectangle is what says so. The conversion is
	 here and not in VectorGraphics-Cairo because the mask buffers are the tiled rasteriser''s
	 own layout."

	^ VGTiledFillEncoding emptyMaskRectangle
]
