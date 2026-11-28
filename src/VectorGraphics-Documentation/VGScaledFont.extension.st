Extension { #name : 'VGScaledFont' }

{ #category : '*VectorGraphics-Documentation' }
VGScaledFont >> inspectionObjectGraph: aBuilder [
	"Extension installed by this project's documentation package: a scaled font is where a reader
	 of the font route starts, and what it holds right now is not what the declarations say it may
	 hold — a cache nothing has asked for reads as absent. The tab is an extension so that the
	 font packages keep depending on nothing new."

	<inspectorPresentationOrder: 95 title: 'Object graph'>
	^ aBuilder newRoassal
		canvas: (ArchDocGraphRenderer on: (ArchDocObjectGraph of: self) graph) canvas;
		yourself
]

{ #category : '*VectorGraphics-Documentation' }
VGScaledFont >> inspectionObjectGraphContext: aContext [
	"Extension installed by this project's documentation package: offer the tab only where there
	 is a graph to draw, which is where this object really holds something a declaration names. A
	 scaled font whose caches are all unbuilt would draw one node and no arrow, and that tells a
	 reader nothing. The holdings are read through the slots, so asking leaves the object exactly
	 as it was."

	^ aContext active: ((ArchDocObjectGraph of: self) holdingsOf: self) notEmpty
]
