Extension { #name : 'VGFontManager' }

{ #category : '*VectorGraphics-Documentation' }
VGFontManager >> inspectionObjectGraph: aBuilder [
	"Extension installed by this project's documentation package: the Bloc side of the route
	 starts here, and what this manager holds right now is not what its declarations say it may
	 hold — the faces are parsed as a session draws with them, so a fresh manager shows the
	 catalogue alone. The tab is an extension so that VectorGraphics-Bloc-Text keeps depending on
	 nothing new."

	<inspectorPresentationOrder: 95 title: 'Object graph'>
	^ aBuilder newRoassal
		canvas: (ArchDocGraphRenderer on: (ArchDocObjectGraph of: self) graph) canvas;
		yourself
]

{ #category : '*VectorGraphics-Documentation' }
VGFontManager >> inspectionObjectGraphContext: aContext [
	"Extension installed by this project's documentation package: offer the tab only where there
	 is a graph to draw, which is where this object really holds something a declaration names. A
	 font manager that has posed no family yet would draw one node and no arrow. The holdings are
	 read through the slots, so asking leaves the object exactly as it was."

	^ aContext active: ((ArchDocObjectGraph of: self) holdingsOf: self) notEmpty
]
