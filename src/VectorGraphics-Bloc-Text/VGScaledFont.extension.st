Extension { #name : 'VGScaledFont' }

{ #category : '*VectorGraphics-Bloc-Text' }
VGScaledFont >> aeTextFont [
	"My adapter for the Alexandrie route, built on first use and kept: it holds the masks Cairo
	 rasterised for my glyphs, and each context of a frame poses me again. This is the one
	 selector of that package I answer; the five text verbs are the adapter's."

	<archCache: #one to: #VGAeTextFont opposite: #scaledFont>
	^ aeTextFont ifNil: [ aeTextFont := VGAeTextFont on: self ]
]
