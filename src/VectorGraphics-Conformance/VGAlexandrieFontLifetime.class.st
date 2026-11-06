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

The library belongs to the run of the virtual machine that opened it, and a session ends when the
image is saved: an image that comes back from a save or a crash holds an FT_Library of a process
that no longer exists, and every face built on it raises an invalid library handle — which is what
the whole Cairo suite did on 6 November 2026. So the run is stamped when the library is opened and
read on every ask: a library of another run is dropped and a new one is opened. Dropped, never
freed, and everything already kept stays kept, the dead faces among it, because a face the
collector can reach is a face it finalises with FT_Done_Face.

Send #isOfThisImageRun for whether the library in hand belongs to this run; the Lifetime tab shows
the same fact to a reader.
"
Class {
	#name : 'VGAlexandrieFontLifetime',
	#superclass : 'Object',
	#classInstVars : [
		'freeTypeLibrary',
		'retained',
		'imageRun'
	],
	#category : 'VectorGraphics-Conformance',
	#package : 'VectorGraphics-Conformance'
}

{ #category : 'lifetime' }
VGAlexandrieFontLifetime class >> forgetFreeTypeLibraryOfAnotherImageRun [
	"Let go of a library opened by a run of the virtual machine that has ended, and send it
	 nothing at all: FT_Done_Library on a handle of a dead process is the same dereference of
	 freed memory as building a face on one. What is retained stays retained for the same
	 reason — the faces of the dead run among it — because a face the collector can reach is a
	 face it finalises with FT_Done_Face."
	freeTypeLibrary := nil.
	imageRun := nil
]

{ #category : 'accessing' }
VGAlexandrieFontLifetime class >> freeTypeLibrary [
	"The one FreeType library every face this project builds for Alexandrie belongs to. It is
	 kept, so it is never collected, and a face harfbuzz still holds therefore never loses the
	 library underneath it."
	"The library belongs to the run of the virtual machine that opened it. A session ends when
	 the image is saved, so an image that comes back holding one holds an FT_Library of a
	 process that no longer exists, and every face built on it raises an invalid library handle.
	 The run is stamped here and read on every ask: a library of another run is dropped, and one
	 is opened again."
	self isOfThisImageRun ifFalse: [ self forgetFreeTypeLibraryOfAnotherImageRun ].
	^ freeTypeLibrary ifNil: [
		  imageRun := Smalltalk session.
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

{ #category : 'inspector' }
VGAlexandrieFontLifetime class >> inspectorLifetime: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Lifetime'>
	"Where a reader sees whether the library in hand belongs to this run of the virtual machine.
	 A restarted image comes back holding one of a run that has ended, and nothing about the
	 object says so: the handle prints the same. Looking opens no library, so a class that has
	 been asked for none still reads its own state here."
	^ aBuilder newTable
		  items: self lifetimeRows;
		  addColumn: (SpStringTableColumn
				   title: 'Fact'
				   evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each second printString ]);
		  yourself
]

{ #category : 'inspector' }
VGAlexandrieFontLifetime class >> inspectorLifetimeContext: aContext [
	"The root of this hierarchy is what holds the library, so the tab belongs to it and not to a
	 subclass that would hold nothing of its own."
	^ aContext active: self superclass == Object
]

{ #category : 'testing' }
VGAlexandrieFontLifetime class >> isOfThisImageRun [
	"Whether the library held was opened by the run of the virtual machine that is running now.
	 A class that holds no library at all answers false, which is the degenerate state and is
	 not a failure: the next ask opens one."
	^ freeTypeLibrary isNotNil and: [ imageRun == Smalltalk session ]
]

{ #category : 'inspector' }
VGAlexandrieFontLifetime class >> lifetimeRows [
	"The two facts the crash of 6 November 2026 turned on, asked of the class rather than
	 restated here, so neither row can drift from the code it reports: whether the library held
	 was opened by the run of the virtual machine that is running now, and how many objects are
	 kept against the collector. A class that has opened nothing answers the first with false,
	 which is the degenerate state."
	^ { 
		  { 'Library of this image run'. self isOfThisImageRun }.
		  { 'Objects kept'. self retained size } }
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
	(anObject isKindOf: AeFTLibrary) ifTrue: [
		^ 'a FreeType library of an image run that has ended, kept and never freed' ].
	(anObject isKindOf: AeFontManager) ifTrue: [
		^ 'a font manager, which owns a FreeType library and a face cache' ].
	^ 'a face a foreign library may still hold and free with FT_Done_Face'
]
