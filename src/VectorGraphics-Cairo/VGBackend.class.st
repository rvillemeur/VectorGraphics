"
I am the boundary between the recorded frame and whatever draws it.

Rule three of the plan freezes my interface at three messages: fillSegments:paint:clip:operator:,
blitSurface:at:paint:clip:operator: and drainInto:. The blit one grew its clip and its operator in
unit 1.7, where a mask became drawable: the surface it names is the mask, its alpha channel says how
much of the paint reaches each pixel, and its colours are never read. Nothing above me knows whether
a paint is evaluated by a Pharo method or by a SPIR-V function, and nothing below me knows what a
BlPaint or an AeCairoPattern is.
A backend below me that raises VGBackendFailure is answered by replaying the same display list on
the software backend, which is why the failover costs nothing to arrange.
My subclasses are VGSoftwareBackend here and the Vulkan backend in phase 2.
"
Class {
	#name : 'VGBackend',
	#superclass : 'Object',
	#classInstVars : [
		'rejectedClasses',
		'preferredClass'
	],
	#category : 'VectorGraphics-Cairo-Backend',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Backend'
}

{ #category : 'blurring' }
VGBackend class >> blurFilterClass [
	"The Gaussian blur filter a shadow drawn through me is blurred with. A blur is a pass over the
	 alpha of a surface and not a drawing verb, so it is named here rather than recorded in a
	 display list, and a backend that blurs elsewhere answers its own filter. The answer is the
	 host filter, because a backend that says nothing about blurring blurs on the host."

	^ VGA8GaussianBlurFilter
]

{ #category : 'selection' }
VGBackend class >> candidateClasses [
	"Every backend that offers itself for selection, best first and the failover last. They are
	 found by reflection over my subclasses, so this package names no Vulkan class and a backend
	 written later is chosen without this method being edited. A class rejected by a failure is
	 left out."

	^ ((self withAllSubclasses select: [ :each |
		    each isCandidate and: [ (self rejections includes: each) not ] ])
		   asSortedCollection: [ :one :other |
		   one preferenceRank <= other preferenceRank ]) asArray
]

{ #category : 'selection' }
VGBackend class >> clearPreference [
	"Forget the chosen class, so that the next frame probes again. The rejections stand: a
	 backend that failed is not probed a second time."

	preferredClass := nil
]

{ #category : 'selection' }
VGBackend class >> failover [
	"The backend a failed frame is replayed on. It is the software one and not whatever selection
	 would choose next, because a recovery may not fail in its turn: the frame has to be drawn
	 once the first attempt has given up on it."

	^ VGSoftwareBackend new
]

{ #category : 'selection' }
VGBackend class >> firstAvailableClass [
	"The first candidate whose probe really draws something. A probe below the first that answers
	 is never run, because a probe costs a device and a dispatch."

	self candidateClasses do: [ :each |
		each probe ifNotNil: [ :backend | ^ each ] ].
	^ VGBackendFailure
		  signalFor: nil
		  because: 'no backend is available, although the software one cannot fail'
]

{ #category : 'selection' }
VGBackend class >> hardwareRank [
	"The rank of a backend that draws on a device. It is below the software rank, so such a
	 backend is probed first and used whenever its probe answers."

	^ 100
]

{ #category : 'inspector' }
VGBackend class >> inspectorBoundary: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Boundary'>
	"The messages a backend answers, read from my own selectors rather than listed here, so the
	 tab says what the frozen boundary really is. Which subclasses answer each one is asked of
	 the subclasses themselves."

	^ aBuilder newTable
		  items: self selectors asSortedCollection asArray;
		  addColumn: (SpStringTableColumn
				   title: 'Message'
				   evaluated: [ :each | each ]);
		  addColumn: (SpStringTableColumn
				   title: 'Arguments'
				   evaluated: [ :each | each numArgs printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Answered by'
				   evaluated: [ :each |
					   ((self allSubclasses select: [ :class |
						     class includesSelector: each ]) collect: [ :class |
						    class name ]) asSortedCollection asArray printString ]);
		  yourself
]

{ #category : 'inspector' }
VGBackend class >> inspectorBoundaryContext: aContext [
	"The boundary belongs to the root of the hierarchy, not to a particular backend."

	aContext active: self superclass == Object
]

{ #category : 'inspector' }
VGBackend class >> inspectorSelection: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Selection'>
	"Which backend draws the frames of this image and why. Every row is asked of the real
	 selection rule rather than described here: the rank each backend declares, whether it stands
	 for selection, whether a failure rejected it and whether it is the one chosen. Nothing is
	 probed, so opening the tab opens no device."

	^ aBuilder newTable
		  items: ((self withAllSubclasses asSortedCollection: [ :one :other |
					    one preferenceRank <= other preferenceRank ]) asArray);
		  addColumn: (SpStringTableColumn
				   title: 'Backend'
				   evaluated: [ :each | each name ]);
		  addColumn: (SpStringTableColumn
				   title: 'Rank'
				   evaluated: [ :each | each preferenceRank printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Stands for selection'
				   evaluated: [ :each | each isCandidate printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Rejected'
				   evaluated: [ :each | (self rejections includes: each) printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Draws'
				   evaluated: [ :each |
					   (self preferredClassOrNil == each) printString ]);
		  yourself
]

{ #category : 'inspector' }
VGBackend class >> inspectorSelectionContext: aContext [
	"Selection belongs to the root of the hierarchy, not to a particular backend: the state it
	 reads is kept here and the table covers the whole hierarchy."

	aContext active: self superclass == Object
]

{ #category : 'selection' }
VGBackend class >> isCandidate [
	"Whether selection may choose me. I am abstract and a test fixture is not a backend anybody
	 asked for, so the answer is no unless a backend says otherwise."

	^ false
]

{ #category : 'selection' }
VGBackend class >> prefer: aBackendClass [
	"Draw through that backend class from now on, without probing anything. This is how a test
	 forces a backend and how a caller who knows the machine overrides the probe."

	preferredClass := aBackendClass
]

{ #category : 'selection' }
VGBackend class >> preferenceRank [
	"Where I stand in the order candidates are probed in, lowest first. The failover carries the
	 highest rank of all, so nothing is probed after it."

	^ self softwareRank
]

{ #category : 'selection' }
VGBackend class >> preferred [
	"A new instance of the preferred class on every send. A backend records in itself the frame
	 it is draining, and reading a pixel of one surface drains another, so a surface owns its
	 instance and selection owns only the class. One instance shared by every surface made each
	 drain replay the commands of the other, and no frame ended."

	^ self preferredClass new
]

{ #category : 'selection' }
VGBackend class >> preferredClass [
	"The class every surface of this image draws through. The probe below is a real dispatch and
	 not a check that a library is present, and it costs 72 ms on an idle machine and more than
	 eight seconds on a loaded one, so it is made once and the answer kept."

	^ preferredClass ifNil: [ preferredClass := self firstAvailableClass ]
]

{ #category : 'selection' }
VGBackend class >> preferredClassOrNil [
	"The class already chosen, or nil while none has been. It answers without probing, which is
	 what a caller keeping and restoring the preference needs."

	^ preferredClass
]

{ #category : 'selection' }
VGBackend class >> probe [
	"An instance of me if I can draw on this machine, nil if I cannot. A candidate overrides this
	 with a drawing it really makes, because a library present on disk says nothing about a device
	 that works."

	^ nil
]

{ #category : 'selection' }
VGBackend class >> reject: aBackendClass [
	"Take that backend out of selection, and forget the preference if it is the one that failed,
	 so that the next frame is drawn by whatever ranks behind it."

	self rejections add: aBackendClass.
	preferredClass == aBackendClass ifTrue: [ preferredClass := nil ]
]

{ #category : 'selection' }
VGBackend class >> rejectedClasses [
	"The backends a failure has taken out of selection for the rest of this session. A fault is
	 the device or the driver and not the instance, so rejection is by class.
	 The answer is a copy, so that a caller keeping the selection state keeps what it was and not
	 a window on what it becomes."

	^ self rejections copy
]

{ #category : 'selection - private' }
VGBackend class >> rejections [
	"The set a rejection is added to and selection reads. It is mine, so nothing outside is
	 handed it."

	^ rejectedClasses ifNil: [ rejectedClasses := Set new ]
]

{ #category : 'selection' }
VGBackend class >> restorePreference: aBackendClassOrNil rejections: aCollection [
	"Put the selection state back where a caller found it. Both are class-side state of mine, so
	 a test that forces a backend or fails one would leak into the next without this. The
	 rejections are taken as a set whatever collection they arrive in, because a rejection is
	 added to them later."

	preferredClass := aBackendClassOrNil.
	rejectedClasses := aCollection asSet
]

{ #category : 'selection' }
VGBackend class >> softwareRank [
	"The rank of a backend that draws every pixel with the processor. It is the highest rank of
	 the scale, so such a backend is probed after every other one and is the failover."

	^ 1000
]

{ #category : 'drawing' }
VGBackend >> blitSurface: aSurface at: aPoint paint: aPaint clip: aClip operator: anOperator [
	self subclassResponsibility
]

{ #category : 'draining' }
VGBackend >> drainInto: aTarget [
	"Write everything recorded since the last drain into that target and keep nothing."
	self subclassResponsibility
]

{ #category : 'drawing' }
VGBackend >> fillSegments: aSegments paint: aPaint clip: aRectangle operator: aSymbol [
	self subclassResponsibility
]
