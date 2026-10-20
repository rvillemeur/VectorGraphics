"
I am the boundary between the recorded frame and whatever draws it.

Rule three of the plan freezes my interface at three messages: fillSegments:paint:clip:operator:,
blitSurface:at:paint:clip:operator: and drainInto:. The blit one grew its clip and its operator in
unit 1.7, where a mask became drawable: the surface it names is the mask, its alpha channel says how
much of the paint reaches each pixel, and its colours are never read. Nothing above me knows whether
a paint is evaluated by a Pharo method or by a SPIR-V function, and nothing below me knows what a
BlPaint or an AeCairoPattern is.
A backend below me that raises VGBackendFailure is answered by replaying the same display list on
the software backend, which is why the failover costs nothing to arrange.
My subclasses are VGSoftwareBackend here and the Vulkan backend in phase 2.
"
Class {
	#name : 'VGBackend',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Backend',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Backend'
}

{ #category : 'inspector' }
VGBackend class >> inspectorBoundary: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Boundary'>
	"The messages a backend answers, read from my own selectors rather than listed here, so the
	 tab says what the frozen boundary really is. Which subclasses answer each one is asked of
	 the subclasses themselves."

	^ aBuilder newTable
		  items: self selectors asSortedCollection asArray;
		  addColumn: (SpStringTableColumn
				   title: 'Message'
				   evaluated: [ :each | each ]);
		  addColumn: (SpStringTableColumn
				   title: 'Arguments'
				   evaluated: [ :each | each numArgs printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Answered by'
				   evaluated: [ :each |
					   ((self allSubclasses select: [ :class |
						     class includesSelector: each ]) collect: [ :class |
						    class name ]) asSortedCollection asArray printString ]);
		  yourself
]

{ #category : 'inspector' }
VGBackend class >> inspectorBoundaryContext: aContext [
	"The boundary belongs to the root of the hierarchy, not to a particular backend."

	aContext active: self superclass == Object
]

{ #category : 'drawing' }
VGBackend >> blitSurface: aSurface at: aPoint paint: aPaint clip: aClip operator: anOperator [
	self subclassResponsibility
]

{ #category : 'draining' }
VGBackend >> drainInto: aTarget [
	"Write everything recorded since the last drain into that target and keep nothing."
	self subclassResponsibility
]

{ #category : 'drawing' }
VGBackend >> fillSegments: aSegments paint: aPaint clip: aRectangle operator: aSymbol [
	self subclassResponsibility
]
