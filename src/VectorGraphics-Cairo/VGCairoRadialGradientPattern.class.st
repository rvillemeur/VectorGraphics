"
I am a VGCairoPattern holding a colour ramp between two circles, which is how Cairo draws a radial gradient.

I answer the frozen paint ABI of rule two of VECTORCANVAS-PLAN.md, and unit 1.5 implements me.
"
Class {
	#name : 'VGCairoRadialGradientPattern',
	#superclass : 'VGCairoPattern',
	#category : 'VectorGraphics-Cairo-Pattern',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Pattern'
}

{ #category : 'skeleton' }
VGCairoRadialGradientPattern class >> innerCenter: anArgument1 innerRadius: anArgument2 outerCenter: anArgument3 outerRadius: anArgument4 [
	^ self notYetImplementedIn: '1.5' selector: #innerCenter:innerRadius:outerCenter:outerRadius:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoRadialGradientPattern class >> innerCenter: arg1 innerRadius: arg2 outerCenter: arg3 outerRadius: arg4 addStopsFrom: arg5 [
	^ self notYetImplementedIn: '1.5' selector: #innerCenter:innerRadius:outerCenter:outerRadius:addStopsFrom:
]
