"
I answer, on my class side, which fonts the machine running the suite has installed, for the gates that read a real file rather than bytes of our own.

One question matters today: which installed font carries its outlines as Type 2 charstrings in a `CFF ` table. The extension is not the answer — a `.otf` file can hold `CFF2` instead, a format this reader does not read, and `Cantarell-VF.otf` is such a font on the machine this was written on. A machine with no readable OpenType font makes a gate skip, and `noCffFontInstalledReason` is the one sentence every such skip prints: it names the fixture to carry in the repository so the gates re-arm by themselves the day it lands.

I hold no state and nobody instantiates me. The scan itself lives in `TrueTypeExamples class`, because the examples ask the same question and an example package may not name a test one.
"
Class {
	#name : 'TTInstalledFonts',
	#superclass : 'Object',
	#category : 'VectorGraphics-TrueType-Tests-Fixtures',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Fixtures'
}

{ #category : 'accessing' }
TTInstalledFonts class >> noCffFontInstalledReason [
	"Why a gate on a real OpenType font skips, said once for every gate that skips. It names what
	 to carry rather than what is absent, because the gate re-arms by itself once the file is in
	 the repository."

	^ 'no installed font holds a CFF table; carry one in the repository to run this'
]

{ #category : 'accessing' }
TTInstalledFonts class >> openTypeFontFile [
	"The first installed font whose outlines this reader can read — a CFF table of Type 2
	 charstrings — or nil when this machine has none."

	^ TrueTypeExamples openTypeFontPath ifNotNil: [ :path | path asFileReference ]
]
