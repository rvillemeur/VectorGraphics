"
I keep the Alexandrie font objects of this project's tests and corpus alive for the whole
session, and I exist because nothing else does.
A FreeType library destroys every face it owns when it is destroyed, and harfbuzz, handed a
face by hb_ft_font_create_referenced, keeps its own C reference to that face and frees it with
FT_Done_Face when the harfbuzz font is collected. Neither side knows about the other's
lifetime, and Pharo collects the wrappers in whatever order the garbage collector reaches
them, so a library collected before a harfbuzz font that outlived it leaves FT_Done_Face
reading freed memory: the image took four segmentation faults inside
FinalizationProcess class >> finalizationProcess on 21 and 22 October 2026, each one with
FT_Done_Face under hb_blob_destroy at the top of the C stack, minutes after the drawing that
made the objects.
Nothing I hold is ever released, which is what I am for: the corpus makes a few faces per
session, and a leak of that size is cheaper than an image that dies in the middle of a suite.
Send #freeTypeLibrary for the one library every face of this project is built on, and
#retain: for a manager or a face handed to a foreign library; #retained answers what I hold.
"
Class {
	#name : 'VGAlexandrieFontLifetime',
	#superclass : 'Object',
	#classInstVars : [
		'freeTypeLibrary',
		'retained'
	],
	#category : 'VectorGraphics-Cairo-Tests-Fixtures',
	#package : 'VectorGraphics-Cairo-Tests',
	#tag : 'Fixtures'
}

{ #category : 'accessing' }
VGAlexandrieFontLifetime class >> freeTypeLibrary [
	"The one FreeType library every face this project builds for Alexandrie belongs to. It is
	 kept, so it is never collected, and a face harfbuzz still holds therefore never loses the
	 library underneath it."

	^ freeTypeLibrary ifNil: [
		  freeTypeLibrary := self retain: AeFTLibrary newInitialized ]
]

{ #category : 'inspector' }
VGAlexandrieFontLifetime class >> inspectorKept: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Kept'>
	"What is held against the collector, and why each object is here: a FreeType library, a
	 face handed to a foreign library, or a font manager that owns both. Nothing is built and
	 nothing is released by looking, because releasing any of it is the crash this class
	 prevents."

	^ aBuilder newTable
		  items: self retained asArray;
		  addColumn: (SpStringTableColumn
				   title: 'Object'
				   evaluated: [ :each | each class name ]);
		  addColumn: (SpStringTableColumn
				   title: 'Role'
				   evaluated: [ :each | self roleOf: each ]);
		  addColumn: (SpStringTableColumn
				   title: 'Handle'
				   evaluated: [ :each | each printString ]);
		  yourself
]

{ #category : 'inspector' }
VGAlexandrieFontLifetime class >> inspectorKeptContext: aContext [
	"The root of this hierarchy is what keeps the objects, so the tab belongs to it and not to a
	 subclass that would hold nothing of its own."

	^ aContext active: self superclass == Object
]

{ #category : 'accessing' }
VGAlexandrieFontLifetime class >> retain: anObject [
	"Keep that object for the session and answer it, so a call site reads as the expression it
	 already was. A face handed to a foreign library, and the font manager that owns the face
	 cache and the library, are what a caller keeps."

	self retained add: anObject.
	^ anObject
]

{ #category : 'accessing' }
VGAlexandrieFontLifetime class >> retained [
	"What I hold, by identity: two font managers of the same family are two managers and both
	 have to be kept."

	^ retained ifNil: [ retained := IdentitySet new ]
]

{ #category : 'inspector' }
VGAlexandrieFontLifetime class >> roleOf: anObject [
	"Why that object is kept, asked of the object rather than recorded when it arrived."

	anObject == freeTypeLibrary ifTrue: [
		^ 'the FreeType library every face of this project belongs to' ].
	(anObject isKindOf: AeFontManager) ifTrue: [
		^ 'a font manager, which owns a FreeType library and a face cache' ].
	^ 'a face a foreign library may still hold and free with FT_Done_Face'
]
