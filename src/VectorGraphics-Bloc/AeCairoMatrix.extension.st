Extension { #name : 'AeCairoMatrix' }

{ #category : '*VectorGraphics-Bloc' }
AeCairoMatrix >> asVGCairoMatrix [
	"Me as one of this project's own matrices: Alexandrie's record and ours hold the same six
	 numbers under the same names. An extension in our own package, because Alexandrie's classes
	 are never edited in this project."

	^ VGCairoMatrix new
		  beX: self x
		  y: self y
		  sx: self sx
		  sy: self sy
		  shx: self shx
		  shy: self shy;
		  yourself
]
