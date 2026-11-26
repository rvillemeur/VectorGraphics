Extension { #name : 'Package' }

{ #category : '*VectorGraphics-Documentation' }
Package >> inspectionArchitecture: aBuilder [
	"Extension of Pharo's Package: a reader asks a package what it holds, so the tab belongs on
	 the package and not on a class of ours. It is here, in this project's own documentation
	 package, because Pharo's package class is not ours to edit."

	<inspectorPresentationOrder: 90 title: 'Architecture'>
	^ aBuilder newRoassal
		canvas: (ArchDocGraphRenderer onPackageNamed: self name) canvas;
		yourself
]

{ #category : '*VectorGraphics-Documentation' }
Package >> inspectionArchitectureContext: aContext [
	"Extension of Pharo's Package: offer the tab on this project's packages alone. Deciding by
	 reading a package's declarations would cost a scan of every method of every package a reader
	 opens, and this package is only entitled to answer for its own project anyway."

	^ aContext active: (self name beginsWith: VGDocumentation packagePrefix)
]
