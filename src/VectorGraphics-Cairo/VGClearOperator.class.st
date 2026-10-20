"
Cairo's `clear`, which leaves nothing where it draws.

The source is ignored and the mask alone decides: a full mask clears the pixel, a partial one
leaves that much of the destination standing, and no mask at all leaves the pixel alone. That is
why I override `composeSource:mask:over:in:` rather than inherit the Porter-Duff factors — the
factors would read the source's alpha, which `clear` has no business reading.
"
Class {
	#name : 'VGClearOperator',
	#superclass : 'VGPorterDuffOperator',
	#category : 'VectorGraphics-Cairo-Compositing',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Compositing'
}

{ #category : 'compositing' }
VGClearOperator >> composeSource: aSourcePixel mask: aMaskByte over: aDestinationPixel in: aFormat [
	"Measured on a live Cairo context: clearing a pixel the shape covers by half leaves half of
	 the destination standing, so the mask weighs the destination here rather than scaling a
	 source that clear does not read at all. Cairo reaches the same place by compositing the
	 coverage out of the destination instead of clearing under it."

	^ aFormat pixel: aDestinationPixel scaledBy: 255 - aMaskByte
]
