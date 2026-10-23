"
I hold the examples of the layering of this project.
My one example answers VGArchitectureTest, whose class-side Dependencies tab puts the edges the table grants, the edges the code really makes and the edges the baseline declares side by side, one row a package.
I live beside the other examples holders of the Cairo layer because VGArchitectureTest lives in the test package, which has no examples package of its own.
"
Class {
	#name : 'VGArchitectureExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGArchitectureExamples class >> dependenciesOfThisProject [
	<sampleInstance>
	"The layering of this project, for its class-side Dependencies tab: what each package may
	 name, what it really names and what the baseline says it needs. Nothing is cached, so the
	 tab is a live scan of the image the moment it opens."

	^ VGArchitectureTest
]
