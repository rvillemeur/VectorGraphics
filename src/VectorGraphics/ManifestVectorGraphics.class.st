"
The pure-Pharo vector rasteriser this project is built on: anti-aliased strokes and fills, Bézier
curves, arcs and ellipses, SVG path commands, and TrueType glyph rendering. It is a port of the
Cuis Smalltalk VectorEngine and it depends on nothing above it — no Bloc, no Alexandrie, no
device — so it loads on its own.

Three ways in:

- `VectorCanvas class >> onForm:` draws through Pharo's `Canvas` protocol, for Morphic.
- `VectorEngineSubPixel class >> onForm:` draws straight onto a `Form`, with no Morphic at all.
- `FontFamily class >> familyName:pointSize:` answers a `TrueTypeFont`, which is how text is drawn.

Tags:

- `Kernel` — the canvas and the four engine classes, which own the path state and the buffers.
- `PathCommands` — one class per SVG path letter; each runs itself on a canvas.
- `SVG` — the parser that turns a `d` attribute into those commands.
- `TrueType` — reading a `.ttf`, the glyphs and metrics it holds, and the font classes above them.
- `Examples` — the class-side `<sampleInstance>` examples of both halves, one click each.
- `Tests` — the SUnit suites of this package.
- `Manifest` — this comment and the Renraku rule configuration.

`doc/ARCHITECTURE.md` describes what spans these classes: the coordinate spaces, the hop loop and
the buffers it writes, the blend stage, the TrueType chain and its four caches. `README.md` lists
the packages and groups of the whole project, and `doc/USAGE.md` shows the layers above this one.

Original source:
https://github.com/Cuis-Smalltalk/Cuis-Smalltalk-Dev/blob/master/Packages/Features/VectorEnginePlugin.pck.st
"
Class {
	#name : 'ManifestVectorGraphics',
	#superclass : 'PackageManifest',
	#category : 'VectorGraphics-Manifest',
	#package : 'VectorGraphics',
	#tag : 'Manifest'
}
