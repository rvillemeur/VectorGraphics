Extension { #name : 'BARenderer' }

{ #category : '*VectorGraphics-Bloc' }
BARenderer >> canvas [
	"An extension of this project, because every renderer of ours is asked which canvas it draws
	 the frame through and the three of them are siblings under this class. A renderer builds one
	 canvas and reuses it, giving it the surface of each damaged rectangle in turn."

	^ aeCanvas
]

{ #category : '*VectorGraphics-Bloc' }
BARenderer >> inspectorRenderer: aBuilder [

	<inspectorPresentationOrder: 10 title: 'Renderer'>
	"An extension of this project, because the tab has to serve every renderer and ours are
	 siblings under this class. What Bloc holds for a frame: the canvas it draws through, the
	 text measurer layout reads, and the class the image would pick for the next space it opens,
	 which is asked of Bloc rather than assumed. Each renderer reports its own. The scale factor
	 is read from the slot because `BlHostRenderer` declares it without an accessor."

	^ aBuilder newTable
		  items: {
				  ('Label' -> self class label).
				  ('Canvas' -> self canvas class).
				  ('Canvas is valid' -> self isValid).
				  ('Text measurer canvas' -> (self textMeasurer
					    ifNil: [ nil ]
					    ifNotNil: [ :measurer | measurer canvas class ])).
				  ('Scale factor' -> scaleFactor).
				  ('Bloc would pick' -> BlHostRenderer preferableClass) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : '*VectorGraphics-Bloc' }
BARenderer >> inspectorRendererContext: aContext [
	"An extension of this project, with its tab. A renderer holds nothing until a host space has
	 initialised it."

	aContext active: aeCanvas notNil
]
