"
I am the four classes one frame of the budget is drawn with: the image surface it is drawn on, the linear gradient pattern its cards are filled with, the canvas a scene draws on and the renderer class its text is measured through.
Two of me exist. `ours` names this project's classes and `alexandrie` names the Cairo ones Bloc already has, so VGFrameDeviceBenchmark's draw methods are written once and draw the same picture on either side; the Cairo figure of a report is then the same frame and not a second description of it. A test holds each pair of classes to the other through VGAlexandrieCorpus' name map and the hierarchy.
`surfaceOfExtent:`, `linearGradientFrom:to:addStopsFrom:`, `canvasOn:` and `rendererClass` are the whole of what a draw method asks of me.
"
Class {
	#name : 'VGFrameDrawingKit',
	#superclass : 'Object',
	#instVars : [
		'surfaceClass',
		'patternClass',
		'canvasClass',
		'rendererClass'
	],
	#category : 'VectorGraphics-Vulkan-Tests-Budget',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Budget'
}

{ #category : 'instance creation' }
VGFrameDrawingKit class >> alexandrie [
	"The kit of the classes Bloc already has, which draw with Cairo. AeCanvas and BARenderer are
	 of Alexandrie's canvas and Bloc's renderer packages and not of Alexandrie's Cairo package,
	 which is why naming them here leaves intact the rule that no package of this project names
	 a Cairo class."

	^ self
		  surfaceClass: AeCairoImageSurface
		  patternClass: AeCairoLinearGradientPattern
		  canvasClass: AeCanvas
		  rendererClass: BARenderer
]

{ #category : 'instance creation' }
VGFrameDrawingKit class >> ours [
	"The kit of this project's own classes, which is what a benchmark draws its own frame with."

	^ self
		  surfaceClass: VGCairoImageSurface
		  patternClass: VGCairoLinearGradientPattern
		  canvasClass: VGCanvas
		  rendererClass: VGRenderer
]

{ #category : 'instance creation' }
VGFrameDrawingKit class >> surfaceClass: aSurfaceClass patternClass: aPatternClass canvasClass: aCanvasClass rendererClass: aRendererClass [
	^ self new
		  setSurfaceClass: aSurfaceClass
		  patternClass: aPatternClass
		  canvasClass: aCanvasClass
		  rendererClass: aRendererClass
]

{ #category : 'drawing' }
VGFrameDrawingKit >> canvasOn: aSurface [
	"A canvas over that surface, which is what a Bloc scene draws on: a scene draws on a canvas
	 and not on a context, and the entries reach the one surface either way."

	^ canvasClass newFor: aSurface
]

{ #category : 'accessing' }
VGFrameDrawingKit >> classes [
	"My four classes, in the order a frame meets them: the surface, the gradient, the canvas and
	 the renderer. The pairing of one kit with the other is tested over this, so the order is
	 part of what I answer and not an accident of the slots."

	^ {
		  surfaceClass.
		  patternClass.
		  canvasClass.
		  rendererClass }
]

{ #category : 'accessing' }
VGFrameDrawingKit >> classesByRole [
	"My classes, each under the role it plays, as role to class associations in the order
	 `classes` answers them. The role is the slot the class is held in with the word Class taken
	 off, so the names cannot drift from the classes they label."

	^ self class slotNames
		  with: self classes
		  collect: [ :slot :each |
			  (slot copyReplaceAll: 'Class' with: '') -> each ]
]

{ #category : 'accessing' }
VGFrameDrawingKit >> counterpart [
	"The kit of the other side, which is the kit my classes are paired with. A measurement of one
	 kit is only worth reading beside the other, so a kit answers where its comparison comes from
	 rather than leaving a caller to name both."

	^ self isOurs
		  ifTrue: [ self class alexandrie ]
		  ifFalse: [ self class ours ]
]

{ #category : 'inspector' }
VGFrameDrawingKit >> inspectorClasses: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Classes'>
	"My four classes with the classes of the other kit they answer to, so that one measurement of
	 Cairo against this project is read beside the pairing it rests on. The counterpart is asked
	 of the other kit and the pairing is asked of the corpus's own name map and of the hierarchy,
	 which is what the test asks, so a pair that stops holding shows here as nothing at all.
	 The pairing is asked our class first whichever side I am, because that is the direction the
	 name map is written in."

	| counterparts |
	counterparts := self counterpart classesByRole.
	^ aBuilder newTable
		  items: (self classesByRole withIndexCollect: [ :each :index |
					   each -> (counterparts at: index) value ]);
		  addColumn:
			  (SpStringTableColumn title: 'Role' evaluated: [ :each |
					   each key key ]);
		  addColumn: (SpStringTableColumn title: 'Class' evaluated: [ :each |
					   each key value name ]);
		  addColumn:
			  (SpStringTableColumn title: 'Counterpart' evaluated: [ :each |
					   each value name ]);
		  addColumn: (SpStringTableColumn title: 'Held by' evaluated: [ :each |
					   (self isOurs
							ifTrue: [ self pairingOf: each key value with: each value ]
							ifFalse: [ self pairingOf: each value with: each key value ])
						   ifNil: [ '' ] ]);
		  yourself
]

{ #category : 'inspector' }
VGFrameDrawingKit >> inspectorClassesContext: aContext [
	"A kit with no class in it has nothing to pair."

	aContext active: surfaceClass isNotNil
]

{ #category : 'testing' }
VGFrameDrawingKit >> isOurs [
	"Whether I draw with this project's classes. Read from the package my surface comes from and
	 not from which class message built me, because that is the same rule the test holds the two
	 kits to: a class of ours in the Cairo kit would measure this project and call it Cairo."

	^ surfaceClass package name beginsWith: 'VectorGraphics'
]

{ #category : 'drawing' }
VGFrameDrawingKit >> linearGradientFrom: aPoint to: anotherPoint addStopsFrom: aCollection [
	^ patternClass
		  from: aPoint
		  to: anotherPoint
		  addStopsFrom: aCollection
]

{ #category : 'accessing' }
VGFrameDrawingKit >> pairingOf: ourClass with: theirClass [
	"What holds those two classes together, or nil if nothing does: the corpus's own name map for
	 a Cairo class this project reimplements, the hierarchy for a canvas or a renderer that
	 subclasses Alexandrie's. Both the pairing test and the Classes tab ask this, so neither can
	 claim a pair the other would refuse."

	((Dictionary newFrom: VGAlexandrieCorpus classNameMap)
		 at: theirClass name
		 ifAbsent: [ nil ]) = ourClass name ifTrue: [ ^ 'name map' ].
	^ (ourClass inheritsFrom: theirClass)
		  ifTrue: [ 'subclass of ' , theirClass name ]
		  ifFalse: [ nil ]
]

{ #category : 'printing' }
VGFrameDrawingKit >> printOn: aStream [
	super printOn: aStream.
	aStream nextPut: $(.
	aStream nextPutAll: surfaceClass name.
	aStream nextPut: $)
]

{ #category : 'accessing' }
VGFrameDrawingKit >> rendererClass [
	"The renderer class a scene's text is measured through. A span measured on one backend keeps
	 that backend's scaled font, which the other cannot draw, so the scene of a kit is laid out
	 through the kit's own renderer."

	^ rendererClass
]

{ #category : 'initialization' }
VGFrameDrawingKit >> setSurfaceClass: aSurfaceClass patternClass: aPatternClass canvasClass: aCanvasClass rendererClass: aRendererClass [
	surfaceClass := aSurfaceClass.
	patternClass := aPatternClass.
	canvasClass := aCanvasClass.
	rendererClass := aRendererClass
]

{ #category : 'drawing' }
VGFrameDrawingKit >> surfaceOfExtent: aPoint [
	"An image surface of that extent on my side. Ours records a display list and theirs draws as
	 it is asked, which is the whole difference the budget measures."

	^ surfaceClass extent: aPoint
]
