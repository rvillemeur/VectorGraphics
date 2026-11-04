Extension { #name : 'VGFontFace' }

{ #category : '*VectorGraphics-Bloc' }
VGFontFace class >> bytesForFamilyName: aFamilyName styleName: aStyleName [
	"The bytes of the font the manager registered under this family and style. A font we cannot
	 name falls back to the bundled default, because a frame drawn in the wrong font is better
	 than a frame that raises inside the renderer.

	 This lives in VectorGraphics-Bloc, not in the package of the class it extends, because it
	 is the only method of the Cairo backend that names AeFontManager and its only sender is
	 newForFace:, the bridge from Bloc's own font face. The Cairo backend has to load in an
	 image with no Alexandrie present."

	| entry |
	entry := AeFontManager globalInstance faceEntries
		         detect: [ :each |
			         each familyName = aFamilyName and: [
				         each styleName = aStyleName ] ]
		         ifNone: [ nil ].
	entry ifNil: [ ^ self defaultBytes ].
	^ (entry isKindOf: AeMemoryFaceEntry)
		  ifTrue: [ entry bytes ]
		  ifFalse: [ entry location binaryReadStream upToEnd ]
]

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
