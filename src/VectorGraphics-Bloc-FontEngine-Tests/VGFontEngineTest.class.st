"
I test the one act `VGFontEngine` performs: posing the route where Cairo rasterises every figure and this project supplies the glyphs, and giving the image back what it held.

Everything the subject writes is global — `AeFontManager`'s class slot, `VGFontManager`'s own, Bloc's `BlHostRenderer class >> preferableClass`, and the three class variables of `FontFamily` an installation registers families in. So `setUp` remembers all of them and `tearDown` writes them back whichever way the test went, as `VGFontManagerInstallationTest` does for the two slots it owns. A test that forgot one would leave the image drawing with a manager of a dead test.

The faces are read from this machine, so a machine holding none of `VGFontManager class >> preferredTextFamilyNames` makes these tests fail where `installGlobally` refuses — which is the behaviour the group's load has as well, by the decision taken at the interview.
"
Class {
	#name : 'VGFontEngineTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousRenderer',
		'previousGlobalInstance',
		'previousInstalledInstance',
		'previousFontFamilyState'
	],
	#category : 'VectorGraphics-Bloc-FontEngine-Tests',
	#package : 'VectorGraphics-Bloc-FontEngine-Tests'
}

{ #category : 'accessing' }
VGFontEngineTest >> defaultTimeLimit [
	"Every test here poses the route, and posing it reads the fonts of this machine off the
	 disk: VGFontManager class >> installGlobally builds a manager with scanDefaultDirectories
	 every time, which is seconds rather than the ten SUnit allows a test. Without this a run
	 reports a timeout where it should report which half of the route is wrong."

	^ 2 minutes
]

{ #category : 'running' }
VGFontEngineTest >> setUp [
	"Remember every piece of global state an installation writes, before a test writes any of
	 it: Bloc's renderer choice, upstream's manager slot, ours, and the three class variables
	 of FontFamily. The dictionary of families is copied, since an installation registers into
	 the very object tearDown puts back."

	super setUp.
	previousRenderer := BlHostRenderer preferableClass.
	previousGlobalInstance := VGFontManager managerUpstreamHolds.
	previousInstalledInstance := VGFontManager installedInstance.
	previousFontFamilyState := #( AvailableFamilies DefaultFamilyName
	                              DefaultPointSize ) collect: [ :name |
		                          (FontFamily classPool at: name) copy ]
]

{ #category : 'running' }
VGFontEngineTest >> tearDown [
	"Put the image back the way I found it, whichever way the test went. Upstream's slot is
	 written through the project's own writer, since uninstallGlobally would leave it nil and
	 this image had a manager there before I ran; ours is written directly, having no writer of
	 its own. Both offscreens are reset because each caches an AeCanvas whose faces were
	 resolved through whichever manager was posed when it was built."

	BlHostRenderer preferableClass: previousRenderer.
	(VGFontManager class slotNamed: #installedInstance)
		write: previousInstalledInstance
		to: VGFontManager.
	VGFontManager restoreUpstreamManager: previousGlobalInstance.
	#( AvailableFamilies DefaultFamilyName DefaultPointSize )
		with: previousFontFamilyState
		do: [ :name :value | FontFamily classPool at: name put: value ].
	VGAeOffscreen resetInstance.
	BAOffscreen resetInstance.
	super tearDown
]

{ #category : 'tests' }
VGFontEngineTest >> testASecondInstallationLeavesTheMemoryOfTheFirstAlone [
	"Posing twice is a mistake a loader can make — two groups naming the package, a user
	 sending install after the load. The second send must not remember the route the first
	 posed, or the retreat would hand the image our own renderer back."

	| rendererBefore |
	rendererBefore := BlHostRenderer preferableClass.

	VGFontEngine install.
	VGFontEngine install.
	VGFontEngine uninstall.

	self assert: BlHostRenderer preferableClass identicalTo: rendererBefore
]

{ #category : 'tests' }
VGFontEngineTest >> testInstallingPosesTheCairoRouteWithOurFonts [
	"The whole point of the class: one send and Bloc draws through Cairo with glyphs of ours.
	 Both halves are stated, because neither alone draws text — a manager of ours under
	 BARenderer dies marshalling a cairo_scaled_font_t, and VGAeRenderer over upstream's
	 manager is the route this project started from."

	VGFontEngine install.

	self assert: BlHostRenderer preferableClass equals: VGAeRenderer.
	self assert: VGFontManager installedInstance notNil.
	self
		assert: VGFontManager managerUpstreamHolds
		identicalTo: VGFontManager installedInstance
]

{ #category : 'tests' }
VGFontEngineTest >> testTheBaselineHookPosesTheRouteItself [
	"What a reader of the fonts group gets: Metacello sends this hook to the baseline once the
	 engine's package is in, and the route is posed with nothing left to evaluate. The hook is
	 run here rather than described, because it reaches the class through the environment —
	 it is compiled into a baseline that must still load where this project is absent — and a
	 wrong name there would be found by no other test."

	VGFontEngine uninstall.
	self deny: VGFontEngine isInstalled.

	BaselineOfVectorGraphics new installTheFontEngine.

	self assert: VGFontEngine isInstalled
]

{ #category : 'tests' }
VGFontEngineTest >> testTheRouteIsReadFromTheImageAndNotFromAFlagOfItsOwn [
	"A reader who poses another renderer after the load has left the route, whatever this
	 class did earlier. The question is answered from Bloc's slot and upstream's, so the
	 answer cannot drift from what the image really draws with."

	VGFontEngine install.
	self assert: VGFontEngine isInstalled.

	BlHostRenderer preferableClass: BARenderer.
	self deny: VGFontEngine isInstalled.

	BlHostRenderer preferableClass: VGAeRenderer.
	VGFontManager uninstallGlobally.
	self deny: VGFontEngine isInstalled
]

{ #category : 'tests' }
VGFontEngineTest >> testTheRouteViewNamesWhatIsPosedAndWhatWasThereBefore [
	"The view a reader opens on this class. It is the one place both halves of the route are
	 read side by side, so it is pinned with its column titles and its rows: the state asked
	 of the image, the two slots posed, and the two remembered."

	| presenter rows rendererBefore |
	rendererBefore := BlHostRenderer preferableClass.
	VGFontEngine install.
	presenter := VGFontEngine inspectorRoute:
		             (SpPresenterBuilder newApplication: SpApplication new).
	rows := presenter items.

	self
		assert: (presenter columns collect: [ :each | each title ]) asArray
		equals: #( 'Property' 'Value' ).
	self
		assert: (rows collect: [ :each | each key ]) asArray
		equals: #( 'Installed' 'Renderer' 'Manager' 'Renderer before'
			   'Manager before' ).
	self assert: rows first value equals: true.
	self assert: rows second value identicalTo: VGAeRenderer.
	self assert: rows third value identicalTo: VGFontManager installedInstance.
	self assert: (rows at: 4) value identicalTo: rendererBefore
]

{ #category : 'tests' }
VGFontEngineTest >> testUninstallingGivesBackTheRendererAndTheManagerThatWereInPlace [
	"The retreat is stated against what the image held, not against a route named in the
	 code: an image already drawing through another renderer must find it again."

	| rendererBefore managerBefore |
	rendererBefore := BlHostRenderer preferableClass.
	managerBefore := VGFontManager managerUpstreamHolds.

	VGFontEngine install.
	VGFontEngine uninstall.

	self assert: BlHostRenderer preferableClass identicalTo: rendererBefore.
	self
		assert: VGFontManager managerUpstreamHolds
		identicalTo: managerBefore.
	self assert: VGFontManager installedInstance isNil.
	self deny: VGFontEngine isInstalled
]

{ #category : 'tests' }
VGFontEngineTest >> testUninstallingWhatWasNeverInstalledChangesNothing [
	"The degenerate state: a reader who sends uninstall in an image that never posed the
	 route. Both slots are nil there, and writing them would pose a renderer of nil."

	| rendererBefore managerBefore |
	rendererBefore := BlHostRenderer preferableClass.
	managerBefore := VGFontManager managerUpstreamHolds.

	VGFontEngine uninstall.

	self assert: BlHostRenderer preferableClass identicalTo: rendererBefore.
	self
		assert: VGFontManager managerUpstreamHolds
		identicalTo: managerBefore
]
