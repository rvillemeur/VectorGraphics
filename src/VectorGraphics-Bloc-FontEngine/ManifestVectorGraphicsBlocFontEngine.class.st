"
One send that poses this project's fonts in the image, and one that gives the image back.

`VGFontEngine install` registers our font manager where Alexandrie reads its global one, names
`VGAeRenderer` as Bloc's host renderer, and resets the offscreen canvas that measures text, so
that an image which drew text through FreeType draws it through this project when the send
returns. `VGFontEngine uninstall` puts back what was there. The package carries a
`postLoadDoIt:` sending `install`, which is why loading the `fonts` group of the baseline leaves
nothing to evaluate.

Everything the route is made of lives in `VectorGraphics-Bloc-Text`; this package holds the
switch alone, so an image can load the route without turning it on.

Two ways in:

- `VGFontEngine class >> install` and `uninstall`, which is the whole public face of the package.
- The three extension methods beside them — on `AeFontManager`, `BARenderer` and `VGFontManager`
  — which are what the install sends and where the state it changes lives.

Tags:

- `Manifest` — this comment, the entry point the architecture tools read, and the Renraku rule
  configuration.

`README.md` lists the baseline groups and `doc/USAGE.md` says which group each level of use needs.


"
Class {
	#name : 'ManifestVectorGraphicsBlocFontEngine',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Bloc-FontEngine-Manifest',
	#package : 'VectorGraphics-Bloc-FontEngine',
	#tag : 'Manifest'
}

{ #category : 'architecture' }
ManifestVectorGraphicsBlocFontEngine class >> archDocEntryPoints [
	"Where a reader of this package starts. It holds one class, and that class is the switch: a
	 package of one class still says so, because a reader of the project asks the same question
	 of every package and an empty answer reads as an oversight."

	^ #( #VGFontEngine )
]
