"
Test helper: records every message sent to it via doesNotUnderstand:.
Use lastMessage / lastSelector / lastArguments to inspect what runOn: invoked.
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
