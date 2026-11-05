"
Test double for a cached font held in a FontFamily, counting the releaseCachedState messages it receives.

FontFamily >> releaseCachedState forwards to every font in baseFontBySizes, and a real TrueTypeFont would need a parsed font file to be built. This double answers the one message the family sends and records it, so FontFamilyTest can state that the forwarding happens without reading a font from disk.

## Key methods

- `releaseCount` — how many times the family released this font
- `wasReleased` — whether it received the message at all
"
Class {
	#name : 'RecordingFont',
	#superclass : 'Object',
	#instVars : [
		'releaseCount'
	],
	#category : 'VectorGraphics-TrueType-Tests-Fixtures',
	#package : 'VectorGraphics-TrueType-Tests',
	#tag : 'Fixtures'
}

{ #category : 'initialization' }
RecordingFont >> initialize [
	super initialize.
	releaseCount := 0
]

{ #category : 'releasing' }
RecordingFont >> releaseCachedState [
	"The one message FontFamily >> releaseCachedState sends to each font it holds."

	releaseCount := releaseCount + 1
]

{ #category : 'accessing' }
RecordingFont >> releaseCount [
	^ releaseCount
]

{ #category : 'testing' }
RecordingFont >> wasReleased [
	^ releaseCount > 0
]
