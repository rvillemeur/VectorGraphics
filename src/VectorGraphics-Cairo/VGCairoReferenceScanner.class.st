"
I read the literal frame of compiled methods and answer the classes of the Cairo package
that they name.
A class named in a method is reached as soon as the method runs, so a project that is meant
to work with no `libcairo` present must name none of them, and that is a fact about the code
rather than about one run.
I am used by the tests of the failover, which assert that `offenders` is empty, and by the
inspector views that show the same scan.
`bypassingBlocMethods` answers the other side of the seam: the methods of the Bloc backend
package that build a Cairo object themselves instead of asking the canvas, which are the
methods a failover cannot reach by subclassing the canvas.
Literals are read through `allLiterals` and not `referencedClasses`, because a full block
carries its own literal frame and a class named only inside a block would be missed.

"
Class {
	#name : 'VGCairoReferenceScanner',
	#superclass : 'Object',
	#instVars : [
		'packageNames'
	],
	#category : 'VectorGraphics-Cairo-Reflection',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Reflection'
}

{ #category : 'constants' }
VGCairoReferenceScanner class >> blocBackendPackageName [
	"The Bloc backend built on Cairo, whose canvas this project subclasses."

	^ 'Bloc-Alexandrie'
]

{ #category : 'constants' }
VGCairoReferenceScanner class >> cairoPackageName [
	"The package whose classes must not be named anywhere in this project."

	^ 'Alexandrie-Cairo'
]

{ #category : 'instance creation' }
VGCairoReferenceScanner class >> default [
	"A scanner over every package of this project."

	^ self new
]

{ #category : 'constants' }
VGCairoReferenceScanner class >> projectPackageNames [
	"Every package of this project except the test packages, so a package added later is scanned
	 without this list being edited. The tests are left out because the proof that no Cairo
	 function runs needs a positive control, which calls Cairo on purpose."

	^ (PackageOrganizer default packages select: [ :each |
		   (each name beginsWith: self projectPackagePrefix) and: [
			   (each name endsWith: self testPackageSuffix) not ] ]) collect: [ :each |
		  each name ]
]

{ #category : 'constants' }
VGCairoReferenceScanner class >> projectPackagePrefix [
	"Every package of this project starts with this, the engine package itself included, so the
	 scan covers the whole repository and not only the backend."

	^ 'VectorGraphics'
]

{ #category : 'constants' }
VGCairoReferenceScanner class >> testPackageSuffix [
	^ '-Tests'
]

{ #category : 'scanning' }
VGCairoReferenceScanner >> bypassingBlocMethods [
	"The methods of the Bloc backend package that build a Cairo object themselves. A failover
	 replaces the canvas, so these are the methods it cannot reach, whatever it overrides."

	^ (self offendersIn: self class blocBackendPackageName) collect: [ :each |
		  each key ]
]

{ #category : 'scanning' }
VGCairoReferenceScanner >> cairoClassesNamedBy: aCompiledMethod [
	"The classes of the Cairo package that one method names. Literals are read through
	 `allLiterals`, because a full block keeps its own literal frame and a class named inside a
	 block would be missed otherwise."

	^ aCompiledMethod allLiterals
		  select: [ :each |
			  each isVariableBinding and: [
				  each value isBehavior and: [
					  each value package notNil and: [
						  each value package name = self class cairoPackageName ] ] ] ]
		  thenCollect: [ :each | each value ]
]

{ #category : 'initialization' }
VGCairoReferenceScanner >> initialize [
	super initialize.
	packageNames := self class projectPackageNames
]

{ #category : 'inspector' }
VGCairoReferenceScanner >> inspectorOffenders: aBuilder [
	<inspectorPresentationOrder: 11 title: 'Offenders'>
	"The methods that name a Cairo class, with the classes each one names. An empty table is what
	 a project that works without that library looks like."

	^ aBuilder newTable
		  items: self offenders;
		  addColumn: (SpStringTableColumn
				   title: 'Method'
				   evaluated: [ :each | each key printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Classes named'
				   evaluated: [ :each |
					   ((each value collect: [ :class | class name ]) asSortedCollection: [
						    :a :b | a <= b ]) asArray printString ]);
		  yourself
]

{ #category : 'inspector' }
VGCairoReferenceScanner >> inspectorOffendersContext: aContext [
	aContext active: packageNames notNil
]

{ #category : 'inspector' }
VGCairoReferenceScanner >> inspectorScan: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Scan'>
	"One row per scanned package, with the number of its methods that name a Cairo class. The
	 scan is run rather than described, so this tab is the answer itself."

	^ aBuilder newTable
		  items: (self packageNames asSortedCollection: [ :a :b | a <= b ])
			       asOrderedCollection;
		  addColumn: (SpStringTableColumn
				   title: 'Package'
				   evaluated: [ :each | each ]);
		  addColumn: (SpStringTableColumn
				   title: 'Methods naming a Cairo class'
				   evaluated: [ :each | (self offendersIn: each) size printString ]);
		  yourself
]

{ #category : 'inspector' }
VGCairoReferenceScanner >> inspectorScanContext: aContext [
	aContext active: packageNames notNil
]

{ #category : 'scanning' }
VGCairoReferenceScanner >> offenders [
	"Every method of the scanned packages that names a Cairo class. An empty answer is what the
	 failover claims."

	^ (self packageNames flatCollect: [ :each | self offendersIn: each ])
		  asOrderedCollection
]

{ #category : 'scanning' }
VGCairoReferenceScanner >> offendersIn: aPackageName [
	"An association per method of that package that names a Cairo class, from the method to the
	 classes it names. Extension methods are read too, because `package methods` answers them."

	| package |
	package := PackageOrganizer default
		           packageNamed: aPackageName
		           ifAbsent: [ ^ #(  ) ].
	^ (package methods collect: [ :each |
		   each -> (self cairoClassesNamedBy: each) ]) select: [ :each |
		  each value notEmpty ]
]

{ #category : 'accessing' }
VGCairoReferenceScanner >> packageNames [
	^ packageNames
]

{ #category : 'accessing' }
VGCairoReferenceScanner >> packageNames: aCollection [
	packageNames := aCollection
]
