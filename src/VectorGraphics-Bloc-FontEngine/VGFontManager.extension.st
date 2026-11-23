Extension { #name : 'VGFontManager' }

{ #category : '*vectorgraphics-bloc-fontengine' }
VGFontManager >> buildsFacesOfThisProject [
	"A manager of mine builds a VGFontFace, whose character map and outlines are read in
	 Pharo with no FreeType handle anywhere."

	^ true
]

{ #category : '*VectorGraphics-Bloc-FontEngine' }
VGFontManager class >> poseFacesOfThisProject: aBoolean during: aBlock [
	"Class-side extension of mine kept in the font engine package rather than with the rest of
	 me: the question it asks of a manager, buildsFacesOfThisProject, is defined there, because
	 that package is the only one that knows both kits. I pose the manager the caller needs for
	 the length of the block and put the ambient one back whatever happens, since
	 AeFontManager globalInstance is global state of Alexandrie.
	 A manager of the right kind is left alone, because building another costs a scan of the
	 embedded fonts for nothing. When the faces wanted are not ours the slot goes to nil rather
	 than to a manager of our own: upstream builds one lazily, which is the state an image that
	 never met this project is in.
	 The manager posed is the shared one and never a fresh build: a build is 116 ms of the
	 machine's fonts, and unit 3.10 measured it once a frame, where it was 86 per cent of what
	 drawing the reference frame cost."

	| ambient |
	ambient := self managerUpstreamHolds.
	(ambient ifNil: [ false ] ifNotNil: [ :each | each buildsFacesOfThisProject ]) = aBoolean
		ifTrue: [ ^ aBlock value ].
	^ [
	  aBoolean
		  ifTrue: [
			  AeFontManager globalInstance:
				  (self installedInstance ifNil: [ self withDefaultFaces ]) ]
		  ifFalse: [ self restoreUpstreamManager: nil ].
	  aBlock value ] ensure: [ self restoreUpstreamManager: ambient ]
]
