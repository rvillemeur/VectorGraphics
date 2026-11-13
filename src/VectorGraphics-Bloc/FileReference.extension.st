Extension { #name : 'FileReference' }

{ #category : '*VectorGraphics-Bloc' }
FileReference >> newHbBlob [
	"A HarfBuzz blob over the font I hold: hb_blob_create_from_file opens the file itself, so
	 the bytes it reads never enter Pharo's object memory and nothing of mine has to be pinned
	 or kept alive. An extension of this project, the companion of fontBytes, so that no
	 catalogue entry asks what kind of source it holds.

	 A FileLocator reaches me through its own doesNotUnderstand:, which forwards any selector
	 the resolved reference responds to."

	^ AeHbBlob newLocatedAt: self
]
