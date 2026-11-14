Extension { #name : 'BAOffscreen' }

{ #category : '*VectorGraphics-Bloc' }
BAOffscreen >> inspectorMeasuring: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Measuring'>
	"An extension of this project, because the tab has to serve every offscreen and the three of
	 them are siblings under Alexandrie's. Text is measured before anything is drawn, and through
	 a canvas of one pixel that exists only to answer scaled fonts. The canvas and the measurer
	 are asked of the object, so each route reports its own."

	^ aBuilder newTable
		  items: {
				  ('Canvas' -> aeCanvas class).
				  ('Canvas is valid' -> (aeCanvas notNil and: [ aeCanvas isValid ])).
				  ('Text measurer' -> textMeasurer class).
				  ('Measurer canvas' -> (textMeasurer
					    ifNil: [ nil ]
					    ifNotNil: [ :measurer | measurer canvas class ])) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : '*VectorGraphics-Bloc' }
BAOffscreen >> inspectorMeasuringContext: aContext [
	"An extension of this project, with its tab. An offscreen built but never made ready holds
	 neither canvas nor measurer."

	aContext active: aeCanvas notNil
]
