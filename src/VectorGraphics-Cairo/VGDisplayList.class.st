"
I am the retained display list of one frame: the entries a context recorded, in the order it recorded them.

Rule one of the plan says a context never rasterises as it records, and I am where it records
instead. The software backend wants me so that the dirty rectangle is known before the first pixel
is written; the Vulkan backend wants me because one draw call per figure is what makes a GPU slower
than a processor. I am also what makes failover cheap, since the same frame can be replayed on
another backend after one raises.

replayOn: hands my entries to a backend in order, and reset empties me once a frame is drained.
"
Class {
	#name : 'VGDisplayList',
	#superclass : 'Object',
	#instVars : [
		'entries'
	],
	#category : 'VectorGraphics-Cairo-Display list',
	#package : 'VectorGraphics-Cairo',
	#tag : 'Display list'
}

{ #category : 'recording' }
VGDisplayList >> add: anEntry [
	entries add: anEntry.
	^ anEntry
]

{ #category : 'draining' }
VGDisplayList >> boundingBox [
	"The dirty rectangle of the frame: the union of what the entries touch, or nil when nothing was
	 recorded. The software backend reads it so that it visits no row the frame cannot reach."
	^ entries inject: nil into: [ :union :each |
		  | box |
		  box := each boundingBox.
		  box isNil
			  ifTrue: [ union ]
			  ifFalse: [ union isNil ifTrue: [ box ] ifFalse: [ union merge: box ] ] ]
]

{ #category : 'accessing' }
VGDisplayList >> entries [
	^ entries asArray
]

{ #category : 'initialization' }
VGDisplayList >> initialize [
	super initialize.
	entries := OrderedCollection new
]

{ #category : 'inspector' }
VGDisplayList >> inspectorEntries: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Entries'>
	"The frame in recording order, which is the order a replay sends the backend messages in."

	^ aBuilder newTable
		  items: (1 to: entries size) asArray;
		  addColumn: (SpStringTableColumn
				   title: 'Order'
				   evaluated: [ :index | index printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Entry'
				   evaluated: [ :index | (entries at: index) class name ]);
		  addColumn: (SpStringTableColumn
				   title: 'Bounding box'
				   evaluated: [ :index | (entries at: index) boundingBox printString ]);
		  addColumn: (SpStringTableColumn
				   title: 'Description'
				   evaluated: [ :index | (entries at: index) printString ]);
		  yourself
]

{ #category : 'inspector' }
VGDisplayList >> inspectorEntriesContext: aContext [
	aContext active: entries notNil
]

{ #category : 'accessing' }
VGDisplayList >> isEmpty [
	^ entries isEmpty
]

{ #category : 'accessing' }
VGDisplayList >> notEmpty [
	^ entries notEmpty
]

{ #category : 'printing' }
VGDisplayList >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: entries size;
		nextPutAll: ' entries)' 
]

{ #category : 'draining' }
VGDisplayList >> replayOn: aBackend [
	entries do: [ :each | each replayOn: aBackend ]
]

{ #category : 'recording' }
VGDisplayList >> reset [
	entries := OrderedCollection new
]

{ #category : 'accessing' }
VGDisplayList >> size [
	^ entries size
]
