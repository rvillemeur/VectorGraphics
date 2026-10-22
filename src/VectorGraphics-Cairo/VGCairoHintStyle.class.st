"
I name the values of Cairo's cairo_hint_style_t, under the names Alexandrie's AeCairoHintStyle calls
them by, so that a drawing written against Alexandrie reads the same when it is run through this
package.

My class side answers one value per name: `VGCairoHintStyle slight`, `VGCairoHintStyle full`, and
the rest. A value is the name itself, as a symbol, because that is the representation VGFontOptions
keeps and `VGFontOptions class >> nameFor:in:` accepts. `names` reads the names from VGFontOptions
rather than listing them again, so the two cannot drift apart, and VGCairoTextTest holds every value
against that list.

Asking for a hint style says what a drawing wanted; it does not make this engine hint. The glyph
raster here is unhinted, which unit 1.8 measured against FreeType, so an experiment that asks for
hinting is compared with Cairo under the tolerance VGAlexandrieCorpus states for it.
"
Class {
	#name : 'VGCairoHintStyle',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'constants' }
VGCairoHintStyle class >> default [
	^ #default
]

{ #category : 'constants' }
VGCairoHintStyle class >> full [
	^ #full
]

{ #category : 'constants' }
VGCairoHintStyle class >> medium [
	^ #medium
]

{ #category : 'constants' }
VGCairoHintStyle class >> names [
	"The names of cairo_hint_style_t, read from the option that keeps them, so that a name
	 cannot drift between the two."

	^ VGFontOptions hintStyleNames
]

{ #category : 'constants' }
VGCairoHintStyle class >> none [
	^ #none
]

{ #category : 'constants' }
VGCairoHintStyle class >> slight [
	^ #slight
]
