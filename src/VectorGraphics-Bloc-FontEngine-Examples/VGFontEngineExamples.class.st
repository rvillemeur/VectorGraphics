"
I hold the runnable example of `VGFontEngine`: a window of this machine, drawn after one send of `install`, showing the family that installation posed as the image's default.

`VGAeRendererExamples` has a window of the same route, and the two say different things. That one poses the route by hand and names a family it scanned a directory for, which is how the route was proved in unit 5.3 of the font plan. Mine sends `install` and names no family at all: what a reader sees is what the `fonts` group leaves an image with, default family included, which is the claim the group makes.

The window outlives the method, so the image is given back in a handler on `BlSpaceClosedEvent` rather than in an `ensure:` — a frame resolves its faces through `AeFontManager globalInstance` again on every repaint.
"
Class {
	#name : 'VGFontEngineExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Bloc-FontEngine-Examples-Examples',
	#package : 'VectorGraphics-Bloc-FontEngine-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGFontEngineExamples class >> openWindowWithTextDrawnByTheInstalledEngine [
	"One send of install, then a window: this is what an image has after the fonts group is
	 loaded. No family is named and no directory is scanned, so the glyphs a reader reads come
	 from the default family the installation posed — the claim the group makes.
	 The window outlives this method, so the image is given back when it closes rather than in
	 an ensure:; a frame resolves its faces through AeFontManager globalInstance again on every
	 repaint."

	<sampleInstance>
	| space |
	VGFontEngine install.
	space := BlSpace new.
	space extent: 360 @ 160.
	space title: 'Text drawn by the installed font engine'.
	space root addChild: self textSceneInTheDefaultFamily.
	space
		addEventHandlerOn: BlSpaceClosedEvent
		doOnce: [ :event | VGFontEngine uninstall ].
	space show.
	^ space
]

{ #category : 'examples' }
VGFontEngineExamples class >> textSceneInTheDefaultFamily [
	"The scene the window shows: two sizes of one line, in whichever family the installation
	 posed as the image's default. The family is read from FontFamily rather than written
	 here, because which one the catalogue found is the machine's business and the name of it
	 is what a reader wants to see."

	<sampleInstance>
	| scene familyName |
	familyName := FontFamily defaultFamilyName.
	scene := BlElement new
		         extent: 360 @ 160;
		         background: (Color gray: 0.95);
		         yourself.
	#( 12 30 ) doWithIndex: [ :size :index |
		| text |
		text := ('Installed: ' , familyName) asRopedText.
		text
			fontName: familyName;
			fontSize: size.
		scene addChild: (BlTextElement new
				 text: text;
				 position: 20 @ (20 + (index - 1 * 60));
				 yourself) ].
	^ scene
]
