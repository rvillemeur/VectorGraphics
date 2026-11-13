Extension { #name : 'AeCairoFontOptions' }

{ #category : '*VectorGraphics-Bloc' }
AeCairoFontOptions >> hintsMetrics [
	"Whether a measurement taken under me is rounded to whole pixels. An extension in this
	 project's own package, because Alexandrie's classes are never edited here: VGScaledFont is
	 handed one of these whenever Alexandrie's canvas builds it instead of VGCanvas, and asks its
	 options record this one question. VGFontOptions answers it about our own record.

	 CAIRO_HINT_METRICS_DEFAULT reads as off, the same reading VGFontOptions takes of its own
	 default."

	^ self hintMetrics = AeCairoHintMetrics on
]
