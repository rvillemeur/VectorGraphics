"
I hold the examples of the layering of this project.

My one example answers VGArchitectureTest, whose class-side Dependencies tab puts the edges the table grants, the edges the code really makes and the edges the baseline declares side by side, one row a package, and whose Groups tab puts the packages each baseline group loads beside the classes of Bloc or Alexandrie those packages name, one row a group.

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
	"The layering of this project, for its two class-side tabs: Dependencies puts what each
	 package may name, what it really names and what the baseline says it needs side by side,
	 and Groups puts what each group of the baseline loads beside the classes of Bloc and
	 Alexandrie those packages name. Nothing is cached, so both tabs are a live scan of the
	 image the moment they open."

	^ VGArchitectureTest
]
