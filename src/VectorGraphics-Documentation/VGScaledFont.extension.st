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
