"
I am the set of rendering choices that Cairo calls a cairo_font_options_t: the antialiasing mode, the hint style, whether the metrics are hinted, and the subpixel order.

I hold each of them as a Symbol, and my setters accept a Symbol, Cairo's own integer code, or one of Alexandrie's enumeration values, so a shared script can hand me any of the three. An unknown name or code is an error rather than a silent default.

Only `hintMetrics` changes a number I answer today: it decides whether a scaled font rounds its extents the way FreeType does. The other three are carried so that a caller can set and read them, and so that the atlas key tells two differently rendered fonts apart.
"
Class {
	#name : 'VGFontOptions',
	#superclass : 'Object',
	#instVars : [
		'antialias',
		'hintStyle',
		'hintMetrics',
		'subpixelOrder'
	],
	#category : 'VectorGraphics-Cairo-Text',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Text'
}

{ #category : 'accessing' }
VGFontOptions class >> antialiasNames [
	"Cairo's cairo_antialias_t, in its own order, so the integer code is the index less one."

	^ #( #default #none #gray #subpixel #fast #good #best )
]

{ #category : 'accessing' }
VGFontOptions class >> hintMetricsNames [
	"Cairo's cairo_hint_metrics_t, in its own order."

	^ #( #default #off #on )
]

{ #category : 'accessing' }
VGFontOptions class >> hintStyleNames [
	"Cairo's cairo_hint_style_t, in its own order."

	^ #( #default #none #slight #medium #full )
]

{ #category : 'converting' }
VGFontOptions class >> nameFor: anObject in: aNameArray [
	"One of my own names, Cairo's own integer code, or one of Alexandrie's enumeration values, the
	 way VGCairoOperator class >> #normalise: accepts all three. An unknown object is an error
	 rather than a silent default, because a wrong font option draws text that looks right and
	 measures wrongly."

	| code |
	anObject isSymbol ifTrue: [
		(aNameArray includes: anObject) ifTrue: [ ^ anObject ].
		^ Error signal: anObject printString , ' is not one of ' , aNameArray printString ].
	code := anObject isInteger
		        ifTrue: [ anObject ]
		        ifFalse: [ anObject value ].
	(code between: 0 and: aNameArray size - 1) ifFalse: [
		^ Error signal: code printString , ' is not a code of ' , aNameArray printString ].
	^ aNameArray at: code + 1
]

{ #category : 'accessing' }
VGFontOptions class >> subpixelOrderNames [
	"Cairo's cairo_subpixel_order_t, in its own order."

	^ #( #default #rgb #bgr #vrgb #vbgr )
]

{ #category : 'comparing' }
VGFontOptions >> = anObject [
	"Two options that render the same way are the same key in the glyph atlas."

	^ self class = anObject class and: [
		  antialias = anObject antialias and: [
			  hintStyle = anObject hintStyle and: [
				  hintMetrics = anObject hintMetrics and: [
					  subpixelOrder = anObject subpixelOrder ] ] ] ]
]

{ #category : 'accessing' }
VGFontOptions >> antialias [
	^ antialias
]

{ #category : 'accessing' }
VGFontOptions >> antialias: anObject [
	antialias := self class nameFor: anObject in: self class antialiasNames
]

{ #category : 'comparing' }
VGFontOptions >> hash [
	^ ((antialias hash bitXor: hintStyle hash) bitXor: hintMetrics hash)
	  bitXor: subpixelOrder hash
]

{ #category : 'accessing' }
VGFontOptions >> hintMetrics [
	^ hintMetrics
]

{ #category : 'accessing' }
VGFontOptions >> hintMetrics: anObject [
	hintMetrics := self class nameFor: anObject in: self class hintMetricsNames
]

{ #category : 'accessing' }
VGFontOptions >> hintStyle [
	^ hintStyle
]

{ #category : 'accessing' }
VGFontOptions >> hintStyle: anObject [
	hintStyle := self class nameFor: anObject in: self class hintStyleNames
]

{ #category : 'testing' }
VGFontOptions >> hintsMetrics [
	"Cairo treats its default as off for the metrics, which is what the FreeType font backend does
	 when no option says otherwise."

	^ hintMetrics = #on
]

{ #category : 'initialization' }
VGFontOptions >> initialize [

	super initialize.
	antialias := #default.
	hintStyle := #default.
	hintMetrics := #default.
	subpixelOrder := #default
]

{ #category : 'inspector' }
VGFontOptions >> inspectorNames: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Cairo names'>
	"My four options, each beside the class that names its values the way Alexandrie names them
	 and the value that class answers for the name I hold. The value is asked of the real
	 enumeration, so a name this package stops knowing shows up here as 'answers no such name'
	 rather than as a row that still looks right."

	^ aBuilder newTable
		  items: {
				  { 'Antialias'. self antialias. VGCairoAntialias }.
				  { 'Hint style'. self hintStyle. VGCairoHintStyle }.
				  { 'Hint metrics'. self hintMetrics. VGCairoHintMetrics }.
				  { 'Subpixel order'. self subpixelOrder. VGCairoSubpixelOrder } };
		  addColumn: (SpStringTableColumn title: 'Option' evaluated: [ :each |
					   each first ]);
		  addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :each |
					   each second printString ]);
		  addColumn: (SpStringTableColumn title: 'Named by' evaluated: [ :each |
					   each third name ]);
		  addColumn: (SpStringTableColumn title: 'That class answers' evaluated: [ :each |
					   (each third names includes: each second)
						   ifTrue: [ (each third perform: each second) printString ]
						   ifFalse: [ 'answers no such name' ] ]);
		  yourself
]

{ #category : 'printing' }
VGFontOptions >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(antialias: ';
		print: antialias;
		nextPutAll: ' hintStyle: ';
		print: hintStyle;
		nextPutAll: ' hintMetrics: ';
		print: hintMetrics;
		nextPutAll: ' subpixelOrder: ';
		print: subpixelOrder;
		nextPut: $)
]

{ #category : 'accessing' }
VGFontOptions >> subpixelOrder [
	^ subpixelOrder
]

{ #category : 'accessing' }
VGFontOptions >> subpixelOrder: anObject [
	subpixelOrder := self class nameFor: anObject in: self class subpixelOrderNames
]
