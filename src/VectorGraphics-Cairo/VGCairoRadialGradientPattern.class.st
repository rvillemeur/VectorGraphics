"
I am a VGCairoPattern holding a colour ramp between two circles, which is how Cairo draws a radial gradient.

I answer the frozen paint ABI of rule two of VECTORCANVAS-PLAN.md, and unit 1.5 implements me.
"
Class {
	#name : 'VGCairoRadialGradientPattern',
	#superclass : 'VGCairoGradientPattern',
	#category : 'VectorGraphics-Cairo-Pattern',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Pattern'
}

{ #category : 'instance creation' }
VGCairoRadialGradientPattern class >> innerCenter: aPoint innerRadius: aRadius outerCenter: anotherPoint outerRadius: anotherRadius [
	^ (self new)
		  innerCenter: aPoint
		  innerRadius: aRadius
		  outerCenter: anotherPoint
		  outerRadius: anotherRadius;
		  yourself
]

{ #category : 'instance creation' }
VGCairoRadialGradientPattern class >> innerCenter: aPoint innerRadius: aRadius outerCenter: anotherPoint outerRadius: anotherRadius addStopsFrom: offsetColorAssociations [
	^ (self
		   innerCenter: aPoint
		   innerRadius: aRadius
		   outerCenter: anotherPoint
		   outerRadius: anotherRadius)
		  addStopsFrom: offsetColorAssociations;
		  yourself
]

{ #category : 'accessing' }
VGCairoRadialGradientPattern class >> paintClass [
	^ VGRadialGradientPaint
]

{ #category : 'initialization' }
VGCairoRadialGradientPattern >> innerCenter: aPoint innerRadius: aRadius outerCenter: anotherPoint outerRadius: anotherRadius [
	paint
		innerCenter: aPoint
		innerRadius: aRadius
		outerCenter: anotherPoint
		outerRadius: anotherRadius
]
