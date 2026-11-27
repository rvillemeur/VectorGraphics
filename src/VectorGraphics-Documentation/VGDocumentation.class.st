"
I am this project's documentation package made askable. I hold no state and I am never instantiated: my class side answers the facts the inspector tabs of this package need, and the package prefix every package of this project shares.

The package I belong to installs its tabs through extension methods, because neither Pharo's `Package` nor the font classes are ours to change for the sake of a picture. Four are on `Package` — *Neighbours*, the project with one package filled apart from the rest; *Components*, the parts a component map claims; *Architecture*, the declarations of the package drawn class by class; and *Where to start*, those classes in reading order with the entry points the package's manifest declares at the head. One more, *Object graph*, is on `VGScaledFont` and on `VGFontManager`, and walks a live object rather than a declaration.

The declarations themselves live on the font classes as pragmas of symbols, and the entry points on each package's manifest as a class-side `archDocEntryPoints`, so the font packages depend on nothing new; reading them is ArchDoc's work, and drawing them is Roassal's.

Key methods: `VGDocumentation class >> packagePrefix`, which the gate of the three project-wide tabs asks so that a reader of Pharo's own packages is offered nothing.
"
Class {
	#name : 'VGDocumentation',
	#superclass : 'Object',
	#category : 'VectorGraphics-Documentation',
	#package : 'VectorGraphics-Documentation'
}

{ #category : 'accessing' }
VGDocumentation class >> packagePrefix [
	"The name every package of this project begins with. The inspector tabs this package installs
	 on Pharo's own Package class are offered for these packages alone."

	^ 'VectorGraphics'
]
