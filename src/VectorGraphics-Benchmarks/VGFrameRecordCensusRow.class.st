"
One line of a VGFrameRecordCensus: the frame drawn, the surface extent it was drawn on, and the counts read off its display list. Built by name:extent:displayList:, which does the counting, so a census is the rows it holds and nothing more. A fill contributes its edges and its coordinates, a blit its surface and that surface's pixels, and every entry its paint and its clip; distinct means distinct object, since neither VGClip nor VGPaint defines equality and what is asked is how many were built.
"
Class {
	#name : 'VGFrameRecordCensusRow',
	#superclass : 'Object',
	#instVars : [
		'name',
		'extent',
		'fills',
		'blits',
		'segments',
		'coordinates',
		'blitPixels',
		'seen'
	],
	#category : 'VectorGraphics-Benchmarks-Frames',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Frames'
}

{ #category : 'instance creation' }
VGFrameRecordCensusRow class >> name: aSymbol extent: aPoint displayList: aDisplayList [
	"The counts of that display list, under the name of the frame it was recorded from and the
	 extent of the surface it was recorded on."
	^ self new
		  setName: aSymbol extent: aPoint displayList: aDisplayList;
		  yourself
]

{ #category : 'accessing' }
VGFrameRecordCensusRow >> blitPixels [

	^ blitPixels
]

{ #category : 'accessing' }
VGFrameRecordCensusRow >> blits [

	^ blits
]

{ #category : 'accessing' }
VGFrameRecordCensusRow >> coordinates [

	^ coordinates
]

{ #category : 'counting' }
VGFrameRecordCensusRow >> countBlit: aBlitEntry [
	"A blit entry counted: one entry, the mask surface it carries and that surface's pixels.
	 The surfaces are held by identity, so a mask the atlas handed out twice counts once."
	| surfaceExtent |
	blits := blits + 1.
	(seen at: #masks) add: aBlitEntry surface.
	surfaceExtent := aBlitEntry surface extent.
	blitPixels := blitPixels + (surfaceExtent x * surfaceExtent y)
]

{ #category : 'counting' }
VGFrameRecordCensusRow >> countFill: aFillEntry [
	"A fill entry counted: one entry, its edges and its coordinates."
	fills := fills + 1.
	segments := segments + aFillEntry segments size.
	coordinates := coordinates + aFillEntry segments coordinates size
]

{ #category : 'accessing' }
VGFrameRecordCensusRow >> distinctBlitSurfaces [
	"How many of the mask surfaces blitted were different objects. A glyph taken from the atlas
	 is the same surface every time it is drawn."
	^ (seen at: #masks) size
]

{ #category : 'accessing' }
VGFrameRecordCensusRow >> distinctClips [
	"How many clip objects the frame built."
	^ (seen at: #clips) size
]

{ #category : 'accessing' }
VGFrameRecordCensusRow >> distinctPaints [
	"How many paint objects the frame built. One a entry means one was built per record call."
	^ (seen at: #paints) size
]

{ #category : 'accessing' }
VGFrameRecordCensusRow >> entries [
	"How many entries the frame recorded. Every entry is a fill or a blit, so this is their
	 sum and not a count of its own."
	^ fills + blits
]

{ #category : 'accessing' }
VGFrameRecordCensusRow >> extent [

	^ extent
]

{ #category : 'accessing' }
VGFrameRecordCensusRow >> fills [

	^ fills
]

{ #category : 'accessing' }
VGFrameRecordCensusRow >> name [

	^ name
]

{ #category : 'printing' }
VGFrameRecordCensusRow >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		nextPutAll: name;
		space;
		print: extent;
		nextPutAll: ', ';
		print: self entries;
		nextPutAll: ' entries, ';
		print: segments;
		nextPutAll: ' edges, ';
		print: blits;
		nextPutAll: ' blits of ';
		print: self distinctBlitSurfaces;
		nextPutAll: ' masks)'
]

{ #category : 'accessing' }
VGFrameRecordCensusRow >> segments [

	^ segments
]

{ #category : 'private' }
VGFrameRecordCensusRow >> setName: aSymbol extent: aPoint displayList: aDisplayList [
	"The three kinds of thing counted by identity are held in one table rather than in a slot
	 each: what a row keeps while it counts is what it has already seen, and that is one fact."
	name := aSymbol.
	extent := aPoint.
	fills := 0.
	blits := 0.
	segments := 0.
	coordinates := 0.
	blitPixels := 0.
	seen := Dictionary new.
	#( #masks #paints #clips ) do: [ :each |
		seen at: each put: IdentitySet new ].
	aDisplayList entries do: [ :each |
		(seen at: #paints) add: each paint.
		(seen at: #clips) add: each clip.
		each countedBy: self ]
]
