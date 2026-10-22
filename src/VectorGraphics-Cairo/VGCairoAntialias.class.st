"
I name the values of Cairo's cairo_antialias_t, under the names Alexandrie's AeCairoAntialias calls
them by, so that a drawing written against Alexandrie reads the same when it is run through this
package.

My class side answers one value per name: `VGCairoAntialias gray`, `VGCairoAntialias fast`, and the
rest. A value is the name itself, as a symbol, because that is the representation VGFontOptions
keeps and `VGFontOptions class >> nameFor:in:` accepts. `names` reads the names from VGFontOptions
rather than listing them again, so the two cannot drift apart, and VGCairoTextTest holds every value
against that list.
"
Class {
	#name : 'VGCairoAntialias',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'constants' }
VGCairoAntialias class >> best [
	^ #best
]

{ #category : 'constants' }
VGCairoAntialias class >> default [
	^ #default
]

{ #category : 'constants' }
VGCairoAntialias class >> fast [
	^ #fast
]

{ #category : 'constants' }
VGCairoAntialias class >> good [
	^ #good
]

{ #category : 'constants' }
VGCairoAntialias class >> gray [
	^ #gray
]

{ #category : 'constants' }
VGCairoAntialias class >> names [
	"The names of cairo_antialias_t, read from the option that keeps them, so that a name
	 cannot drift between the two."

	^ VGFontOptions antialiasNames
]

{ #category : 'constants' }
VGCairoAntialias class >> none [
	^ #none
]

{ #category : 'constants' }
VGCairoAntialias class >> subpixel [
	^ #subpixel
]
