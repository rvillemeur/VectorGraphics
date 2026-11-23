"
I am what the device half of a benchmarked frame answered: which device drew it, the picture that came back, whether those pixels are the ones the software path draws, and — when no device drew at all — the reason the machine gave.

A machine with no driver, no device, or a device that refuses the features this project asks for is not a failure of a benchmark: it is an outcome, and `isAvailable` is false with `unavailableReason` saying why. `compareWith:` takes the software picture, answers nothing of it, and keeps only the verdict, because what the comparison is read for is whether the device drew the frame and not what software drew. `rows` is the pair of lines a report prints for the device half.
"
Class {
	#name : 'VGDeviceOutcome',
	#superclass : 'Object',
	#instVars : [
		'deviceName',
		'form',
		'pixelsEqual',
		'unavailableReason'
	],
	#category : 'VectorGraphics-Benchmarks-Frames',
	#package : 'VectorGraphics-Benchmarks',
	#tag : 'Frames'
}

{ #category : 'comparing' }
VGDeviceOutcome >> compareWith: aForm [
	"The software picture of the same frame. Only the verdict is kept: what the comparison is
	 read for is whether the device drew the frame, not what software drew. A machine where no
	 device drew has nothing to compare and keeps no verdict."

	form ifNotNil: [ pixelsEqual := form bits = aForm bits ].
	^ self
]

{ #category : 'accessing' }
VGDeviceOutcome >> deviceName [
	^ deviceName
]

{ #category : 'accessing' }
VGDeviceOutcome >> deviceName: aString [
	deviceName := aString
]

{ #category : 'accessing' }
VGDeviceOutcome >> form [
	^ form
]

{ #category : 'accessing' }
VGDeviceOutcome >> form: aForm [
	form := aForm
]

{ #category : 'inspector' }
VGDeviceOutcome >> inspectorDevice: aBuilder [
	<inspectorPresentationOrder: 10 title: 'Device'>
	"The lines a report prints for the device half, built from rows rather than from the fields
	 beside them, so a reader of this tab sees what a reader of the report sees."

	^ aBuilder newTable
		  addColumn: (SpStringTableColumn
				   title: 'Fact'
				   evaluated: [ :each | each key ]);
		  addColumn: (SpStringTableColumn
				   title: 'Value'
				   evaluated: [ :each | each value ]);
		  items: self rows;
		  yourself
]

{ #category : 'inspector' }
VGDeviceOutcome >> inspectorDeviceFrame: aBuilder [
	<inspectorPresentationOrder: 20 title: 'Device frame'>
	"The picture the device drew, so that a frame measured fast and drawn wrong is visible as
	 such and not only read as a false in the rows of a report."

	^ aBuilder newImage image: form
]

{ #category : 'inspector' }
VGDeviceOutcome >> inspectorDeviceFrameContext: aContext [
	"An outcome where no device drew has no picture."

	aContext active: form isNotNil
]

{ #category : 'testing' }
VGDeviceOutcome >> isAvailable [
	"Whether this machine could be measured on a device at all. A device that is missing, or a
	 driver that faults, records why instead."

	^ unavailableReason isNil
]

{ #category : 'accessing' }
VGDeviceOutcome >> pixelsEqual [
	"Whether the picture the device drew is the one software draws, or nil when the two were
	 never compared."

	^ pixelsEqual
]

{ #category : 'reporting' }
VGDeviceOutcome >> rows [
	"Which device drew the frame, or why none did, and whether what came back is the picture the
	 software path draws."

	| rows |
	rows := OrderedCollection new.
	self isAvailable
		ifTrue: [ deviceName ifNotNil: [ rows add: 'device' -> deviceName ] ]
		ifFalse: [
			rows add: 'device' -> 'none'.
			rows add: 'reason' -> unavailableReason ].
	pixelsEqual ifNotNil: [ rows add: 'same pixels' -> pixelsEqual printString ].
	^ rows asArray
]

{ #category : 'accessing' }
VGDeviceOutcome >> unavailableReason [
	^ unavailableReason
]

{ #category : 'accessing' }
VGDeviceOutcome >> unavailableReason: aString [
	unavailableReason := aString
]
