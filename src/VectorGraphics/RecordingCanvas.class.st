"
Test double that records every message sent to it via doesNotUnderstand:.

Used in PathCommandRunOnTest and PathCommandDispatchTest to verify that PathCommand >> runOn:
sends the correct canvas message with the correct arguments, without requiring a real
VectorCanvas or rendering engine.

Every unknown message is captured as a Message object in the `messages` OrderedCollection.
Assertions inspect the last captured message via `lastSelector` and `lastArguments`.

## Key methods
- `lastSelector`   — the selector of the most recently received message
- `lastArguments`  — the arguments of the most recently received message
- `lastMessage`    — the full Message object
- `messageCount`   — total number of messages recorded
- `messages`       — the full history (OrderedCollection of Message)
"
Class {
	#name : 'RecordingCanvas',
	#superclass : 'Object',
	#instVars : [
		'messages'
	],
	#category : 'VectorGraphics-Tests',
	#package : 'VectorGraphics',
	#tag : 'Tests'
}

{ #category : 'accessing' }
RecordingCanvas >> doesNotUnderstand: aMessage [

	messages add: aMessage
]

{ #category : 'initialize' }
RecordingCanvas >> initialize [

	messages := OrderedCollection new
]

{ #category : 'accessing' }
RecordingCanvas >> lastArguments [

	^ messages last arguments
]

{ #category : 'accessing' }
RecordingCanvas >> lastMessage [

	^ messages last
]

{ #category : 'accessing' }
RecordingCanvas >> lastSelector [

	^ messages last selector
]

{ #category : 'accessing' }
RecordingCanvas >> messageCount [

	^ messages size
]

{ #category : 'accessing' }
RecordingCanvas >> messages [

	^ messages
]
