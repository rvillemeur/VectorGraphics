"
I hold the example of VGAlexandrieFontLifetime: one click shows what this session keeps alive
so that FreeType and harfbuzz cannot free the same face twice.
The example draws a reference picture with Alexandrie, which is what leaves a font manager
behind, and answers the keeper, whose Kept tab names every object it holds and why.
"
Class {
	#name : 'VGAlexandrieFontLifetimeExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGAlexandrieFontLifetimeExamples class >> fontObjectsKeptForThisSession [
	<sampleInstance>
	"One click: a reference picture drawn by Alexandrie, which replaces the global font manager
	 and may hand its face to harfbuzz, and then the keeper that holds what the collector must
	 not reach. Its Kept tab names the FreeType library, the managers and the faces, with the
	 reason each one is held, and its Lifetime tab says whether the library in hand was opened
	 by this run of the virtual machine — false there is the state a restarted image comes back
	 in, and the next ask for the library repairs it."
	VGAlexandrieFontLifetime freeTypeLibrary.
	(VGAlexandrieCase for: #lineCap) cairoForm.
	^ VGAlexandrieFontLifetime
]
