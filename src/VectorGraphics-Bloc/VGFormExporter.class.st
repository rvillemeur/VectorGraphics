"
I export a Bloc element as a Pharo `Form` through this project's canvas. The exporter
hierarchy of `Bloc-Alexandrie` is backend independent but for one method, `newCanvas:`, which names
`AeCanvas`; that method is my only override.
"
Class {
	#name : 'VGFormExporter',
	#superclass : 'BAFormExporter',
	#category : 'VectorGraphics-Bloc-Exporters',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Exporters'
}

{ #category : 'inspector' }
VGFormExporter >> inspectorExport: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Export'>
	"What this exporter will draw with, asked of the exporter rather than stated here: the canvas
	 its own `newCanvas:` builds for a one point square, so a lost override shows as Alexandrie's
	 class in the row."

	^ aBuilder newTable
		  items: {
				  ('element' -> self element printString).
				  ('scale' -> self scale printString).
				  ('background' -> self background printString).
				  ('canvas class' -> (self newCanvas: 1 @ 1) class name) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value ]);
		  yourself
]

{ #category : 'inspector' }
VGFormExporter >> inspectorExportContext: aContext [
	"The rows ask the exporter for the element it holds, so the tab waits until one is set."

	aContext active: self element notNil
]

{ #category : 'private' }
VGFormExporter >> newCanvas: anExtent [

	^ VGCanvas extent: anExtent
]
