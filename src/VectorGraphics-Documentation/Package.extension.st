Extension { #name : 'Package' }

{ #category : '*VectorGraphics-Documentation' }
Package >> archDocComponentMap [
	"The map claiming me, or nil. A package belongs to one map: two maps claiming it would draw
	 two pictures of the same classes, and a reader would have no way to choose."

	^ (ArchDocComponentMap maps
		detect: [ :each | each packageNames includes: self name ]
		ifNone: [ nil ]) ifNotNil: [ :class | class new ]
]

{ #category : '*VectorGraphics-Documentation' }
Package >> archDocProject [
	"The project I belong to, read as a graph of packages. This package answers for its own
	 project alone, which is the same rule the architecture tab is gated by."

	^ ArchDocProjectModel onPrefix: VGDocumentation packagePrefix
]

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

{ #category : '*VectorGraphics-Documentation' }
Package >> inspectionComponents: aBuilder [
	"Extension of Pharo's Package: the component altitude of a package, before the class one,
	 because a reader asking what a package is wants six parts and not twenty class names. The
	 picture is drawn by the map that claims the package."

	<inspectorPresentationOrder: 85 title: 'Components'>
	^ aBuilder newRoassal
		canvas: (ArchDocComponentRenderer onMap: self archDocComponentMap) canvas;
		yourself
]

{ #category : '*VectorGraphics-Documentation' }
Package >> inspectionComponentsContext: aContext [
	"Extension of Pharo's Package: offer the components tab where a map claims the package, and
	 nowhere else. A package no map claims has no parts to draw."

	^ aContext active: self archDocComponentMap notNil
]

{ #category : '*VectorGraphics-Documentation' }
Package >> inspectionNeighbours: aBuilder [
	"Extension of Pharo's Package: the widest altitude, before the parts and the classes,
	 because the first question asked of a package is where it sits. The project is drawn whole
	 with this package filled apart from the rest, and a forbidden arrow is drawn in red."

	<inspectorPresentationOrder: 80 title: 'Neighbours'>
	^ aBuilder newRoassal
		canvas: (ArchDocPackageRenderer
			onProject: self archDocProject
			focusing: self) canvas;
		yourself
]

{ #category : '*VectorGraphics-Documentation' }
Package >> inspectionNeighboursContext: aContext [
	"Extension of Pharo's Package: offer the tab on this project's packages alone, the same rule
	 the architecture tab is gated by. Drawing another project would claim to speak for code
	 this one does not own."

	^ aContext active: (self name beginsWith: VGDocumentation packagePrefix)
]
