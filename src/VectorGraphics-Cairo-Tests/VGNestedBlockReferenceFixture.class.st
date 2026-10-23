"
I exist so that one test can prove the dependency scan reads the literals of every block inside a method.
My one method names VGCairoMatrix three blocks deep and nowhere else, so a scan that reads only a method own literals answers nothing for me and the test that asks for VGCairoMatrix package fails.
I am never instantiated and I draw nothing.
"
Class {
	#name : 'VGNestedBlockReferenceFixture',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Tests-Fixtures',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Fixtures'
}

{ #category : 'scanning' }
VGNestedBlockReferenceFixture >> reachThroughThreeBlocks [
	"The reference the scan has to find. It is inside three nested blocks and the method itself
	 names no class of this project, which is what VGArchitectureTest reads me for."

	^ [ [ [ VGCairoMatrix newIdentity ] value ] value ] value
]
