"
I hold the unit 1.9 blur examples: an alpha mask with a shape in it, and the filter that has
blurred it.
One click from the browser opens an inspector whose Mask tab shows the blurred alpha and whose
Box radii tab shows what the three box passes of a radius are.
"
Class {
	#name : 'VGA8GaussianBlurFilterExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGA8GaussianBlurFilterExamples class >> blurredDot [
	<sampleInstance>
	"A single opaque pixel in the middle of an alpha mask, blurred: the point spread of the filter
	 itself, which is what a shadow of any shape is built from."

	| surface filter |
	surface := VGCairoImageSurface extent: 48 @ 48 format: VGCairoSurfaceFormat a8.
	surface pixelAtX: 24 y: 24 put: 255.
	filter := VGA8GaussianBlurFilter new.
	filter surface: surface.
	filter applySigma: 4.
	^ filter
]

{ #category : 'examples' }
VGA8GaussianBlurFilterExamples class >> blurredShadowOfARoundedRectangle [
	<sampleInstance>
	"The shadow Bloc builds: a shape drawn opaque into an alpha mask, then blurred by the radius
	 the shadow effect carries."

	| surface context filter |
	surface := VGCairoImageSurface extent: 64 @ 48 format: VGCairoSurfaceFormat a8.
	context := surface newContext.
	context sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
	context
		roundedRectangleLeft: 12 top: 10 right: 52 bottom: 38 tl: 8 tr: 8 br: 8 bl: 8;
		fill.
	surface flush.
	filter := VGA8GaussianBlurFilter new.
	filter surface: surface.
	filter applyRadius: 10.
	^ filter
]
