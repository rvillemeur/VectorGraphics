"
I hold the one-click examples for the compositing operators, which are what decides how a paint
meets the pixel already on the surface.

Each of my examples rebuilds its operator on every call and asserts nothing. Between them they show
the four behaviours worth looking at: `over`, the one every context starts in; `clear`, which
ignores its source, runs over the whole clip and takes a paint's alpha as a mask; `multiply`, the
blend mode pixman gives an eight-bit combiner of its own, with a rounding per part; and
`colorDodge` and `saturate`, two of the eight whose arithmetic divides and which pixman therefore
composites in floating point. Open the Combiners tab of `VGCairoOperator` to see that split for all
twenty-nine at once.
"
Class {
	#name : 'VGCairoOperatorExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGCairoOperatorExamples class >> clear [
	<sampleInstance>
	"The operator that leaves nothing behind. Its Compositing tab is the one place the two odd
	 things about it show at once: it writes a different pixel at a coverage of nothing, which is
	 what makes Cairo run it over the whole clip, and the source it is handed makes no difference
	 to any row."
	^ VGCairoOperator clear
]

{ #category : 'examples' }
VGCairoOperatorExamples class >> colorDodge [
	<sampleInstance>
	"A blend mode whose arithmetic divides, so pixman keeps no eight-bit combiner for it and
	 composites it in floating point. The source reaches it as four sixteen-bit shorts and the
	 result is stored by truncating a multiple of two hundred and fifty-six, which is a different
	 rounding from the eight-bit route."
	^ VGCairoOperator colorDodge
]

{ #category : 'examples' }
VGCairoOperatorExamples class >> multiply [
	<sampleInstance>
	"The blend mode pixman gives a combiner of its own: it rounds the backdrop part, the source
	 part and the blend part separately, where the other seven eight-bit modes round their sum
	 once. That one difference is worth a byte in the written pixel."
	^ VGCairoOperator multiply
]

{ #category : 'examples' }
VGCairoOperatorExamples class >> over [
	<sampleInstance>
	"The operator every Cairo context starts in, and the one the Compositing tab is easiest to
	 read on: the source arrives scaled by the mask and what is left of the destination shows
	 through it."
	^ VGCairoOperator over
]

{ #category : 'examples' }
VGCairoOperatorExamples class >> saturate [
	<sampleInstance>
	"The one operator outside the blend modes that pixman composites in floating point: it scales
	 the source by however much room the destination's alpha leaves, which is a division, so no
	 eight-bit combiner exists for it either."
	^ VGCairoOperator saturate
]
