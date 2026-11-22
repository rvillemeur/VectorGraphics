"
I pose, in one send, the route where Cairo rasterises every figure of a Bloc frame and this project supplies the glyphs — and I give the image back what it held when asked to leave.

Two slots of the image decide that route, and neither alone draws text. `AeFontManager`'s class slot decides which manager every consumer of a face reaches, and `VGFontManager installGlobally` writes a manager of ours there, which reads an sfnt file in Pharo and holds no FreeType library. `BlHostRenderer class >> preferableClass` decides the renderer a space builds its frame through, and `VGAeRenderer` is the one whose canvas answers our scaled fonts: under Alexandrie's own renderer a font of ours dies marshalling a `cairo_scaled_font_t`, the substitution that used to hide that having been withdrawn in unit 4.6 of the font plan. So `install` writes both, and `uninstall` writes both back.

I am what the `fonts` group of `BaselineOfVectorGraphics` loads for: its `postLoadDoIt:` sends `install` once my package is in, so a reader who asks for that group has the route posed by the time Metacello returns, with nothing left to evaluate. A machine holding none of `VGFontManager class >> preferredTextFamilyNames` makes that load fail with `VGFontManagerHasNoUsableFamily` rather than quietly keep FreeType.

`isInstalled` asks the image rather than a flag of mine, so it stays true of what is really posed. Nothing of mine registers for the image start: `preferableClass` is a class-side slot and survives the save, and `VGFontManager class >> startUp:` already puts its manager back after upstream nils its own slot.
"
Class {
	#name : 'VGFontEngine',
	#superclass : 'Object',
	#classInstVars : [
		'previousRenderer',
		'previousManager'
	],
	#category : 'VectorGraphics-Bloc-FontEngine-Installation',
	#package : 'VectorGraphics-Bloc-FontEngine',
	#tag : 'Installation'
}

{ #category : 'inspector' }
VGFontEngine class >> inspectorRoute: aBuilder [
	<inspectorPresentationOrder: 1 title: 'Route'>
	"Both halves of the route in one table, with what each was before it was posed. The state
	 is asked of isInstalled rather than restated here, so the row cannot disagree with the
	 two below it. Nothing of upstream is asked: AeFontManager globalInstance would build a
	 whole FreeType manager at the moment a reader opens an inspector, so the manager posed is
	 read from VGFontManager's own slot, which is where install wrote it."

	^ aBuilder newTable
		  items: {
				  ('Installed' -> self isInstalled).
				  ('Renderer' -> BlHostRenderer preferableClass).
				  ('Manager' -> VGFontManager installedInstance).
				  ('Renderer before' -> previousRenderer).
				  ('Manager before' -> previousManager) };
		  addColumn:
			  (SpStringTableColumn title: 'Property' evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value printString ]);
		  yourself
]

{ #category : 'inspector' }
VGFontEngine class >> inspectorRouteContext: aContext [
	"The view reads previousRenderer and previousManager, which are class-instance variables:
	 a subclass would get its own copies, always nil, and the tab would say nothing true of
	 it. So the tab belongs to the class that installs, and the rule is asked rather than
	 restated — the view is offered where install is defined."

	aContext active: (self includesSelector: #install)
]

{ #category : 'installing' }
VGFontEngine class >> install [
	"Pose the route where Cairo rasterises every figure and this project reads, scales and
	 draws the glyphs: a font manager of ours in the slot every consumer of a face reaches
	 through AeFontManager globalInstance, and VGAeRenderer as the renderer Bloc builds a
	 space's frame through. Neither half draws text alone, which is why one send does both.
	 What was in place is remembered first, so uninstall can give the image back rather than
	 name a route of its own; a second send leaves that memory alone, the state it would
	 remember being the one this class posed.
	 A renderer of mine already posed is remembered as nothing rather than as itself. The
	 question isInstalled asks is an and of both halves, so an image holding my renderer with
	 no manager of mine — what upstream's resetGlobalInstance leaves — reaches this line, and
	 remembering VGAeRenderer there would make uninstall pose the route it is taking away.
	 Nil is the honest memory: upstream picks a renderer from availableClasses when its slot
	 is nil, which is the state an image that never met this project is in.
	 Both offscreens are reset because each caches an AeCanvas whose faces were resolved
	 through whichever manager was posed when it was built."

	self isInstalled ifFalse: [
		previousRenderer := BlHostRenderer preferableClass.
		previousRenderer == VGAeRenderer ifTrue: [ previousRenderer := nil ].
		previousManager := VGFontManager managerUpstreamHolds ].
	VGFontManager installGlobally.
	BlHostRenderer preferableClass: VGAeRenderer.
	VGAeOffscreen resetInstance.
	BAOffscreen resetInstance
]

{ #category : 'testing' }
VGFontEngine class >> isInstalled [
	"Whether the route is posed right now. The question is put to the image rather than to a
	 flag of mine: a flag and the two slots it describes could fall out of step, and a reader
	 who posed a renderer by hand after loading this package deserves the honest answer. The
	 manager is read from the slot every drawing reads, not from the memory of my own
	 installation, because a reset of that slot takes the route away without telling me."

	^ BlHostRenderer preferableClass == VGAeRenderer and: [
		  VGFontManager managerUpstreamHolds isKindOf: VGFontManager ]
]

{ #category : 'installing' }
VGFontEngine class >> uninstall [
	"Give the image back the renderer and the manager that were in place when the route was
	 posed, and forget them. Upstream's slot is written through VGFontManager's own writer
	 rather than nilled, because an image that had already asked for a face held a manager
	 there; ours goes to nil, which uninstallGlobally does on the way.
	 Nothing was posed, nothing is given back: the two slots are then nil, and writing them
	 would hand an image a renderer of nil."

	self isInstalled ifFalse: [ ^ self ].
	VGFontManager uninstallGlobally.
	VGFontManager restoreUpstreamManager: previousManager.
	BlHostRenderer preferableClass: previousRenderer.
	previousRenderer := nil.
	previousManager := nil.
	VGAeOffscreen resetInstance.
	BAOffscreen resetInstance
]
