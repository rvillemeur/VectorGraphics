"
I am a VGCairoPattern holding a colour ramp along the line between two points.

I answer the frozen paint ABI of rule two of VECTORCANVAS-PLAN.md, and unit 1.5 implements me.
"
Class {
	#name : 'VGCairoLinearGradientPattern',
	#superclass : 'VGCairoGradientPattern',
	#category : 'VectorGraphics-Cairo-Pattern',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Pattern'
}

{ #category : 'instance creation' }
VGCairoLinearGradientPattern class >> from: aPoint to: anotherPoint [
	^ (self new)
		  from: aPoint to: anotherPoint;
		  yourself
]

{ #category : 'instance creation' }
VGCairoLinearGradientPattern class >> from: aPoint to: anotherPoint addStopsFrom: offsetColorAssociations [
	^ (self from: aPoint to: anotherPoint)
		  addStopsFrom: offsetColorAssociations;
		  yourself
]

{ #category : 'accessing' }
VGCairoLinearGradientPattern class >> paintClass [
	^ VGLinearGradientPaint
]

{ #category : 'initialization' }
VGCairoLinearGradientPattern >> from: aPoint to: anotherPoint [
	paint from: aPoint to: anotherPoint
]
