"
I export a Bloc element as a PNG file through this project's canvas and this
project's PNG writer. As with `VGFormExporter`, `newCanvas:` is the only method of the exporter
hierarchy that names a backend class, so it is my only override.
"
Class {
	#name : 'VGPngExporter',
	#superclass : 'BAPngExporter',
	#category : 'VectorGraphics-Bloc-Exporters',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Exporters'
}

{ #category : 'inspector' }
VGPngExporter >> inspectorExport: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Export'>
	"What this exporter will write with, asked of the exporter rather than stated here: the canvas
	 its own `newCanvas:` builds for a one point square, so a lost override shows as Alexandrie's
	 class in the row."

	^ aBuilder newTable
		  items: {
				  ('element' -> self element printString).
				  ('target' -> self target printString).
				  ('scale' -> self scale printString).
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
VGPngExporter >> inspectorExportContext: aContext [
	"The rows ask the exporter for the element it holds, so the tab waits until one is set."

	aContext active: self element notNil
]

{ #category : 'private' }
VGPngExporter >> newCanvas: anExtent [

	^ VGCanvas extent: anExtent
]
