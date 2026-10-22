Extension { #name : 'VGFontFace' }

{ #category : '*VectorGraphics-Bloc' }
VGFontFace class >> newForFace: aFreeTypeFace [
	"The face for the font a FreeType face names. A FreeType face is a handle into the library
	 this project replaces: it carries a family name and a style name, and no bytes and no file
	 name, so the bytes are matched back out of the font manager that registered it.
	 This and #bytesForFamilyName:styleName: live in the Bloc package, as extensions, because
	 they are the only part of the face that knows a foreign font registry: the engine reads
	 bytes and nothing else. Bloc hands a canvas a face of this kind, and so does a drawing that
	 picks its font by family name."

	^ self newForBytes: (self
			   bytesForFamilyName: aFreeTypeFace familyName
			   styleName: aFreeTypeFace styleName)
]
