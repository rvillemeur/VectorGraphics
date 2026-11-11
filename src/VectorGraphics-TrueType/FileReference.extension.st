Extension { #name : 'FileReference' }

{ #category : '*VectorGraphics-TrueType' }
FileReference >> fontBytes [
	"The bytes of the font this file holds. An extension of this project, so that a catalogue
	 entry can ask its source for bytes rather than ask what kind of source it is."

	^ self binaryReadStreamDo: [ :stream | stream upToEnd ]
]

{ #category : '*VectorGraphics-TrueType' }
FileReference >> fontSourceName [
	"How I name myself when I am the source of a font: my base name, which is what a reader
	 looking at a catalogue of hundreds of files can tell apart. An extension of this project,
	 the companion of fontBytes, so no catalogue entry asks what kind of source it holds."

	^ self basename
]
