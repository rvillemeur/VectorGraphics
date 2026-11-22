Extension { #name : 'AeCairoImageSurface' }

{ #category : '*VectorGraphics-Bloc' }
AeCairoImageSurface >> newVectorGraphicsContextOrNil [
	"Nil: I am Alexandrie's surface and my newContext answers Alexandrie's context, which is not
	 the protocol a drawing of this project is written against. The extension is here rather
	 than upstream because the question is this project's, and it is an extension rather than a
	 class test in the asking method so that the two surfaces answer it themselves."

	^ nil
]
