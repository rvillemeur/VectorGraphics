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
