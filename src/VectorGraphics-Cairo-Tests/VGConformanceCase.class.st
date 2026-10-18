"
I am one case of the conformance corpus: a name, the unit of VECTORCANVAS-PLAN.md at which I should go green, a surface extent, a block that drives a Cairo context, and the tolerance my comparison allows.

My block speaks only the Cairo API, so the same case runs against our VGCairoContext and against a real AeCairoContext. That is what makes a reference render possible: VGCairoReferenceGenerator replays me through Alexandrie and writes the pixels Cairo produced, and a later unit compares our render against that file.

Most of my cases leave the source alone, because Cairo starts with opaque black. That keeps the unit attribution honest: a case that only fills a rectangle is owed by unit 1.3, not by the unit that implements colour sources.
"
Class {
	#name : 'VGConformanceCase',
	#superclass : 'Object',
	#instVars : [
		'name',
		'unit',
		'extent',
		'drawBlock',
		'tolerance'
	],
	#category : 'VectorGraphics-Cairo-Tests-Conformance',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Conformance'
}

{ #category : 'instance creation' }
VGConformanceCase class >> name: aString unit: aUnitString extent: aPoint draw: aBlock [
	| case |
	case := self new.
	case setName: aString unit: aUnitString extent: aPoint draw: aBlock.
	^ case
]

{ #category : 'running' }
VGConformanceCase >> blockingFailure [
	"The first selector of mine that no unit has implemented yet, as the VGNotYetImplemented it
	 raised, or nil once I draw from end to end. Only that one error is caught: any other error is a
	 real defect and must reach the caller."

	^ [ self drawOn: self newTarget.
	  nil ]
		  on: VGNotYetImplemented
		  do: [ :error | error return: error ]
]

{ #category : 'drawing' }
VGConformanceCase >> drawOn: aContext [
	drawBlock value: aContext
]

{ #category : 'accessing' }
VGConformanceCase >> extent [
	^ extent
]

{ #category : 'inspecting' }
VGConformanceCase >> inspectorBlockingFailure: aContext [
	<inspectorPresentationOrder: 10 title: 'Blocking'>
	"Where my drawing stops today. The picture is drawn on a target of my own each time this is
	 asked, so inspecting me changes nothing about me."

	| failure |
	failure := self blockingFailure.
	^ aContext newTable
		  items: {
				  ('case' -> self name).
				  ('filed under unit' -> self unit).
				  ('stops on' -> (failure ifNil: [ 'nothing: the case draws' ] ifNotNil: [ failure selectorName ])).
				  ('owed by unit' -> (failure ifNil: [ '-' ] ifNotNil: [ failure unit ])) };
		  addColumn: (SpStringTableColumn title: 'Question' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn title: 'Answer' evaluated: [ :each | each value ]);
		  yourself
]

{ #category : 'accessing' }
VGConformanceCase >> name [
	^ name
]

{ #category : 'running' }
VGConformanceCase >> newTarget [
	"A real ARGB32 surface of my own size, now that unit 1.1 builds one. The context a case draws
	 on is the one a caller would build, so the selector a case reports is the one its own drawing
	 asks for."
	^ (VGCairoImageSurface extent: extent) newContext
]

{ #category : 'printing' }
VGConformanceCase >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ' ';
		nextPutAll: name;
		nextPutAll: ' (unit ';
		nextPutAll: unit;
		nextPut: $)
]

{ #category : 'accessing' }
VGConformanceCase >> referenceFileName [
	"The reference render lives next to the corpus, one PNG per case, named after the case."

	^ name , '.png'
]

{ #category : 'private' }
VGConformanceCase >> setName: aString unit: aUnitString extent: aPoint draw: aBlock [
	name := aString.
	unit := aUnitString.
	extent := aPoint.
	drawBlock := aBlock
]

{ #category : 'accessing' }
VGConformanceCase >> tolerance [
	"How far a channel may differ from the reference before the case fails. Zero is the default,
	 because a rasteriser that matches Cairo exactly is the goal; blur and text relax it."

	^ tolerance ifNil: [ 0 ]
]

{ #category : 'accessing' }
VGConformanceCase >> tolerance: anInteger [
	tolerance := anInteger
]

{ #category : 'accessing' }
VGConformanceCase >> unit [
	^ unit
]
