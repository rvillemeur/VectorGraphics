"
Signalled by PathCommand class >> from:commandChar stream: when the command character does
not match any known PathCommand subclass (i.e. classFor: returns nil).

The error message contains the offending character.
"
Class {
	#name : 'PathCommandError',
	#superclass : 'Error',
	#category : 'VectorGraphics-PathCommands',
	#package : 'VectorGraphics',
	#tag : 'PathCommands'
}
