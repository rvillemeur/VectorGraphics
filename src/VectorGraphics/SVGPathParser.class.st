"
Parses an SVG path string into an OrderedCollection of PathCommand objects.

Scans the string character by character. When a letter is encountered it flushes the
accumulated number text for the previous command (creating a PathCommand via the standard
factory), then starts collecting for the new command. Numbers are split on spaces and commas.

## Usage
  cmds := SVGPathParser parse: 'M 10 20 L 30 40 Z'.
  canvas strokeWidth: 2.0 color: Color black do: [ canvas runPathCommands: cmds ].

## Limitations
  - Adjacent negative numbers without whitespace (e.g. '10-20') are not handled; use
    explicit spaces or commas as separators.
  - Scientific notation (e.g. '1e2') is not handled.

## Relationship
  - Creates SVGNumberStream per command token to feed PathCommand >> buildFrom:commandChar stream:.
  - VectorCanvasExample exampleSvg* methods use this class to render real SVG path strings.
"
Class {
	#name : 'SVGPathParser',
	#superclass : 'Object',
	#category : 'VectorGraphics-SVG',
	#package : 'VectorGraphics',
	#tag : 'SVG'
}

{ #category : 'parsing' }
SVGPathParser class >> parse: aString [

	| commands currentCmd numStr |
	commands := OrderedCollection new.
	currentCmd := nil.
	numStr := ''.
	aString do: [ :c |
			c isLetter
				ifTrue: [
						currentCmd ifNotNil: [
								commands add: (PathCommand
										 from: currentCmd
										 stream: (SVGNumberStream on: (self parseNumbers: numStr))) ].
						currentCmd := c.
						numStr := '' ]
				ifFalse: [ numStr := numStr , (String with: c) ] ].
	currentCmd ifNotNil: [
			commands add: (PathCommand
					 from: currentCmd
					 stream: (SVGNumberStream on: (self parseNumbers: numStr))) ].
	^ commands
]

{ #category : 'parsing' }
SVGPathParser class >> parseNumbers: aString [

	^ (aString substrings: ' ,') collect: [ :t | t asNumber ]
]
