"
I hold the `<sampleInstance>` examples of `VGCairoStrokeStyle`, the object that carries a context's line width, cap, join, miter limit and dash pattern.

Each example rebuilds its style from scratch and asserts nothing, so it can be run with one click from the browser and inspected. The two inspector views of the style, `Style` and `Dash cycle`, are what the examples are there to show: `Dash cycle` writes out the cycle the stroker really walks, which is the pattern doubled when its size is odd.

`dashedStrokeStyle` and `oddDashStrokeStyle` are the two to compare: the first has an even pattern and a period equal to its sum, the second an odd one whose period is twice its sum.
"
Class {
	#name : 'VGCairoStrokeStyleExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGCairoStrokeStyleExamples class >> dashedStrokeStyle [
	<sampleInstance>
	"Nine on and four off, started two into the cycle. The period is thirteen, so an offset of
	 fifteen would draw the same picture."

	^ VGCairoStrokeStyle new
		  lineWidth: 5.0;
		  dashPattern: #( 9 4 ) offset: 2;
		  yourself
]

{ #category : 'examples' }
VGCairoStrokeStyleExamples class >> defaultStrokeStyle [
	<sampleInstance>
	"The style a fresh context carries: two user units wide, a butt cap, a miter join, a miter
	 limit of ten and no dash at all. Every one of those numbers is measured against a live
	 Cairo context in VGCairoStrokeTest."

	^ VGCairoStrokeStyle new
]

{ #category : 'examples' }
VGCairoStrokeStyleExamples class >> dottedStrokeStyle [
	<sampleInstance>
	"The pattern Cairo's own documentation offers for a dotted line: a run of no length under a
	 round cap, which paints the disc and nothing between one dot and the next."

	^ VGCairoStrokeStyle new
		  lineWidth: 6.0;
		  lineCap: #round;
		  dashPattern: #( 0 12 ) offset: 0;
		  yourself
]

{ #category : 'examples' }
VGCairoStrokeStyleExamples class >> oddDashStrokeStyle [
	<sampleInstance>
	"A pattern of one length: Cairo writes the cycle out twice, so four on and four off is what
	 the walk really reads and the period is eight rather than four."

	^ VGCairoStrokeStyle new
		  lineWidth: 4.0;
		  dashPattern: #( 4 ) offset: 0;
		  yourself
]

{ #category : 'examples' }
VGCairoStrokeStyleExamples class >> roundStrokeStyle [
	<sampleInstance>
	"A wide stroke with a round cap and a round join, which is the one pair that needs no
	 orientation: a disc serves for both."

	^ VGCairoStrokeStyle new
		  lineWidth: 12.0;
		  lineCap: #round;
		  lineJoin: #round;
		  yourself
]

{ #category : 'examples' }
VGCairoStrokeStyleExamples class >> tightMiterStrokeStyle [
	<sampleInstance>
	"A miter limit of one and a quarter, which is under the square root of two a right angle
	 needs, so Cairo draws the bevel at every corner sharper than a right angle."

	^ VGCairoStrokeStyle new
		  lineWidth: 8.0;
		  miterLimit: 1.25;
		  yourself
]
