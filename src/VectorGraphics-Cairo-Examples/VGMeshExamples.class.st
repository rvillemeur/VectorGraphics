"
I hold the one-click examples for the mesh patterns, the paint a mesh builds and the raster behind it.

A mesh pattern is a pattern made of patches. Each patch is a closed path of up to four sides with a colour at each corner, and Cairo runs the colour over the surface the sides bound by interpolating the corners in both of the patch's parameters. Each of my examples rebuilds its object on every call and asserts nothing. Between them they show the four shapes a patch can take: straight sides, three sides with the fourth closed for us, curved sides, and sides that fold the patch over itself.

Unit 1.12 of VECTORCANVAS-PLAN.md builds what I show.
"
Class {
	#name : 'VGMeshExamples',
	#superclass : 'Object',
	#category : 'VectorGraphics-Cairo-Examples-Examples',
	#package : 'VectorGraphics-Cairo-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
VGMeshExamples class >> curvedCoonsPatch [
	<sampleInstance>
	"One patch of a pattern, taken out of the pattern that holds it, with all four sides bowed
	 outwards. A patch is what evaluates the surface, so this is the object to inspect to see
	 where a pair of parameters lands and what colour it carries."

	^ (VGCairoMeshPattern new
		   beginPatch;
		   moveToX: 4 y: 4;
		   curveViaX: 14 y: -6 viaX: 22 y: -6 toX: 32 y: 4;
		   curveViaX: 42 y: 14 viaX: 42 y: 22 toX: 32 y: 32;
		   curveViaX: 22 y: 42 viaX: 14 y: 42 toX: 4 y: 32;
		   curveViaX: -6 y: 22 viaX: -6 y: 14 toX: 4 y: 4;
		   cornerAt: 0 putColorRGB: Color red;
		   cornerAt: 1 putColorRGB: Color green;
		   cornerAt: 2 putColorRGB: Color blue;
		   cornerAt: 3 putColorRGB: Color yellow;
		   endPatch;
		   yourself) patches first
]

{ #category : 'examples' }
VGMeshExamples class >> foldedMeshPaint [
	<sampleInstance>
	"The paint of a patch that folds over itself: its first and third sides are one loop out to the
	 right and back again, and its second and fourth sides are the straight edge on the left, so
	 the point at a parameter and the point at one minus that parameter are the same point. Both
	 halves of the fold reach every pixel, and Cairo draws the lower parameters first, so the pixel
	 keeps the colour of the later half; the corner colours mirror the fold, so the inspector shows
	 which half won."

	^ (VGCairoMeshPattern new
		   beginPatch;
		   moveToX: 0 y: 0;
		   curveViaX: 24 y: 0 viaX: 24 y: 0 toX: 0 y: 0;
		   curveViaX: 0 y: 8 viaX: 0 y: 16 toX: 0 y: 24;
		   curveViaX: 24 y: 24 viaX: 24 y: 24 toX: 0 y: 24;
		   curveViaX: 0 y: 16 viaX: 0 y: 8 toX: 0 y: 0;
		   cornerAt: 0 putColorRGB: Color red;
		   cornerAt: 1 putColorRGB: Color green;
		   cornerAt: 2 putColorRGB: Color green;
		   cornerAt: 3 putColorRGB: Color red;
		   endPatch;
		   yourself) paintForDeviceMatrix: VGCairoMatrix newIdentity
]

{ #category : 'examples' }
VGMeshExamples class >> meshRaster [
	<sampleInstance>
	"The picture a mesh is rasterised into before anything composites it. A mesh has no
	 antialiasing, so this is where to see the hard edge: a pixel a patch reaches carries the
	 colour of the surface near the middle of that pixel, and a pixel it does not reach is
	 untouched."

	^ VGMeshRaster ofPatches: self straightSidedMeshPattern patches
]

{ #category : 'examples' }
VGMeshExamples class >> straightSidedMeshPattern [
	<sampleInstance>
	"A patch whose four sides are lines and whose four corners carry a colour each, which is the
	 whole of a Coons surface when nothing bends it: the colour of a point is the two corner
	 colours of each side interpolated along it, and then those two interpolated across."

	^ VGCairoMeshPattern new
		  beginPatch;
		  moveToX: 0 y: 0;
		  lineToX: 32 y: 0;
		  lineToX: 32 y: 32;
		  lineToX: 0 y: 32;
		  cornerAt: 0 putColorRGB: Color red;
		  cornerAt: 1 putColorRGB: Color green;
		  cornerAt: 2 putColorRGB: Color blue;
		  cornerAt: 3 putColorRGB: Color yellow;
		  endPatch;
		  yourself
]

{ #category : 'examples' }
VGMeshExamples class >> threeSidedMeshPattern [
	<sampleInstance>
	"A patch of three sides, which is Gouraud shading: the fourth side closes the patch by itself
	 and the fourth corner takes the colour of the first, so a triangle needs no fourth colour."

	^ VGCairoMeshPattern new
		  beginPatch;
		  moveToX: 16 y: 0;
		  lineToX: 32 y: 28;
		  lineToX: 0 y: 28;
		  cornerAt: 0 putColorRGB: Color red;
		  cornerAt: 1 putColorRGB: Color green;
		  cornerAt: 2 putColorRGB: Color blue;
		  endPatch;
		  yourself
]
