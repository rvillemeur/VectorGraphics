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
VGCairoImageSurfaceExamples class >> translucentArgb32Surface [
	<sampleInstance>
	| surface |
	surface := VGCairoImageSurface extent: 64 @ 64.
	surface newContext clearColor: (Color r: 0.9 g: 0.3 b: 0.1 alpha: 0.5).
	^ surface
]
