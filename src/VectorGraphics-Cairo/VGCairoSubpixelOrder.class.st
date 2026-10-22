"
I name the values of Cairo's cairo_subpixel_order_t, under the names Alexandrie's
AeCairoSubpixelOrder calls them by, so that a drawing written against Alexandrie reads the same when
it is run through this package.

My class side answers one value per name: `VGCairoSubpixelOrder rgb`, `VGCairoSubpixelOrder vbgr`,
and the rest. A value is the name itself, as a symbol, because that is the representation
VGFontOptions keeps and `VGFontOptions class >> nameFor:in:` accepts. `names` reads the names from
VGFontOptions rather than listing them again, so the two cannot drift apart, and VGCairoTextTest
holds every value against that list.

The order is carried and not acted on: this engine rasterises a glyph as a single coverage mask, so
no value here makes it write subpixel coverage.
"
Class {
	#name : 'VGCairoSubpixelOrder',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'constants' }
VGCairoSubpixelOrder class >> bgr [
	^ #bgr
]

{ #category : 'constants' }
VGCairoSubpixelOrder class >> default [
	^ #default
]

{ #category : 'constants' }
VGCairoSubpixelOrder class >> names [
	"The names of cairo_subpixel_order_t, read from the option that keeps them, so that a name
	 cannot drift between the two."

	^ VGFontOptions subpixelOrderNames
]

{ #category : 'constants' }
VGCairoSubpixelOrder class >> rgb [
	^ #rgb
]

{ #category : 'constants' }
VGCairoSubpixelOrder class >> vbgr [
	^ #vbgr
]

{ #category : 'constants' }
VGCairoSubpixelOrder class >> vrgb [
	^ #vrgb
]
