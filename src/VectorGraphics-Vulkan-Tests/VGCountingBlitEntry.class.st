"
I am a blit entry that counts the conversions to the fill the tiled rasteriser draws in my place, so a test can hold that an entry drawn twice in one frame is converted once. I count in `newTiledFill`, which is the work the memo in `VGBlitEntry >> asTiledFill` is there to spare.
"
Class {
	#name : 'VGCountingBlitEntry',
	#superclass : 'VGBlitEntry',
	#instVars : [
		'conversions'
	],
	#category : 'VectorGraphics-Vulkan-Tests-Fixtures',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Fixtures'
}

{ #category : 'counting' }
VGCountingBlitEntry >> conversionCount [
	"How many times I was asked to build the fill the tiled rasteriser draws in my place."

	^ conversions ifNil: [ 0 ]
]

{ #category : 'counting' }
VGCountingBlitEntry >> newTiledFill [
	"The conversion my superclass builds, counted. A frame that asks twice and builds once is
	 what the memo on the entry is for, and this counter is how a test can see it."

	conversions := self conversionCount + 1.
	^ super newTiledFill
]
