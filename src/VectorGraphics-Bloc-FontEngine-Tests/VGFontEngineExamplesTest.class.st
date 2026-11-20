"
I hold the examples and the inspector views of the font engine's own package to the shape the whole project uses, by naming `VGFontEngineExamples` to the gate my superclass carries: every example rebuilds its object and answers something, every window example is named for the window and is never run by the gate, every holder has a comment, and every view a reader opens has a gate and fills its cells.

Each layer of the project has one such subclass. Mine exists because the font engine is a package of its own, loaded by the `fonts` group alone, and a gate of another layer naming my example class would make that layer's tests need my packages.
"
Class {
	#name : 'VGFontEngineExamplesTest',
	#superclass : 'VGCairoExamplesTest',
	#category : 'VectorGraphics-Bloc-FontEngine-Tests',
	#package : 'VectorGraphics-Bloc-FontEngine-Tests'
}

{ #category : 'accessing' }
VGFontEngineExamplesTest >> exampleHolders [
	^ { VGFontEngineExamples }
]
