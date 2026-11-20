Extension { #name : 'Color' }

{ #category : '*VectorGraphics-Canvas-Raster' }
Color >> asVGChannels [
	"My four channels as floats in zero to one. An extension on Color, in the renderer's own
	 package, because this is where the quantisation of a colour stops: a Pharo Color stores ten
	 bits a channel, and every interpolation past this point is in floating point, which is what
	 live Cairo does. Alexandrie reads the same four accessors off the same Color, so an input
	 colour quantises identically on both sides. It lives here rather than on VGPaint so that
	 VGCoonsPatch can convert a corner colour without naming a class of the canvas, which is
	 what keeps VectorGraphics-Canvas-Raster a package that depends on nothing."

	^ {
		  self red asFloat.
		  self green asFloat.
		  self blue asFloat.
		  self alpha asFloat }
]
