"
I hold the unit 1.1 examples: the ARGB32 target, a surface that borrows a host buffer with a
padded stride, and an A8 mask. Each example rebuilds its surface and paints it, so one click from
the browser opens an inspector whose Picture and Layout tabs show what the unit delivers.
"
Class {
	#name : 'VGCairoImageSurfaceExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGCairoImageSurfaceExamples class >> a8MaskSurface [
	<sampleInstance>
	"The format AeCanvas builds its shadow mask in: one byte of alpha per pixel, so a row of
	 seventeen pixels is padded to twenty bytes."
	| surface |
	surface := VGCairoImageSurface extent: 17 @ 8 format: VGCairoSurfaceFormat a8.
	surface newContext clearColor: (Color black alpha: 0.5).
	^ surface
]

{ #category : 'examples' }
VGCairoImageSurfaceExamples class >> hostSurfaceWithAPaddedStride [
	<sampleInstance>
	"The host hands over its own buffer and its own row pitch; the four bytes after every row stay
	 as the host left them, which the Layout tab counts."
	| width height stride buffer surface |
	width := 16.
	height := 8.
	stride := width * 4 + 4.
	buffer := ByteArray new: stride * height withAll: 16rEE.
	surface := VGCairoImageSurface
		           unownedNewForData: buffer
		           format: VGCairoSurfaceFormat argb32
		           width: width
		           height: height
		           stride: stride.
	surface newContext clearColor: (Color r: 0.1 g: 0.6 b: 0.8).
	^ surface
]

{ #category : 'examples' }
VGCairoImageSurfaceExamples class >> surfaceMaskedThroughACircleClip [
	<sampleInstance>
	"A mask painted through a clip that is a circle. The mask is opaque on its left half and half
	 translucent on its right half, and the rim of the circle is shaded, because a mask carries no
	 spans for the clip to meet and is scaled by the coverage of the clip instead."

	| surface context mask maskContext |
	mask := VGCairoImageSurface extent: 32 @ 32.
	maskContext := mask newContext.
	maskContext sourceColorR: 1.0 g: 1.0 b: 1.0 a: 1.0.
	maskContext
		rectangleX: 0 y: 0 width: 16 height: 32;
		fill.
	maskContext sourceColorR: 1.0 g: 1.0 b: 1.0 a: 0.5.
	maskContext
		rectangleX: 16 y: 0 width: 16 height: 32;
		fill.
	mask flush.
	surface := VGCairoImageSurface extent: 32 @ 32.
	context := surface newContext.
	context
		circleCenterX: 16 y: 16 radius: 10;
		clip.
	context sourceColorR: 0.0 g: 0.0 b: 1.0 a: 1.0.
	context maskSurface: mask x: 0 y: 0.
	surface flush.
	^ surface
]

{ #category : 'examples' }
VGCairoImageSurfaceExamples class >> translucentArgb32Surface [
	<sampleInstance>
	| surface |
	surface := VGCairoImageSurface extent: 64 @ 64.
	surface newContext clearColor: (Color r: 0.9 g: 0.3 b: 0.1 alpha: 0.5).
	^ surface
]
