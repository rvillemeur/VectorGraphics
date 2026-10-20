"
I hold the Bloc backend to the same rules as the rest of the project: every example runs and
answers a fresh object, every example holder has a class comment, and every inspector view of
every example builds, fills its cells and carries a gate.
The rules themselves are inherited from `VGCairoExamplesTest`, and only the list of example
holders is mine, so a rule added there is asked of this package too.
One consequence of inheriting them: a run of the Cairo test package also runs those rules
against these holders, because Pharo builds a suite from the concrete subclasses as well.

"
Class {
	#name : 'VGBlocExamplesTest',
	#superclass : 'VGCairoExamplesTest',
	#category : 'VectorGraphics-Bloc-Tests',
	#package : 'VectorGraphics-Bloc-Tests'
}

{ #category : 'accessing' }
VGBlocExamplesTest >> exampleHolders [
	^ {
		  VGCanvasExamples.
		  VGRendererExamples }
]
