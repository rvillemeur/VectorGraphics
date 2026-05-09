"
Does only whole pixel anti aliasing. Appropriate for very high resolution displays.
edgeCounts and alphaMask are single byte per pixel.
"
Class {
	#name : 'VectorEngineWholePixel',
	#superclass : 'VectorEnginePixel',
	#category : 'VectorGraphics-Kernel',
	#package : 'VectorGraphics',
	#tag : 'Kernel'
}

{ #category : 'instance creation' }
VectorEngineWholePixel class >> defaultAntiAliasingWidth [

	^ 1.7
]

{ #category : 'private - blend with mask' }
VectorEngineWholePixel >> blendFillOnly [

	| edgesUpToThisPixel edgesThisPixel pixelIndex morphAtThisPixelId |
	blendTop to: blendBottom do: [ :displayY | 
		edgesUpToThisPixel := 0.
		pixelIndex := displayY * targetWidth + blendLeft.
		blendLeft to: blendRight do: [ :displayX | 
			pixelIndex := pixelIndex + 1.
			edgesThisPixel := edgeCounts at: pixelIndex.
			edgeCounts at: pixelIndex put: 0.
			"Not needed in C or OpenCL, use signed char, i.e. a type where 16rFF means -1 and not 255"
			edgesThisPixel > 127 ifTrue: [ 
				edgesThisPixel := edgesThisPixel - 256 ].
			edgesUpToThisPixel := edgesUpToThisPixel + edgesThisPixel.
			(clippingMorphId = 0 or: [ 
				 morphAtThisPixelId := morphIds at: pixelIndex.
				 morphAtThisPixelId = clippingMorphId or: [ 
					 morphAtThisPixelId = currentMorphId ] ]) ifTrue: [ 
				self
					blendFillOnlyAtX: displayX
					y: displayY
					pixelIndex: pixelIndex
					isInside: edgesUpToThisPixel ~= 0 ].
			alphaMask at: pixelIndex put: 0 ] ]
]

{ #category : 'private - blend with mask' }
VectorEngineWholePixel >> blendFillOnlyAtX: x y: y pixelIndex: pixelIndex isInside: isInside [

	"targetForm only contains opaque colors. Assume its alpha is always one. Don't ask for it. Set it to one when writing. 	Blends fill over background. Despite method selector, there might be a very thin stroke of the same color as the fill. Handle this by adjusting antiAliasAlphas.	For blending, alphas are in [0 .. 1.0] and R, G, B color components are in [0 .. 255]"

	| resultR resultG resultB antiAliasAlpha alpha unAlpha resultAlpha targetWord targetAlpha |
	antiAliasAlpha := alphaMask at: pixelIndex.
	antiAliasAlpha = 16r00 ifTrue: [ "Not in the stroke" 
		isInside ifFalse: [ "Not inside" ^ self ] ]. "Optimization: We are completely transparent at this point. Do nothing."

	"In this method, antiAliasAlphas are not used to blend stroke, but fill. This means that in the inside of the shape, and away from the stroke, they must be 1.0 (not 0.0)."
	antiAliasAlpha := antiAliasAlpha / 127.0.
	isInside ifTrue: [ 
		antiAliasAlpha := 1.0 - antiAliasAlpha.
		morphIds at: pixelIndex put: currentMorphId ].

	alpha := antiAliasAlpha * fillColor alpha.
	unAlpha := 1.0 - alpha.
	targetWord := targetForm bits bytesAt: pixelIndex.
	targetAlpha := (targetWord at: 4) / 255.0.
	resultAlpha := alpha + (unAlpha * targetAlpha).
	targetWord at: 4 put: (resultAlpha * 255) rounded.

	resultR := alpha * fillColor red * 255
	           + (unAlpha * (targetWord at: 3) * targetAlpha).
	resultR := resultR / resultAlpha.
	targetWord at: 3 put: resultR rounded.

	resultG := alpha * fillColor green * 255
	           + (unAlpha * (targetWord at: 2) * targetAlpha).
	resultG := resultG / resultAlpha.
	targetWord at: 2 put: resultG rounded.

	resultB := alpha * fillColor blue * 255
	           + (unAlpha * (targetWord at: 1) * targetAlpha).
	resultB := resultB / resultAlpha.
	targetWord at: 1 put: resultB rounded.

	targetForm bits bytesAt: pixelIndex put: targetWord
]

{ #category : 'private - blend with mask' }
VectorEngineWholePixel >> blendStrokeAndFill [

	| edgesUpToThisPixel edgesThisPixel pixelIndex morphAtThisPixelId |
	blendTop to: blendBottom do: [ :displayY | 
		edgesUpToThisPixel := 0.
		pixelIndex := displayY * targetWidth + blendLeft.
		blendLeft to: blendRight do: [ :displayX | 
			pixelIndex := pixelIndex + 1.
			edgesThisPixel := edgeCounts at: pixelIndex.
			edgeCounts at: pixelIndex put: 0.
			"Not needed in C or OpenCL, use signed char, i.e. a type where 16rFF means -1 and not 255"
			edgesThisPixel > 127 ifTrue: [ 
				edgesThisPixel := edgesThisPixel - 256 ].
			edgesUpToThisPixel := edgesUpToThisPixel + edgesThisPixel.
			(clippingMorphId = 0 or: [ 
				 morphAtThisPixelId := morphIds at: pixelIndex.
				 morphAtThisPixelId = clippingMorphId or: [ 
					 morphAtThisPixelId = currentMorphId ] ]) ifTrue: [ 
				self
					blendStrokeAndFillAtX: displayX
					y: displayY
					pixelIndex: pixelIndex
					isInside: edgesUpToThisPixel ~= 0 ].
			alphaMask at: pixelIndex put: 0 ] ]
]

{ #category : 'private - blend with mask' }
VectorEngineWholePixel >> blendStrokeAndFillAtX: x y: y pixelIndex: pixelIndex isInside: isInside [

	"targetForm only contains opaque colors. Assume its alpha is always one. Don't ask for it. Set it to one when writing. 	Do an appropriate (anti aliased) mix between stoke and fill (or pick just stroke or just fill). Blend this over background. 	For blending, alphas are in [0 .. 1.0] and R, G, B color components are in [0 .. 255]"

	| targetWord resultR resultG resultB antiAliasAlpha alpha unAlpha foreR foreG foreB targetAlpha resultAlpha |
	antiAliasAlpha := alphaMask at: pixelIndex.
	antiAliasAlpha = 16r00 ifTrue: [ isInside ifFalse: [ ^ self ] ]. "Optimization: We are completely transparent at this point. Do nothing."

	antiAliasAlpha := antiAliasAlpha / 127.0.

	isInside
		ifTrue: [ "Do gradient between stroke and fill. Blend the result over background"
			alpha := antiAliasAlpha * strokeColor alpha
			         + (1 - antiAliasAlpha * fillColor alpha).
			foreR := antiAliasAlpha * strokeColor red * 255
			         + (1 - antiAliasAlpha * fillColor red * 255).
			foreG := antiAliasAlpha * strokeColor green * 255
			         + (1 - antiAliasAlpha * fillColor green * 255).
			foreB := antiAliasAlpha * strokeColor blue * 255
			         + (1 - antiAliasAlpha * fillColor blue * 255).
			morphIds at: pixelIndex put: currentMorphId ]
		ifFalse: [ "Blend stroke over background"
			alpha := antiAliasAlpha * strokeColor alpha.
			foreR := strokeColor red * 255.
			foreG := strokeColor green * 255.
			foreB := strokeColor blue * 255.
			antiAliasAlpha > 0.5 ifTrue: [ 
				morphIds at: pixelIndex put: currentMorphId ] ].

	unAlpha := 1.0 - alpha.
	targetWord := targetForm bits bytesAt: pixelIndex.
	targetAlpha := (targetWord at: 4) / 255.0.
	resultAlpha := alpha + (unAlpha * targetAlpha).
	targetWord at: 4 put: (resultAlpha * 255) rounded.

	resultR := alpha * foreR
	           + (unAlpha * (targetWord at: 3) * targetAlpha).
	resultR := resultR / resultAlpha.
	targetWord at: 3 put: resultR rounded.

	resultG := alpha * foreG
	           + (unAlpha * (targetWord at: 2) * targetAlpha).
	resultG := resultG / resultAlpha.
	targetWord at: 2 put: resultG rounded.

	resultB := alpha * foreB
	           + (unAlpha * (targetWord at: 1) * targetAlpha).
	resultB := resultB / resultAlpha.
	targetWord at: 1 put: resultB rounded.

	targetForm bits bytesAt: pixelIndex put: targetWord
]

{ #category : 'private - blend with mask' }
VectorEngineWholePixel >> blendStrokeOnlyAtX: x y: y pixelIndex: pixelIndex [

	"targetForm only contains opaque colors. Assume its alpha is always one. Don't ask for it. Set it to one when writing. 	Blends stroke over background. 	For blending, alphas are in [0 .. 1.0] and R, G, B color components are in [0 .. 255]"

	| targetWord resultR resultG resultB antiAliasAlpha alpha unAlpha resultAlpha targetAlpha |
	antiAliasAlpha := alphaMask at: pixelIndex.
	antiAliasAlpha = 16r00 ifTrue: [ ^ self ]. "Optimization: We are completely transparent at this point. Do nothing."

	antiAliasAlpha := antiAliasAlpha / 127.0.

	alpha := antiAliasAlpha * strokeColor alpha.
	unAlpha := 1.0 - alpha.
	targetWord := targetForm bits bytesAt: pixelIndex.
	targetAlpha := (targetWord at: 4) / 255.0.
	resultAlpha := alpha + (unAlpha * targetAlpha).
	targetWord at: 4 put: (resultAlpha * 255) rounded.

	resultR := alpha * strokeColor red * 255
	           + (unAlpha * (targetWord at: 3) * targetAlpha).
	resultR := resultR / resultAlpha.
	targetWord at: 3 put: resultR rounded.

	resultG := alpha * strokeColor green * 255
	           + (unAlpha * (targetWord at: 2) * targetAlpha).
	resultG := resultG / resultAlpha.
	targetWord at: 2 put: resultG rounded.

	resultAlpha := alpha + (unAlpha * targetAlpha).
	resultB := alpha * strokeColor blue * 255
	           + (unAlpha * (targetWord at: 1) * targetAlpha).
	resultB := resultB / resultAlpha.
	targetWord at: 1 put: resultB rounded.

	targetForm bits bytesAt: pixelIndex put: targetWord.

	antiAliasAlpha > 0.5 ifTrue: [ 
		morphIds at: pixelIndex put: currentMorphId ]
]

{ #category : 'private' }
VectorEngineWholePixel >> pvtSetForm: aForm [

	| s |
	super pvtSetForm: aForm.
	s := targetForm width * targetForm height.
	alphaMask := ByteArray new: s.
	edgeCounts := ByteArray new: s
]

{ #category : 'primitive algorithms - aux' }
VectorEngineWholePixel >> updateAlphasForX: x y: y [

	"slight optimization possible when we know width = 0... perhaps implement: 
			-we know palpha is never 127 
			- we know distanceToEdge is always > erodedHalfWidth. 
				In smalltalk, performance icrease 1.5%. Perhaps in c/asm it is more than that... 
					Mas importante: 		Cuando width es medio grande, entonces dibujar la bolita rellena de entrada es importante... en los casos en que no necesito calcular la distancia"

	| distanceToAxisSquared alpha t b l r prevAlpha dx dy pixelIndex |
	"Compute affected rect. Honor clipRect"
	t := (y - auxStrokeWidthDilatedHalf) truncated + 1.
	t := t max: clipTop.
	b := (y + auxStrokeWidthDilatedHalf) truncated.
	b := b min: clipBottom.
	l := (x - auxStrokeWidthDilatedHalf) truncated + 1.
	l := l max: clipLeft.
	r := (x + auxStrokeWidthDilatedHalf) truncated.
	r := r min: clipRight.

	t to: b do: [ :displayY | 
		pixelIndex := displayY * targetWidth + l.
		dy := displayY - y.
		l to: r do: [ :displayX | 
			pixelIndex := pixelIndex + 1.
			prevAlpha := alphaMask at: pixelIndex.
			prevAlpha = 16r7F ifFalse: [ "le précédent alpha était déjà dans la zone w-r"
				dx := displayX - x.
				distanceToAxisSquared := dx * dx + (dy * dy). "pythagore, square distance"
				distanceToAxisSquared < auxStrokeWidthDilatedHalfSquared "we are in the area to be colorred "ifTrue: [ 
					alpha := distanceToAxisSquared <= auxStrokeWidthErodedHalfSquared
						         ifTrue: [ 16r7F ]
						         ifFalse: [ 
							         (auxStrokeWidthDilatedHalf
							          - distanceToAxisSquared sqrt
							          * auxAntiAliasingWidthScaledInverse) rounded ].
					alpha > prevAlpha ifTrue: [ alphaMask at: pixelIndex put: alpha ] ] ] ] ]
]

{ #category : 'primitive algorithms - aux' }
VectorEngineWholePixel >> updateEdgesAndBoundsForX: x y: y [

	| thisYTruncated pixelY pixelIndex increment count pixelX |
	blendLeft := blendLeft min: x.
	blendTop := blendTop min: y.
	blendRight := blendRight max: x.
	blendBottom := blendBottom max: y.
	fillColor notNil ifFalse: [ ^ self ].
	thisYTruncated := y truncated.
	(thisYTruncated between: clipTop - 1 and: clipBottom) ifTrue: [ 
		prevYTruncated
			ifNil: [ prevYTruncated := thisYTruncated ]
			ifNotNil: [ 
				thisYTruncated = prevYTruncated ifFalse: [ "All edge count at the left of the clipRect are added there (at the left of the clipRect).
											The effect is the same, and we need to clean up less stuff afterwards.
												More important, it avoids trying to acess pixels outside our form, i.e. invalid array acesses."
					pixelX := x truncated + 1 max: clipLeft.
					pixelX <= clipRight ifTrue: [ 
						pixelY := thisYTruncated max: prevYTruncated.
						increment := (thisYTruncated - prevYTruncated) sign.
						pixelIndex := pixelY * targetWidth + pixelX + 1.
						count := edgeCounts at: pixelIndex.
						count := count + increment bitAnd: 16rFF.
						edgeCounts at: pixelIndex put: count ].
					prevYTruncated := thisYTruncated ] ] ]
]
