"
I am raised when a `CFF ` table says something a reader cannot act on: a byte that is no operand, an operator a dictionary was asked for and does not hold, a charstring operator the Type 2 interpreter does not know, or a font keyed by CID, which this reader does not draw.

My message names what was read and where, because a font that reaches a reader has already passed every other check: the defect is in the bytes or in the reader, and both are found by the place that raised me.

A face reads its glyphs one at a time, so a glyph that raises me leaves the rest of the face usable. Whoever drew the text decides whether to carry on without that glyph.
"
Class {
	#name : 'TTCffError',
	#superclass : 'Error',
	#category : 'VectorGraphics-TrueType-CFF',
	#package : 'VectorGraphics-TrueType',
	#tag : 'CFF'
}
