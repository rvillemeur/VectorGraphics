"
I am the replacement for AeCairoContext: the paint API that Bloc and AeCanvas really drive.

I record rather than rasterise. Every drawing message appends an entry to a display list, which a backend drains once per frame; that is rule one of VECTORCANVAS-PLAN.md, and it is what lets the Vulkan backend of phase 2 and the software backend of phase 1 sit behind the same object. I also keep the Cairo state machine - source, matrix, fill rule, stroke parameters, clip stack - because the Cairo API is stateful and immediate, and because fillPreservingPath and strokePreservingPath mean a path outlives the operation that drew it.

Most of my selectors are still skeletons: they signal VGNotYetImplemented naming the unit that will implement them. VGCairoInventory says which selectors I must answer, and VGCairoInventoryTest fails if one is missing.
"
Class {
	#name : 'VGCairoContext',
	#superclass : 'VGCairoObject',
	#instVars : [
		'surface',
		'state',
		'stateStack',
		'status'
	],
	#category : 'VectorGraphics-Cairo-Context',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Context'
}

{ #category : 'instance creation' }
VGCairoContext class >> newFor: aSurface [
	| context |
	context := self new.
	context setSurface: aSurface.
	^ context
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> annulusSectorCenter: arg1 from: arg2 to: arg3 innerRadius: arg4 outerRadius: arg5 [
	^ self notYetImplementedIn: '1.3' selector: #annulusSectorCenter:from:to:innerRadius:outerRadius:
]

{ #category : 'skeleton - unit 1.4' }
VGCairoContext >> antialias: arg1 [
	^ self notYetImplementedIn: '1.4' selector: #antialias:
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> appendGlyphsPath: arg1 [
	^ self notYetImplementedIn: '1.8' selector: #appendGlyphsPath:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> arcCenter: arg1 radius: arg2 startAngle: arg3 endAngle: arg4 cw: arg5 [
	^ self notYetImplementedIn: '1.3' selector: #arcCenter:radius:startAngle:endAngle:cw:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> arcCenter: arg1 radius: arg2 startAngle: arg3 sweep: arg4 [
	^ self notYetImplementedIn: '1.3' selector: #arcCenter:radius:startAngle:sweep:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> arcCenterX: arg1 centerY: arg2 radius: arg3 startAngle: arg4 endAngle: arg5 [
	^ self notYetImplementedIn: '1.3' selector: #arcCenterX:centerY:radius:startAngle:endAngle:
]

{ #category : 'transformations' }
VGCairoContext >> changeMatrixBy: aBlock [
	"Cairo ignores every request once the context is in error, which is how a singular matrix ends
	 as an empty drawing instead of a signal."
	self isInError ifTrue: [ ^ self ].
	aBlock value: state matrix
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> circleCenterX: arg1 y: arg2 radius: arg3 [
	^ self notYetImplementedIn: '1.3' selector: #circleCenterX:y:radius:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> circleSectorCenter: arg1 from: arg2 to: arg3 radius: arg4 [
	^ self notYetImplementedIn: '1.3' selector: #circleSectorCenter:from:to:radius:
]

{ #category : 'painting' }
VGCairoContext >> clearColor: aColor [
	"Every pixel of my target in aColor. The operator and the clip arrive in units 1.6 and 1.7, so
	 this is a plain fill of the whole surface for now."
	self isInError ifTrue: [ ^ self ].
	surface fillPixel: (surface format pixelForColor: aColor)
]

{ #category : 'painting' }
VGCairoContext >> clearTransparent [
	self isInError ifTrue: [ ^ self ].
	surface fillPixel: 0
]

{ #category : 'skeleton - unit 1.6' }
VGCairoContext >> clip [
	^ self notYetImplementedIn: '1.6' selector: #clip
]

{ #category : 'skeleton - unit 1.6' }
VGCairoContext >> clipPreservingPath [
	^ self notYetImplementedIn: '1.6' selector: #clipPreservingPath
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> closePath [
	^ self notYetImplementedIn: '1.3' selector: #closePath
]

{ #category : 'skeleton - unit 1.2' }
VGCairoContext >> currentPointInUserSpace [
	^ self notYetImplementedIn: '1.3' selector: #currentPointInUserSpace
]

{ #category : 'painting' }
VGCairoContext >> currentTarget [
	^ surface
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> curveVia: arg1 via: arg2 to: arg3 [
	^ self notYetImplementedIn: '1.3' selector: #curveVia:via:to:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> curveViaX: arg1 y: arg2 viaX: arg3 y: arg4 toX: arg5 y: arg6 [
	^ self notYetImplementedIn: '1.3' selector: #curveViaX:y:viaX:y:toX:y:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> ellipseWidth: arg1 height: arg2 [
	^ self notYetImplementedIn: '1.3' selector: #ellipseWidth:height:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> fill [
	^ self notYetImplementedIn: '1.3' selector: #fill
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> fillPreservingPath [
	^ self notYetImplementedIn: '1.3' selector: #fillPreservingPath
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> fillPreservingPath: arg1 [
	^ self notYetImplementedIn: '1.3' selector: #fillPreservingPath:
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> fontExtents [
	^ self notYetImplementedIn: '1.8' selector: #fontExtents
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> fontSize: arg1 [
	^ self notYetImplementedIn: '1.8' selector: #fontSize:
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> getGlyphExtentsOf: arg1 size: arg2 into: arg3 [
	^ self notYetImplementedIn: '1.8' selector: #getGlyphExtentsOf:size:into:
]

{ #category : 'initialization' }
VGCairoContext >> initialize [
	super initialize.
	state := VGCairoState new.
	stateStack := OrderedCollection new.
	status := VGCairoStatus success
]

{ #category : 'inspecting' }
VGCairoContext >> inspectorStateStack: aBuilder [
	<inspectorPresentationOrder: 12 title: 'State stack'>
	^ aBuilder newTable
		  items: self stateStackDescription;
		  addColumn: (SpStringTableColumn
				   title: 'Depth'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Fill rule'
				   evaluated: [ :each | each second fillRule printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Source'
				   evaluated: [ :each | each second source printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Clip'
				   evaluated: [ :each | each second clip printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Matrix'
				   evaluated: [ :each | each second matrix printString ]);
		  yourself
]

{ #category : 'inspecting' }
VGCairoContext >> inspectorStateStackContext: aContext [
	aContext active: state notNil
]

{ #category : 'accessing' }
VGCairoContext >> isInError [
	"Cairo latches a failure on the context and then ignores every request, so the drawing a bad
	 matrix would have produced is empty rather than signalled."
	^ status isSuccess not
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> lineFrom: arg1 to: arg2 [
	^ self notYetImplementedIn: '1.3' selector: #lineFrom:to:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> lineTo: arg1 [
	^ self notYetImplementedIn: '1.3' selector: #lineTo:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> lineToX: arg1 y: arg2 [
	^ self notYetImplementedIn: '1.3' selector: #lineToX:y:
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> maskGroupWith: arg1 [
	^ self notYetImplementedIn: '1.7' selector: #maskGroupWith:
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> maskSurface: arg1 x: arg2 y: arg3 [
	^ self notYetImplementedIn: '1.7' selector: #maskSurface:x:y:
]

{ #category : 'transformations' }
VGCairoContext >> matrix [
	"A copy, because Alexandrie answers a fresh matrix and a caller may transform what it got."
	^ state matrix copy
]

{ #category : 'transformations' }
VGCairoContext >> matrix: aMatrix [
	self isInError ifTrue: [ ^ self ].
	aMatrix isInvertible
		ifTrue: [ state matrix: aMatrix copy ]
		ifFalse: [ status := VGCairoStatus invalidMatrix ]
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> moveTo: arg1 [
	^ self notYetImplementedIn: '1.3' selector: #moveTo:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> paint [
	^ self notYetImplementedIn: '1.3' selector: #paint
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> paintGroupWith: arg1 [
	^ self notYetImplementedIn: '1.7' selector: #paintGroupWith:
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> paintGroupWith: arg1 alpha: arg2 [
	^ self notYetImplementedIn: '1.7' selector: #paintGroupWith:alpha:
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> paintWithAlpha: arg1 [
	^ self notYetImplementedIn: '1.7' selector: #paintWithAlpha:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> quadraticCurveFromCurrentPoint: arg1 via: arg2 to: arg3 [
	^ self notYetImplementedIn: '1.3' selector: #quadraticCurveFromCurrentPoint:via:to:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> rectangle: arg1 [
	^ self notYetImplementedIn: '1.3' selector: #rectangle:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> rectangleTo: arg1 [
	^ self notYetImplementedIn: '1.3' selector: #rectangleTo:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> rectangleX: arg1 y: arg2 width: arg3 height: arg4 [
	^ self notYetImplementedIn: '1.3' selector: #rectangleX:y:width:height:
]

{ #category : 'state' }
VGCairoContext >> restoreState [
	stateStack isEmpty ifTrue: [ ^ self ].
	state := stateStack removeLast
]

{ #category : 'state' }
VGCairoContext >> restoreStateAfter: aBlock [
	"The block runs with my state saved, and the state comes back even when the block raises: a
	 painting that fails must not leave the next frame transformed."
	self saveState.
	^ aBlock ensure: [ self restoreState ]
]

{ #category : 'transformations' }
VGCairoContext >> rotateByRadians: anAngle [
	self changeMatrixBy: [ :each | each rotateByRadians: anAngle ]
]

{ #category : 'transformations' }
VGCairoContext >> rotateByRadians: anAngle center: aPoint [
	self changeMatrixBy: [ :each | each rotateByRadians: anAngle center: aPoint ]
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> roundedRectangleLeft: arg1 top: arg2 right: arg3 bottom: arg4 tl: arg5 tr: arg6 br: arg7 bl: arg8 [
	^ self notYetImplementedIn: '1.3' selector: #roundedRectangleLeft:top:right:bottom:tl:tr:br:bl:
]

{ #category : 'state' }
VGCairoContext >> saveState [
	stateStack addLast: state copy
]

{ #category : 'transformations' }
VGCairoContext >> scaleBy: aPoint [
	self changeMatrixBy: [ :each | each scaleBy: aPoint ]
]

{ #category : 'transformations' }
VGCairoContext >> scaleByX: aNumber y: anotherNumber [
	self changeMatrixBy: [ :each | each scaleByX: aNumber y: anotherNumber ]
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> scaledFont: arg1 [
	^ self notYetImplementedIn: '1.8' selector: #scaledFont:
]

{ #category : 'transformations' }
VGCairoContext >> setIdentityMatrix [
	self changeMatrixBy: [ :each | each beIdentity ]
]

{ #category : 'skeleton - unit 1.7' }
VGCairoContext >> setOperatorClear [
	^ self notYetImplementedIn: '1.7' selector: #setOperatorClear
]

{ #category : 'private' }
VGCairoContext >> setSurface: aSurface [
	surface := aSurface
]

{ #category : 'skeleton - unit 1.8' }
VGCairoContext >> showGlyphs: arg1 [
	^ self notYetImplementedIn: '1.8' selector: #showGlyphs:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> source [
	^ self notYetImplementedIn: '1.5' selector: #source
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> sourceColor: arg1 [
	^ self notYetImplementedIn: '1.5' selector: #sourceColor:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> sourceColorR: arg1 g: arg2 b: arg3 [
	^ self notYetImplementedIn: '1.5' selector: #sourceColorR:g:b:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> sourceColorR: arg1 g: arg2 b: arg3 a: arg4 [
	^ self notYetImplementedIn: '1.5' selector: #sourceColorR:g:b:a:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> sourcePattern: arg1 [
	^ self notYetImplementedIn: '1.5' selector: #sourcePattern:
]

{ #category : 'skeleton - unit 1.5' }
VGCairoContext >> sourceSurface: arg1 [
	^ self notYetImplementedIn: '1.5' selector: #sourceSurface:
]

{ #category : 'accessing' }
VGCairoContext >> state [
	"My current graphics state: the matrix, the source, the fill rule and the clip that #saveState
	 pushes and #restoreState brings back together."
	^ state
]

{ #category : 'inspecting' }
VGCairoContext >> stateStackDescription [
	"One row for my current state and one for each state waiting under it, newest first, read from
	 the stack itself so the view shows what #restoreState will really bring back."
	^ ({ state } , stateStack reversed) withIndexCollect: [ :each :index |
		  {
			  (index = 1
				   ifTrue: [ 'current' ]
				   ifFalse: [ 'saved ' , (index - 1) printString ]).
			  each } ]
]

{ #category : 'accessing' }
VGCairoContext >> status [
	^ status
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> stroke [
	^ self notYetImplementedIn: '1.3' selector: #stroke
]

{ #category : 'skeleton - unit 1.4' }
VGCairoContext >> strokeCap: arg1 [
	^ self notYetImplementedIn: '1.4' selector: #strokeCap:
]

{ #category : 'skeleton - unit 1.4' }
VGCairoContext >> strokeDashPattern: arg1 offset: arg2 [
	^ self notYetImplementedIn: '1.4' selector: #strokeDashPattern:offset:
]

{ #category : 'skeleton - unit 1.4' }
VGCairoContext >> strokeJoin: arg1 [
	^ self notYetImplementedIn: '1.4' selector: #strokeJoin:
]

{ #category : 'skeleton - unit 1.4' }
VGCairoContext >> strokeJoinMiterLimit: arg1 [
	^ self notYetImplementedIn: '1.4' selector: #strokeJoinMiterLimit:
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> strokePreservingPath [
	^ self notYetImplementedIn: '1.3' selector: #strokePreservingPath
]

{ #category : 'skeleton - unit 1.4' }
VGCairoContext >> strokeSize: arg1 [
	^ self notYetImplementedIn: '1.4' selector: #strokeSize:
]

{ #category : 'accessing' }
VGCairoContext >> surface [
	^ surface
]

{ #category : 'skeleton - unit 1.4' }
VGCairoContext >> tolerance: arg1 [
	^ self notYetImplementedIn: '1.4' selector: #tolerance:
]

{ #category : 'transformations' }
VGCairoContext >> transformWith: aMatrix [
	"The argument acts first and my own matrix after it, which is cairo_transform."
	self changeMatrixBy: [ :each | each preMultiply: aMatrix ]
]

{ #category : 'transformations' }
VGCairoContext >> translateBy: aPoint [
	self changeMatrixBy: [ :each | each translateBy: aPoint ]
]

{ #category : 'transformations' }
VGCairoContext >> translateByX: aNumber y: anotherNumber [
	self changeMatrixBy: [ :each | each translateByX: aNumber y: anotherNumber ]
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> useFillRuleEvenOdd [
	^ self notYetImplementedIn: '1.3' selector: #useFillRuleEvenOdd
]

{ #category : 'skeleton - unit 1.3' }
VGCairoContext >> useFillRuleWinding [
	^ self notYetImplementedIn: '1.3' selector: #useFillRuleWinding
]
