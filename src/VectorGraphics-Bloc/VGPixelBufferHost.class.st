"
I am a host with no window whose space draws, so a Bloc space can be opened, drawn and sent
events with no window system present at all.
`BlHeadlessHost` builds a host space that counts the frames it is asked for and draws none,
so it says nothing about a renderer. Mine lends a byte array of pixels instead of the texture
of a window, which is the only difference from the host space of a real window, and the
pixels can then be read, saved or compared.
The renderer is the one the image has chosen, so what draws here is what would draw in a
window: send `BlHostRenderer preferableClass: VGRenderer` to choose this project.

"
Class {
	#name : 'VGPixelBufferHost',
	#superclass : 'BlHeadlessHost',
	#category : 'VectorGraphics-Bloc-Hosts',
	#package : 'VectorGraphics-Bloc',
	#tag : 'Hosts'
}

{ #category : 'inspector' }
VGPixelBufferHost >> inspectorHost: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Host'>
	"What this host would give the next space opened on it. The renderer class is asked of Bloc,
	 because the host builds whichever renderer the image has chosen."

	^ aBuilder newTable
		  items: {
				  ('Label' -> self class label).
				  ('Spaces open' -> self spaces size).
				  ('Pulse loop running' -> self isRunning).
				  ('Renderer it would build' -> BlHostRenderer preferableClass).
				  ('Host space it would build' -> VGPixelBufferHostSpace) };
		  addColumn: (SpStringTableColumn
				   title: 'Property'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGPixelBufferHost >> inspectorHostContext: aContext [
	aContext active: true
]

{ #category : 'host - api' }
VGPixelBufferHost >> newHostSpaceFor: aSpace [
	"The host space the headless host builds, except that mine draws its frames into a buffer of
	 pixels it owns."

	^ VGPixelBufferHostSpace new
		  host: self;
		  space: aSpace;
		  renderer: self newHostRenderer;
		  windowExtent: aSpace extent;
		  canvasExtent: aSpace extent;
		  yourself
]
