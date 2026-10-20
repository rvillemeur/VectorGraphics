"
I hold the examples of `VGCairoReferenceScanner`, which reads the compiled methods of a
package and answers the Cairo classes they name.
One example scans this project, where the answer is empty and the failover is real. One
scans the Bloc backend, where the answer is the methods a failover cannot reach by
subclassing the canvas.

"
Class {
	#name : 'VGCairoReferenceScannerExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGCairoReferenceScannerExamples class >> scanOfTheBlocBackend [
	<sampleInstance>
	"The same scanner pointed at the Bloc backend built on Cairo, where the answer is not empty.
	 Four of its methods build a Cairo object themselves, and three of those cannot be reached by
	 subclassing the canvas."

	^ VGCairoReferenceScanner new
		  packageNames: { VGCairoReferenceScanner blocBackendPackageName };
		  yourself
]

{ #category : 'examples' }
VGCairoReferenceScannerExamples class >> scanOfThisProject [
	<sampleInstance>
	"The scan this project has to pass: no method of any of its packages names a class of the
	 Cairo package, so nothing of it would load that library. The Offenders tab of the inspector
	 is empty when the failover is real."

	^ VGCairoReferenceScanner default
]
