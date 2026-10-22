"
I name the values of Cairo's cairo_hint_metrics_t, under the names Alexandrie's AeCairoHintMetrics
calls them by, so that a drawing written against Alexandrie reads the same when it is run through
this package.

My class side answers one value per name: `VGCairoHintMetrics on` and `VGCairoHintMetrics off`,
beside the default. A value is the name itself, as a symbol, because that is the representation
VGFontOptions keeps and `VGFontOptions class >> nameFor:in:` accepts. `names` reads the names from
VGFontOptions rather than listing them again, so the two cannot drift apart, and VGCairoTextTest
holds every value against that list.

Whether a scaled font then rounds its metrics is VGFontOptions' own answer, `hintsMetrics`, which
treats Cairo's default as off, as the FreeType font backend does.
"
Class {
	#name : 'VGCairoHintMetrics',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'constants' }
VGCairoHintMetrics class >> default [
	^ #default
]

{ #category : 'constants' }
VGCairoHintMetrics class >> names [
	"The names of cairo_hint_metrics_t, read from the option that keeps them, so that a name
	 cannot drift between the two."

	^ VGFontOptions hintMetricsNames
]

{ #category : 'constants' }
VGCairoHintMetrics class >> off [
	^ #off
]

{ #category : 'constants' }
VGCairoHintMetrics class >> on [
	^ #on
]
