"
I am the inventory of the Cairo calling surface that Bloc and AeCanvas really send, and I am the specification our replacement classes answer to.

I hold three frozen lists of selectors, split by instance side and class side: one for AeCairoContext, one for AeCairoSurface and one for AeCairoPattern and its subclasses. The lists are frozen rather than computed because the engine image loads neither Bloc nor Alexandrie, and the inventory has to be readable there. When Alexandrie is loaded, my measured* methods recompute the same intersection from the live classes, and VGCairoInventoryTest fails if a frozen list has drifted, so a frozen list cannot go stale unnoticed.

Key methods: contextSelectors, contextClassSelectors, surfaceSelectors, surfaceClassSelectors, patternSelectors, patternClassSelectors give the frozen lists; measuredSelectorsOf:excluding: recomputes one; selectorsExcludedFromInventory says which selectors the measurement over-reports and why.
"
Class {
	#name : 'VGCairoInventory',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Inventory',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Inventory'
}

{ #category : 'inventory' }
VGCairoInventory class >> allInventorySelectors [
	"Every selector in the inventory, both sides, with no duplicates."

	^ (self contextSelectors , self contextClassSelectors , self surfaceSelectors
	   , self surfaceClassSelectors , self patternSelectors , self patternClassSelectors) asSet
		  asSortedCollection asArray
]

{ #category : 'measuring' }
VGCairoInventory class >> callerPackageNames [
	"The packages whose sends define the inventory: everything Bloc, plus Alexandrie's own canvas,
	 which is the other client of the Cairo layer. Test packages are left out, because a test may
	 exercise a selector no renderer ever sends."

	^ (Smalltalk packageOrganizer packages
		   select: [ :each |
			   (('Bloc*' match: each name) or: [ each name = 'Alexandrie-Canvas' ])
				   and: [ ('*-Tests' match: each name) not ] ])
		  collect: [ :each | each name ]
]

{ #category : 'inventory - context' }
VGCairoInventory class >> contextClassSelectors [
	"Class-side selectors sent to AeCairoContext. #initialize is deliberately absent: it is Pharo's
	 class-initialisation hook, and the measurement reports it only because unrelated Bloc code
	 sends #initialize to its own classes."

	^ #( #new #newFor: )
]

{ #category : 'inventory - context' }
VGCairoInventory class >> contextSelectors [
	"Instance-side selectors that the Bloc code packages and Alexandrie-Canvas send to an
	 AeCairoContext. Measured, not guessed: see measuredSelectorsOf:excluding:."

	^ #( #annulusSectorCenter:from:to:innerRadius:outerRadius: #antialias: #appendGlyphsPath:
	     #arcCenter:radius:startAngle:endAngle:cw: #arcCenter:radius:startAngle:sweep:
	     #arcCenterX:centerY:radius:startAngle:endAngle: #autoRelease #circleCenterX:y:radius:
	     #circleSectorCenter:from:to:radius: #clearColor: #clearTransparent #clip
	     #clipPreservingPath #closePath #currentPointInUserSpace #currentTarget #curveVia:via:to:
	     #curveViaX:y:viaX:y:toX:y: #ellipseWidth:height: #externallyFree #fill #fillPreservingPath
	     #fillPreservingPath: #fontExtents #fontSize: #getGlyphExtentsOf:size:into: #lineFrom:to:
	     #lineTo: #lineToX:y: #maskGroupWith: #maskSurface:x:y: #matrix #matrix: #moveTo: #paint
	     #paintGroupWith: #paintGroupWith:alpha: #paintWithAlpha:
	     #quadraticCurveFromCurrentPoint:via:to: #rectangle: #rectangleTo:
	     #rectangleX:y:width:height: #restoreStateAfter: #rotateByRadians: #rotateByRadians:center:
	     #roundedRectangleLeft:top:right:bottom:tl:tr:br:bl: #scaleBy: #scaledFont:
	     #setIdentityMatrix #setOperatorClear #showGlyphs: #source #sourceColor: #sourceColorR:g:b:
	     #sourceColorR:g:b:a: #sourcePattern: #sourceSurface: #status #stroke #strokeCap:
	     #strokeDashPattern:offset: #strokeJoin: #strokeJoinMiterLimit: #strokePreservingPath
	     #strokeSize: #tolerance: #transformWith: #translateBy: #useFillRuleEvenOdd
	     #useFillRuleWinding )
]

{ #category : 'measuring' }
VGCairoInventory class >> excludedPatternClassNames [
	"AeCairoMeshPattern declares moveTo:, lineTo: and the curve selectors, which collide with the
	 context's path selectors and would be attributed to patterns by name alone. No method in the
	 caller packages names that class."

	^ #( #AeCairoMeshPattern )
]

{ #category : 'inspecting' }
VGCairoInventory class >> inspectorUnitProgress: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Units'>
	"How far phase 1 has got, counted from the compiled methods by #progressReport."

	^ aBuilder newTable
		  items: self progressReport;
		  addColumn: (SpStringTableColumn title: 'Unit' evaluated: [ :each | each first ]);
		  addColumn: (SpStringTableColumn title: 'Selectors' evaluated: [ :each | each second ]);
		  addColumn: (SpStringTableColumn title: 'Still skeletons' evaluated: [ :each | each third ]);
		  addColumn: (SpStringTableColumn
				   title: 'Implemented'
				   evaluated: [ :each | (each second - each third) printString , ' / ' , each second printString ]);
		  yourself
]

{ #category : 'inspecting' }
VGCairoInventory class >> inspectorUnitProgressContext: aContext [
	"The report describes the whole plan, so the tab belongs to the root of this hierarchy and not to
	 a subclass that might narrow it."

	aContext active: self superclass = Object
]

{ #category : 'measuring' }
VGCairoInventory class >> isLiveCairoAvailable [
	"Answer whether Alexandrie is loaded, so a test can measure the real classes instead of reading
	 the frozen lists. The engine image loads neither Bloc nor Alexandrie."

	^ #( #AeCairoContext #AeCairoSurface #AeCairoPattern ) allSatisfy: [ :each |
		  (Smalltalk at: each ifAbsent: [ nil ]) notNil ]
]

{ #category : 'querying' }
VGCairoInventory class >> isSkeletonSelector: aSelector [
	^ (self skeletonMethodsNamed: aSelector) notEmpty
]

{ #category : 'measuring' }
VGCairoInventory class >> measuredSelectorsOf: aClass excluding: excludedClassNames [
	"Answer an association of the instance-side and the class-side selectors that the caller
	 packages send to aClass or one of its subclasses. A subclass named in excludedClassNames is
	 skipped: AeCairoMeshPattern declares path selectors whose names collide with the context's."

	| sent instanceSide classSide |
	sent := self selectorsSentByCallers.
	instanceSide := Set new.
	classSide := Set new.
	aClass withAllSubclasses do: [ :each |
		(excludedClassNames includes: each name) ifFalse: [
			instanceSide addAll: (each selectors select: [ :one | sent includes: one ]).
			classSide addAll: (each class selectors select: [ :one | sent includes: one ]) ] ].
	^ instanceSide asSortedCollection asArray -> classSide asSortedCollection asArray
]

{ #category : 'inventory - pattern' }
VGCairoInventory class >> patternClassSelectors [
	"Class-side selectors sent to a pattern class: the two gradient constructors AeCanvas uses, the
	 colour constructors and the surface pattern constructor."

	^ #( #from:to: #from:to:addStopsFrom:
	     #innerCenter:innerRadius:outerCenter:outerRadius:addStopsFrom: #new #newFrom: #r:g:b:
	     #r:g:b:alpha: #surface: )
]

{ #category : 'inventory - pattern' }
VGCairoInventory class >> patternSelectors [
	"Instance-side selectors sent to an AeCairoPattern. The five path selectors the measurement also
	 reports - moveTo:, lineTo:, lineToX:y:, curveVia:via:to: and curveViaX:y:viaX:y:toX:y: - belong
	 to AeCairoMeshPattern, which no Bloc or Alexandrie-Canvas method names, so they are excluded."

	^ #( #autoRelease #externallyFree #filter: #matrix #matrix: #status #type )
]

{ #category : 'units' }
VGCairoInventory class >> planUnits [
	"The units of phase 1 that VECTORCANVAS-PLAN.md declares. A skeleton may only name one of
	 these, which is what keeps the code and the plan from drifting apart."

	^ #( '1.0' '1.1' '1.2' '1.3' '1.4' '1.5' '1.6' '1.7' '1.8' '1.9' )
]

{ #category : 'querying' }
VGCairoInventory class >> progressReport [
	"One row per unit: the unit, how many selectors it owes, and how many of those are still
	 skeletons. Every number is read from the compiled methods, so the report cannot drift from the
	 code."

	^ self planUnits collect: [ :unit |
		  | selectors |
		  selectors := self selectorsForUnit: unit.
		  {
			  unit.
			  selectors size.
			  (selectors count: [ :each | self isSkeletonSelector: each ]) } ]
]

{ #category : 'units' }
VGCairoInventory class >> selectorUnitTable [
	"Which unit owes which selector. One entry per unit, in plan order. A selector that several
	 classes declare - status, autoRelease, matrix: - is owed by the same unit everywhere."

	^ {
		  ('1.0' -> #( #autoRelease #externallyFree #status #new #newFor: )).
		  ('1.1' -> #( #asForm #clearColor: #clearTransparent #colorAt: #currentTarget #data
		                #deviceOffset: #deviceScale #deviceScale: #deviceScaleMatrix #deviceScaleX:y:
		                #extent #extent: #extent:format: #extent:to: #finish #flush #fromForm:
		                #height #newContext #newSimilarImageFormat:width:height: #stride
		                #unownedNewForData:format:width:height:stride: #width #writePngTo: )).
		  ('1.2' -> #( #currentPointInUserSpace #matrix #matrix: #restoreStateAfter:
		                #rotateByRadians: #rotateByRadians:center: #scaleBy: #setIdentityMatrix
		                #transformWith: #translateBy: )).
		  ('1.3' -> #( #annulusSectorCenter:from:to:innerRadius:outerRadius:
		                #arcCenter:radius:startAngle:endAngle:cw:
		                #arcCenter:radius:startAngle:sweep:
		                #arcCenterX:centerY:radius:startAngle:endAngle: #circleCenterX:y:radius:
		                #circleSectorCenter:from:to:radius: #closePath #curveVia:via:to:
		                #curveViaX:y:viaX:y:toX:y: #ellipseWidth:height: #fill #fillPreservingPath
		                #fillPreservingPath: #lineFrom:to: #lineTo: #lineToX:y: #moveTo: #paint
		                #quadraticCurveFromCurrentPoint:via:to: #rectangle: #rectangleTo:
		                #rectangleX:y:width:height:
		                #roundedRectangleLeft:top:right:bottom:tl:tr:br:bl: #stroke
		                #strokePreservingPath #useFillRuleEvenOdd #useFillRuleWinding )).
		  ('1.4' -> #( #antialias: #strokeCap: #strokeDashPattern:offset: #strokeJoin:
		                #strokeJoinMiterLimit: #strokeSize: #tolerance: )).
		  ('1.5' -> #( #filter: #from:to: #from:to:addStopsFrom:
		                #innerCenter:innerRadius:outerCenter:outerRadius:addStopsFrom: #newFrom:
		                #r:g:b: #r:g:b:alpha: #source #sourceColor: #sourceColorR:g:b:
		                #sourceColorR:g:b:a: #sourcePattern: #sourceSurface: #surface: #type )).
		  ('1.6' -> #( #clip #clipPreservingPath )).
		  ('1.7' -> #( #maskGroupWith: #maskSurface:x:y: #paintGroupWith: #paintGroupWith:alpha:
		                #paintWithAlpha: #setOperatorClear )).
		  ('1.8' -> #( #appendGlyphsPath: #fontExtents #fontSize: #getGlyphExtentsOf:size:into:
		                #scaledFont: #showGlyphs: )) }
]

{ #category : 'measuring' }
VGCairoInventory class >> selectorsExcludedFromInventory [
	"Selectors the measurement over-reports, with the reason, so the drift test can subtract them
	 instead of hiding a mismatch. #initialize and #initializeWith: are construction glue sent by
	 unrelated Bloc classes to their own objects; #image exists only on the Quartz and Win32
	 surfaces."

	^ #( #initialize #initializeWith: #image )
]

{ #category : 'querying' }
VGCairoInventory class >> selectorsForUnit: aUnitString [
	^ (self selectorUnitTable
		   detect: [ :each | each key = aUnitString ]
		   ifNone: [ aUnitString -> #(  ) ]) value
]

{ #category : 'measuring' }
VGCairoInventory class >> selectorsSentByCallers [
	"Every selector sent anywhere in the caller packages. The intersection with a class's own
	 selectors is what the inventory is."

	| sent |
	sent := Set new.
	self callerPackageNames do: [ :each |
		(Smalltalk packageOrganizer packageNamed: each) methods do: [ :method |
			sent addAll: method messages ] ].
	^ sent
]

{ #category : 'querying' }
VGCairoInventory class >> skeletonMethodsNamed: aSelector [
	"Every method of the VGCairoObject hierarchy, on either side, that answers aSelector and is still
	 a skeleton."

	^ VGCairoObject withAllSubclasses flatCollect: [ :each |
		  { each. each class } inject: OrderedCollection new into: [ :found :behavior |
			  (behavior compiledMethodAt: aSelector ifAbsent: [ nil ]) ifNotNil: [ :method |
				  (method sendsSelector: #notYetImplementedIn:selector:) ifTrue: [ found add: method ] ].
			  found ] ]
]

{ #category : 'inventory - surface' }
VGCairoInventory class >> surfaceClassSelectors [
	"Class-side selectors sent to an AeCairoSurface class. unownedNewForData:format:width:height:
	 stride: is the one the host window path uses: BARenderer wraps a raw pixel address with it."

	^ #( #extent: #extent:format: #extent:to: #fromForm: #new
	     #unownedNewForData:format:width:height:stride: )
]

{ #category : 'inventory - surface' }
VGCairoInventory class >> surfaceSelectors [
	"Instance-side selectors sent to an AeCairoSurface. #image is deliberately absent: only
	 AeCairoQuartzSurface and AeCairoWin32Surface define it, and it wraps a platform-specific Cairo
	 call we do not reproduce."

	^ #( #asForm #autoRelease #colorAt: #data #deviceOffset: #deviceScale #deviceScale:
	     #deviceScaleMatrix #deviceScaleX:y: #extent #externallyFree #finish #flush #height
	     #newContext #newSimilarImageFormat:width:height: #status #stride #width #writePngTo: )
]

{ #category : 'units' }
VGCairoInventory class >> unitForSelector: aSelector [
	"Answer the unit that owes aSelector, or nil when the table does not name it. A nil is a fault,
	 and VGCairoSkeletonTest reports it."

	self selectorUnitTable do: [ :each |
		(each value includes: aSelector) ifTrue: [ ^ each key ] ].
	^ nil
]
