"
I test the one piece of class-side state this project owns: whether the font manager of this project is the one Bloc asks for its faces.

Installing is a global act. `AeFontManager class` keeps its manager in a class slot, and every consumer of a face reaches it through `AeFontManager globalInstance`, so a test that installs changes what the whole image draws with. I remember both slots in `setUp` — upstream's and ours — and write them back in `tearDown`, whatever the test did in between. That is why these tests live in a class of their own rather than in `VGFontManagerTest`, whose tests own nothing outside the manager they build.

Unit 3.5 of the font plan. The mechanism I test is temporary: 5.1 turns the installation on for the whole image, and 5.2 deletes it along with me.
"
Class {
	#name : 'VGFontManagerInstallationTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousGlobalInstance',
		'previousInstalledInstance'
	],
	#category : 'VectorGraphics-Bloc-Tests',
	#package : 'VectorGraphics-Bloc-Tests'
}

{ #category : 'running' }
VGFontManagerInstallationTest >> setUp [
	"Remember both slots before a test writes either of them. Upstream's is read by reflection
	 on purpose: sending globalInstance would build a whole AeFontManager, FreeType and all,
	 just to tell me what was there."

	super setUp.
	previousGlobalInstance := (AeFontManager class slotNamed: #globalInstance)
		                          read: AeFontManager.
	previousInstalledInstance := VGFontManager installedInstance
]

{ #category : 'running' }
VGFontManagerInstallationTest >> tearDown [
	"Put the image back the way I found it, whichever way the test went. Both slots are written
	 directly, since uninstallGlobally would leave upstream's at nil and this image had a
	 manager there before I ran."

	(VGFontManager class slotNamed: #installedInstance)
		write: previousInstalledInstance
		to: VGFontManager.
	(AeFontManager class slotNamed: #globalInstance)
		write: previousGlobalInstance
		to: AeFontManager.
	super tearDown
]

{ #category : 'tests' }
VGFontManagerInstallationTest >> testAnImageThatInstalledNothingLeavesUpstreamsOwnManagerAlone [
	"My startUp: runs in every image where this package is loaded, installed or not, because a
	 session handler is registered once and cannot ask first. So it has to leave the slot alone
	 when I posed nothing in it: an image that draws with Alexandrie's manager keeps the
	 manager it built, and does not have it replaced by nil behind its back."

	| theirs |
	VGFontManager uninstallGlobally.
	theirs := AeFontManager globalInstance.
	VGFontManager startUp: true.
	self assert: AeFontManager globalInstance identicalTo: theirs.
	self assert: VGFontManager installedInstance isNil
]

{ #category : 'tests' }
VGFontManagerInstallationTest >> testOurManagerSurvivesTheResetUpstreamPerformsAtEveryImageStart [
	"Upstream nils its global manager on every image start, at GUI priority 110, because the
	 faces it holds are handles into a FreeType library that the dead session owned. An
	 installation of ours has to be put back after that, or it would last exactly until the
	 next start of the image. So I register above 110 and write the manager back."

	VGFontManager installGlobally.
	AeFontManager startUp: true.
	VGFontManager startUp: true.
	self assert: AeFontManager globalInstance identicalTo: VGFontManager installedInstance.
	self assert: AeFontManager globalInstance class equals: VGFontManager
]

{ #category : 'tests' }
VGFontManagerInstallationTest >> testTheInstallationViewNamesWhatIsPosedAndAsksUpstreamForNothing [
	"The view a reader opens on the class itself, where the installation lives. It says what
	 this project posed, nothing about what upstream holds: asking AeFontManager globalInstance
	 would build a whole FreeType manager at the moment an inspector opens. What the posed
	 manager knows is its own State view's business, not this one's."

	| rowsBefore rowsAfter builder |
	builder := [ SpPresenterBuilder newApplication: SpApplication new ].
	VGFontManager uninstallGlobally.
	rowsBefore := (VGFontManager inspectorInstallation: builder value) items.
	self
		assert:
		(rowsBefore detect: [ :each | each key = 'Installed manager' ]) value
		equals: nil.
	VGFontManager installGlobally.
	rowsAfter := (VGFontManager inspectorInstallation: builder value) items.
	self
		assert:
		(rowsAfter detect: [ :each | each key = 'Installed manager' ]) value
		identicalTo: VGFontManager installedInstance.
	self assert:
		((AeFontManager class slotNamed: #globalInstance) read: AeFontManager)
			identicalTo: VGFontManager installedInstance
]
