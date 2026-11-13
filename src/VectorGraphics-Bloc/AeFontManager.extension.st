Extension { #name : 'AeFontManager' }

{ #category : '*VectorGraphics-Bloc' }
AeFontManager class >> globalInstance: aManager [
	"Pose the manager every consumer of a face reaches, or nil to let the lazy getter build one
	 again. An extension of this project: Alexandrie keeps this slot for its own manager and
	 offers no setter, and VectorGraphics-Bloc installs a manager that reads fonts in Pharo
	 instead of through FreeType (unit 3.5 of the font plan, removed again at 5.2)."

	globalInstance := aManager
]
