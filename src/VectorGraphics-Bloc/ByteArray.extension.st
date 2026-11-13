Extension { #name : 'ByteArray' }

{ #category : '*VectorGraphics-Bloc' }
ByteArray >> newHbBlob [
	"A HarfBuzz blob over myself: a font held in memory is already its own bytes. An extension
	 of this project, the companion of fontBytes, so that no catalogue entry asks what kind of
	 source it holds.

	 I pin myself first. hb_blob_create is called in HB_MEMORY_MODE_READONLY with no destroy
	 callback, so HarfBuzz keeps the raw address of my first byte and reads through it long
	 after the call returns. An unpinned ByteArray can be moved by the garbage collector, and
	 the blob would then read whatever took my place. pinInMemory answers whether I was already
	 pinned, not myself, so the blob is built on me."

	self pinInMemory.
	^ AeHbBlob newFrom: self
]
