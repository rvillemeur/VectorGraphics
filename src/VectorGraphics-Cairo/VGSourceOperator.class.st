"
Cairo's `source`, which replaces the destination by the source instead of compositing with it.

Under a partial mask the pixel is a mix of the two by the mask, which is Cairo's own behaviour and
not something the Porter-Duff factors can state: they would scale the source by the mask and leave
the destination weighed by one minus the source's alpha. So I override
`composeSource:mask:over:in:` and interpolate.
"
Class {
	#name : 'VGSourceOperator',
	#superclass : 'VGPorterDuffOperator',
	#category : 'VectorGraphics-Cairo-Compositing',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Compositing'
}

{ #category : 'compositing' }
VGSourceOperator >> composeSource: aSourcePixel mask: aMaskByte over: aDestinationPixel in: aFormat [
	"Measured on a live Cairo context: at half coverage the source operator writes half of each
	 pixel and not a source scaled to half its alpha, so the mask is a weight between the two
	 and not a scaling of the source."

	^ aFormat
		  lerpPixel: aSourcePixel
		  over: aDestinationPixel
		  by: aMaskByte
]
