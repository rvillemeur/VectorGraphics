"
I am this project's documentation package made askable. I hold no state and I am never instantiated: my class side answers the facts the inspector tabs of this package need, and the package prefix every package of this project shares.

The package I belong to installs two tabs through extension methods, because neither Pharo's `Package` nor the font classes are ours to change for the sake of a picture: an *Architecture* tab on `Package`, which draws the declarations of a package, and an *Object graph* tab on `VGScaledFont`, which walks one live font and shows what it holds at this moment. The declarations themselves live on the font classes as pragmas of symbols, so the font packages depend on nothing new; reading them is ArchDoc's work, and drawing them is Roassal's.

Key methods: `VGDocumentation class >> packagePrefix`, which the `Architecture` tab's gate asks so that a reader of Pharo's own packages is offered nothing.
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
