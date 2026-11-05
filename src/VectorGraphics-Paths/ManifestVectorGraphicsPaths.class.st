"
The SVG path language: one command class per path letter, each able to run itself on a canvas,
and the parser that reads a `d` attribute into a sequence of them.

Two ways in:

- `SVGPathParser class >> parse:` answers the commands of a `d` attribute string.
- `PathCommand >> runOn:` sends the command's own drawing calls to a `VectorCanvas`.

Tags:

- `Commands` — one class per path letter, absolute and relative, plus the error they signal.
- `SVG` — the parser and the number stream it reads coordinates with.
- `Manifest` — this comment and the Renraku rule configuration.

The package draws through `VectorGraphics-Engine` and adds nothing to it. Section 11 of
`doc/ARCHITECTURE.md` describes the path data and the smooth-curve state the parser carries;
`VectorGraphics-Paths-Examples` holds a runnable path per shape.
"
Class {
	#name : 'ManifestVectorGraphicsPaths',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Paths-Manifest',
	#package : 'VectorGraphics-Paths',
	#tag : 'Manifest'
}
