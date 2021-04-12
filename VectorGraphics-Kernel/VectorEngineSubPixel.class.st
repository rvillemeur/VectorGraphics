Class {
	#name : #VectorEngineSubPixel,
	#superclass : #VectorEnginePixel,
	#instVars : [
		'subPixelDelta'
	],
	#category : #'VectorGraphics-Kernel'
}

{ #category : #'instance creation' }
VectorEngineSubPixel class >> defaultAntiAliasingWidth [

	^ 1.4
]

{ #category : #'private - blend with mask' }
VectorEngineSubPixel >> blendFillOnly [

	| edgesUpToThisPixelR edgesUpToThisPixelG edgesUpToThisPixelB edgesThisPixel edgesThisPixelR edgesThisPixelG edgesThisPixelB isRedInside isGreenInside isBlueInside pixelIndex morphAtThisPixelId |
	blendTop to: blendBottom do: [ :displayY | 
		edgesUpToThisPixelR := 0.
		edgesUpToThisPixelG := 0.
		edgesUpToThisPixelB := 0.
		pixelIndex := displayY * targetWidth + blendLeft.
		blendLeft to: blendRight do: [ :displayX | 
			pixelIndex := pixelIndex + 1.

			edgesThisPixel := edgeCounts bytesAt: pixelIndex.
			edgeCounts at: pixelIndex put: 0.
			edgesThisPixelR := edgesThisPixel at: 3.
			edgesThisPixelG := edgesThisPixel at: 2.
			edgesThisPixelB := edgesThisPixel at: 1.

			"Not needed in C or OpenCL, use signed char, i.e. a type where 16rFF means -1 and not 255"
			edgesThisPixelR > 127 ifTrue: [ 
				edgesThisPixelR := edgesThisPixelR - 256 ].
			edgesThisPixelG > 127 ifTrue: [ 
				edgesThisPixelG := edgesThisPixelG - 256 ].
			edgesThisPixelB > 127 ifTrue: [ 
				edgesThisPixelB := edgesThisPixelB - 256 ].

			edgesUpToThisPixelR := edgesUpToThisPixelR + edgesThisPixelR.
			edgesUpToThisPixelG := edgesUpToThisPixelG + edgesThisPixelG.
			edgesUpToThisPixelB := edgesUpToThisPixelB + edgesThisPixelB.
			isRedInside := edgesUpToThisPixelR ~= 0.
			isGreenInside := edgesUpToThisPixelG ~= 0.
			isBlueInside := edgesUpToThisPixelB ~= 0.

			(clippingMorphId = 0 or: [ 
				 morphAtThisPixelId := morphIds at: pixelIndex.
				 morphAtThisPixelId = clippingMorphId or: [ 
					 morphAtThisPixelId = currentMorphId ] ]) ifTrue: [ 
				self
					blendFillOnlyAtX: displayX
					y: displayY
					pixelIndex: pixelIndex
					redIsInside: isRedInside
					greenIsInside: isGreenInside
					blueIsInside: isBlueInside ].
			alphaMask at: pixelIndex put: 0 ] ]
]

{ #category : #'private - blend with mask' }
VectorEngineSubPixel >> blendFillOnlyAtX: x y: y pixelIndex: pixelIndex redIsInside: isRedInside greenIsInside: isGreenInside blueIsInside: isBlueInside [

	"targetForm only contains opaque colors. Assume its alpha is always one. Don't ask for it. Set it to one when writing.
	Blends fill over background. Despite method selector, there might be a very thin stroke of the same color as the fill. Handle this by adjusting antiAliasAlphas.
	For blending, alphas are in [0 .. 1.0] and R, G, B color components are in [0 .. 255]"

	| targetWord resultR resultG resultB antiAliasAlphasWord antiAliasRedAlpha antiAliasGreenAlpha antiAliasBlueAlpha alphaR alphaG alphaB unAlphaR unAlphaG unAlphaB resultAlpha targetAlpha |
	antiAliasAlphasWord := alphaMask bytesAt: pixelIndex.

	antiAliasAlphasWord = #[ 16r00 16r00 16r00 16r00 ] ifTrue: [ "Not in the stroke"
		(isRedInside or: [ isGreenInside or: [ isBlueInside ] ]) ifFalse: [ "Not inside" 
			^ self ] ]. "16r00000000" "Optimization: We are completely transparent at this point. Do nothing."

	"In this method, antiAliasAlphas are not used to blend stroke, but fill. This means that in the inside of the shape, and away from the stroke, they must be 1.0 (not 0.0)."
	antiAliasRedAlpha := (antiAliasAlphasWord at: 3) / 127.0.
	isRedInside ifTrue: [ antiAliasRedAlpha := 1.0 - antiAliasRedAlpha ].
	antiAliasGreenAlpha := (antiAliasAlphasWord at: 2) / 127.0.
	isGreenInside ifTrue: [ 
		antiAliasGreenAlpha := 1.0 - antiAliasGreenAlpha.
		morphIds at: pixelIndex put: currentMorphId ].
	antiAliasBlueAlpha := (antiAliasAlphasWord at: 1) / 127.0.
	isBlueInside ifTrue: [ 
		antiAliasBlueAlpha := 1.0 - antiAliasBlueAlpha ].

	targetWord := targetForm bits bytesAt: pixelIndex.
	targetAlpha := (targetWord at: 4) / 255.0.

	"These if are not really needed. just ignore them if we use simd instructions."
	antiAliasRedAlpha = 0.0 ifFalse: [ 
		alphaR := antiAliasRedAlpha * fillColor alpha.
		unAlphaR := 1.0 - alphaR.
		resultAlpha := alphaR + (unAlphaR * targetAlpha).
		resultR := alphaR * fillColor red * 255
		           + (unAlphaR * (targetWord at: 3) * targetAlpha).
		resultR := resultR / resultAlpha.
		targetWord at: 3 put: resultR rounded ].

	antiAliasGreenAlpha = 0.0 ifFalse: [ 
		alphaG := antiAliasGreenAlpha * fillColor alpha.
		unAlphaG := 1.0 - alphaG.
		resultAlpha := alphaG + (unAlphaG * targetAlpha).
		resultG := alphaG * fillColor green * 255
		           + (unAlphaG * (targetWord at: 2) * targetAlpha).
		resultG := resultG / resultAlpha.
		targetWord at: 2 put: resultG rounded.
		targetWord at: 4 put: (resultAlpha * 255) rounded ].

	antiAliasBlueAlpha = 0.0 ifFalse: [ 
		alphaB := antiAliasBlueAlpha * fillColor alpha.
		unAlphaB := 1.0 - alphaB.
		resultAlpha := alphaB + (unAlphaB * targetAlpha).
		resultB := alphaB * fillColor blue * 255
		           + (unAlphaB * (targetWord at: 1) * targetAlpha).
		resultB := resultB / resultAlpha.
		targetWord at: 1 put: resultB rounded ].

	targetForm bits bytesAt: pixelIndex put: targetWord
]

{ #category : #'private - blend with mask' }
VectorEngineSubPixel >> blendStrokeAndFill [

	| edgesUpToThisPixelR edgesUpToThisPixelG edgesUpToThisPixelB edgesThisPixel edgesThisPixelR edgesThisPixelG edgesThisPixelB isRedInside isGreenInside isBlueInside pixelIndex morphAtThisPixelId |
	blendTop to: blendBottom do: [ :displayY | 
		edgesUpToThisPixelR := 0.
		edgesUpToThisPixelG := 0.
		edgesUpToThisPixelB := 0.
		pixelIndex := displayY * targetWidth + blendLeft.
		blendLeft to: blendRight do: [ :displayX | 
			pixelIndex := pixelIndex + 1.

			edgesThisPixel := edgeCounts bytesAt: pixelIndex.
			edgeCounts at: pixelIndex put: 0.
			edgesThisPixelR := edgesThisPixel at: 3.
			edgesThisPixelG := edgesThisPixel at: 2.
			edgesThisPixelB := edgesThisPixel at: 1.

			"Not needed in C or OpenCL, use signed char, i.e. a type where 16rFF means -1 and not 255"
			edgesThisPixelR > 127 ifTrue: [ 
				edgesThisPixelR := edgesThisPixelR - 256 ].
			edgesThisPixelG > 127 ifTrue: [ 
				edgesThisPixelG := edgesThisPixelG - 256 ].
			edgesThisPixelB > 127 ifTrue: [ 
				edgesThisPixelB := edgesThisPixelB - 256 ].

			edgesUpToThisPixelR := edgesUpToThisPixelR + edgesThisPixelR.
			edgesUpToThisPixelG := edgesUpToThisPixelG + edgesThisPixelG.
			edgesUpToThisPixelB := edgesUpToThisPixelB + edgesThisPixelB.
			isRedInside := edgesUpToThisPixelR ~= 0.
			isGreenInside := edgesUpToThisPixelG ~= 0.
			isBlueInside := edgesUpToThisPixelB ~= 0.

			(clippingMorphId = 0 or: [ 
				 morphAtThisPixelId := morphIds at: pixelIndex.
				 morphAtThisPixelId = clippingMorphId or: [ 
					 morphAtThisPixelId = currentMorphId ] ]) ifTrue: [ 
				self
					blendStrokeAndFillAtX: displayX
					y: displayY
					pixelIndex: pixelIndex
					redIsInside: isRedInside
					greenIsInside: isGreenInside
					blueIsInside: isBlueInside ].
			alphaMask at: pixelIndex put: 0 ] ]
]

{ #category : #'private - blend with mask' }
VectorEngineSubPixel >> blendStrokeAndFillAtX: x y: y pixelIndex: pixelIndex redIsInside: isRedInside greenIsInside: isGreenInside blueIsInside: isBlueInside [

	"targetForm only contains opaque colors. Assume its alpha is always one. Don't ask for it. Set it to one when writing.
	Do an appropriate (anti aliased) mix between stoke and fill (or pick just stroke or just fill). Blend this over background.
	For blending, alphas are in [0 .. 1.0] and R, G, B color components are in [0 .. 255]"

	| targetWord resultR resultG resultB antiAliasAlphasWord antiAliasRedAlpha antiAliasGreenAlpha antiAliasBlueAlpha alphaR alphaG alphaB unAlphaR unAlphaG unAlphaB foreR foreG foreB targetAlpha resultAlpha |
	antiAliasAlphasWord := alphaMask bytesAt: pixelIndex.
	antiAliasAlphasWord = #[ 16r00 16r00 16r00 16r00 ] ifTrue: [ 
		(isRedInside or: [ isGreenInside or: [ isBlueInside ] ]) ifFalse: [ 
			^ self ] ]. "16r00000000" "Optimization: We are completely transparent at this point. Do nothing."

	antiAliasRedAlpha := (antiAliasAlphasWord at: 3) / 127.0.
	antiAliasGreenAlpha := (antiAliasAlphasWord at: 2) / 127.0.
	antiAliasBlueAlpha := (antiAliasAlphasWord at: 1) / 127.0.

	targetWord := targetForm bits bytesAt: pixelIndex.
	targetAlpha := (targetWord at: 4) / 255.0.

	isRedInside
		ifTrue: [ "Do gradient between stroke and fill. Blend the result over background"
			alphaR := antiAliasRedAlpha * strokeColor alpha
			          + (1 - antiAliasRedAlpha * fillColor alpha).
			foreR := antiAliasRedAlpha * strokeColor red * 255
			         + (1 - antiAliasRedAlpha * fillColor red * 255) ]
		ifFalse: [ "Blend stroke over background"
			alphaR := antiAliasRedAlpha * strokeColor alpha.
			foreR := strokeColor red * 255 ].

	isGreenInside
		ifTrue: [ "Do gradient between stroke and fill. Blend the result over background"
			alphaG := antiAliasGreenAlpha * strokeColor alpha
			          + (1 - antiAliasGreenAlpha * fillColor alpha).
			foreG := antiAliasGreenAlpha * strokeColor green * 255
			         + (1 - antiAliasGreenAlpha * fillColor green * 255).
			morphIds at: pixelIndex put: currentMorphId ]
		ifFalse: [ "Blend stroke over background"
			alphaG := antiAliasGreenAlpha * strokeColor alpha.
			foreG := strokeColor green * 255.
			antiAliasGreenAlpha > 0.5 ifTrue: [ 
				morphIds at: pixelIndex put: currentMorphId ] ].

	isBlueInside
		ifTrue: [ "Do gradient between stroke and fill. Blend the result over background"
			alphaB := antiAliasBlueAlpha * strokeColor alpha
			          + (1 - antiAliasBlueAlpha * fillColor alpha).
			foreB := antiAliasBlueAlpha * strokeColor blue * 255
			         + (1 - antiAliasBlueAlpha * fillColor blue * 255) ]
		ifFalse: [ "Blend stroke over background"
			alphaB := antiAliasBlueAlpha * strokeColor alpha.
			foreB := strokeColor blue * 255 ].

	"These if are not really needed. just ignore them if we use simd instructions."
	alphaR = 0.0 ifFalse: [ 
		unAlphaR := 1.0 - alphaR.
		resultAlpha := alphaR + (unAlphaR * targetAlpha).
		resultR := alphaR * foreR
		           + (unAlphaR * (targetWord at: 3) * targetAlpha).
		resultR := resultR / resultAlpha.
		targetWord at: 3 put: resultR rounded ].
	alphaG = 0.0 ifFalse: [ 
		unAlphaG := 1.0 - alphaG.
		resultAlpha := alphaG + (unAlphaG * targetAlpha).
		resultG := alphaG * foreG
		           + (unAlphaG * (targetWord at: 2) * targetAlpha).
		resultG := resultG / resultAlpha.
		targetWord at: 2 put: resultG rounded.
		targetWord at: 4 put: (resultAlpha * 255) rounded ].
	alphaB = 0.0 ifFalse: [ 
		unAlphaB := 1.0 - alphaB.
		resultAlpha := alphaB + (unAlphaB * targetAlpha).
		resultB := alphaB * foreB
		           + (unAlphaB * (targetWord at: 1) * targetAlpha).
		resultB := resultB / resultAlpha.
		targetWord at: 1 put: resultB rounded ].

	targetForm bits bytesAt: pixelIndex put: targetWord
]

{ #category : #'private - blend with mask' }
VectorEngineSubPixel >> blendStrokeOnly [

	| pixelIndex morphAtThisPixelId |
	blendTop to: blendBottom do: [ :displayY | 
		pixelIndex := displayY * targetWidth + blendLeft.
		blendLeft to: blendRight do: [ :displayX | 
			pixelIndex := pixelIndex + 1.
			(clippingMorphId = 0 or: [ 
				 morphAtThisPixelId := morphIds at: pixelIndex.
				 morphAtThisPixelId = clippingMorphId or: [ 
					 morphAtThisPixelId = currentMorphId ] ]) ifTrue: [ 
				self
					blendStrokeOnlyAtX: displayX
					y: displayY
					pixelIndex: pixelIndex ].
			alphaMask at: pixelIndex put: 0 ] ]
]

{ #category : #'private - blend with mask' }
VectorEngineSubPixel >> blendStrokeOnlyAtX: x y: y pixelIndex: pixelIndex [

	"targetForm only contains opaque colors. Assume its alpha is always one. Don't ask for it. Set it to one when writing.
	Blends stroke over background.
	For blending, alphas are in [0 .. 1.0] and R, G, B color components are in [0 .. 255]"

	| targetWord resultR resultG resultB antiAliasAlphasWord antiAliasRedAlpha antiAliasGreenAlpha antiAliasBlueAlpha alphaR alphaG alphaB unAlphaR unAlphaG unAlphaB resultAlpha targetAlpha |
	antiAliasAlphasWord := alphaMask bytesAt: pixelIndex.
	antiAliasAlphasWord = #[ 16r00 16r00 16r00 16r00 ] ifTrue: [ ^ self ]. "16r00000000" "Optimization: We are completely transparent at this point. Do nothing."

	antiAliasRedAlpha := (antiAliasAlphasWord at: 3) / 127.0.
	antiAliasGreenAlpha := (antiAliasAlphasWord at: 2) / 127.0.
	antiAliasBlueAlpha := (antiAliasAlphasWord at: 1) / 127.0.

	targetWord := targetForm bits bytesAt: pixelIndex.
	targetAlpha := (targetWord at: 4) / 255.0.

	"These if are not really needed. just ignore them if we use simd instructions."
	antiAliasRedAlpha = 0.0 ifFalse: [ 
		alphaR := antiAliasRedAlpha * strokeColor alpha.
		unAlphaR := 1.0 - alphaR.
		resultAlpha := alphaR + (unAlphaR * targetAlpha).
		resultR := alphaR * strokeColor red * 255
		           + (unAlphaR * (targetWord at: 3) * targetAlpha).
		resultR := resultR / resultAlpha.
		targetWord at: 3 put: resultR rounded ].

	antiAliasGreenAlpha = 0.0 ifFalse: [ 
		alphaG := antiAliasGreenAlpha * strokeColor alpha.
		unAlphaG := 1.0 - alphaG.
		resultAlpha := alphaG + (unAlphaG * targetAlpha).
		resultG := alphaG * strokeColor green * 255
		           + (unAlphaG * (targetWord at: 2) * targetAlpha).
		resultG := resultG / resultAlpha.
		targetWord at: 2 put: resultG rounded.
		targetWord at: 4 put: (resultAlpha * 255) rounded ].

	antiAliasBlueAlpha = 0.0 ifFalse: [ 
		alphaB := antiAliasBlueAlpha * strokeColor alpha.
		unAlphaB := 1.0 - alphaB.
		resultAlpha := alphaB + (unAlphaB * targetAlpha).
		resultB := alphaB * strokeColor blue * 255
		           + (unAlphaB * (targetWord at: 1) * targetAlpha).
		resultB := resultB / resultAlpha.
		targetWord at: 1 put: resultB rounded ].

	targetForm bits bytesAt: pixelIndex put: targetWord.

	antiAliasGreenAlpha > 0.5 ifTrue: [ 
		morphIds at: pixelIndex put: currentMorphId ]
]

{ #category : #private }
VectorEngineSubPixel >> finishPath: ensureClosePath [

	"Blend stroke and/or fill over background, according to the just computed pen alphas (distance from pixel to center of stroke)"

	"If we are doing a fill, and caller forgot to close the trajectory, then do it anyway."

	ensureClosePath ifTrue: [ 
		(pathFirstX = pathCurrentX and: [ pathFirstY = pathCurrentY ]) 
			ifFalse: [ "This is actually an error condition. If we are asked to fill, then the path should be closed. 	This is a workaround. If width > 0.0, we'll be adding a visible edge to the path." 
				self basicClosePath ] ].

	blendLeft := (blendLeft - auxStrokeWidthDilatedHalf - subPixelDelta)
		             truncated + 1.
	blendTop := (blendTop - auxStrokeWidthDilatedHalf) truncated + 1.
	blendRight := (blendRight + auxStrokeWidthDilatedHalf + subPixelDelta)
		              truncated + 1. "Make room not just for updated mask, but also edges (hence, +1)"
	blendBottom := (blendBottom + auxStrokeWidthDilatedHalf) truncated.

	"morphBounds is not affected by clipRect"
	morphBoundsLeft := morphBoundsLeft min: blendLeft.
	morphBoundsTop := morphBoundsTop min: blendTop.
	morphBoundsRight := morphBoundsRight max: blendRight.
	morphBoundsBottom := morphBoundsBottom max: blendBottom.

	blendLeft := blendLeft max: clipLeft.
	blendTop := blendTop max: clipTop.
	blendRight := blendRight min: clipRight.
	blendBottom := blendBottom min: clipBottom.

	(blendRight >= blendLeft and: [ blendBottom >= blendTop ]) ifTrue: [ 
		fillColor notNil
			ifTrue: [ 
				strokeColor notNil
					ifTrue: [ self blendStrokeAndFill ]
					ifFalse: [ self blendFillOnly ] ]
			ifFalse: [ self blendStrokeOnly ] ].

	pathFirstX := 0.0.
	pathFirstY := 0.0.
	pathCurrentX := 0.0.
	pathCurrentY := 0.0.
	previousCallX := 0.0.
	previousCallY := 0.0.
	previousCallControlX := previousCallX.
	previousCallControlY := previousCallY
]

{ #category : #private }
VectorEngineSubPixel >> pvtSetForm: aForm [

	| s |
	super pvtSetForm: aForm.
	s := targetForm width * targetForm height.
	alphaMask := WordArray new: s.
	edgeCounts := WordArray new: s.
	subPixelDelta := 0.25 "Values closer to 0.333 might produce a bit of coloring on some displays. Used to be 0.28"
]

{ #category : #'primitive algorithms - aux' }
VectorEngineSubPixel >> updateAlphasForX: x y: y [

	"slight optimization possible when we know width = 0... perhaps implement:
		-we know palpha is never 127
		- we know distanceToEdge is always > erodedHalfWidth.
	In smalltalk, performance icrease 1.5%. Perhaps in c/asm it is more than that...
	Mas importante:
		Cuando width es medio grande, entonces dibujar la bolita rellena de entrada es importante... en los casos en que no necesito calcular la distancia"

	| distanceToAxisSquared alpha t b l r alphaWord doUpdate dySquared dx dxSquared dy pixelIndex dxp |
	"Compute affected rect. Honor clipRect"
	t := (y - auxStrokeWidthDilatedHalf) truncated + 1.
	t := t max: clipTop.
	b := (y + auxStrokeWidthDilatedHalf) truncated.
	b := b min: clipBottom.
	l := (x - auxStrokeWidthDilatedHalf - subPixelDelta) truncated + 1.
	l := l max: clipLeft.
	r := (x + auxStrokeWidthDilatedHalf + subPixelDelta) truncated.
	r := r min: clipRight.

	t to: b do: [ :displayY | 
		pixelIndex := displayY * targetWidth + l.
		l to: r do: [ :displayX | 
			pixelIndex := pixelIndex + 1.
			alphaWord := alphaMask bytesAt: pixelIndex.
			alphaWord = #[ 16r7F 16r7F 16r7F 16r00 ] ifFalse: [ "16r007F7F7F"
				doUpdate := false.
				dy := displayY - y.
				dySquared := dy * dy.
				dx := displayX - x.
				"Red"
				dxp := dx - subPixelDelta.
				dxSquared := dxp * dxp.
				distanceToAxisSquared := dxSquared + dySquared.
				distanceToAxisSquared < auxStrokeWidthDilatedHalfSquared ifTrue: [ 
					alpha := distanceToAxisSquared <= auxStrokeWidthErodedHalfSquared
						         ifTrue: [ 16r7F ]
						         ifFalse: [ 
							         (auxStrokeWidthDilatedHalf
							          - distanceToAxisSquared sqrt
							          * auxAntiAliasingWidthScaledInverse) rounded ].
					alpha > (alphaWord at: 3) ifTrue: [ 
						alphaWord at: 3 put: alpha.
						doUpdate := true ] ].
				"Green"
				dxSquared := dx * dx.
				distanceToAxisSquared := dxSquared + dySquared.
				distanceToAxisSquared < auxStrokeWidthDilatedHalfSquared ifTrue: [ 
					alpha := distanceToAxisSquared <= auxStrokeWidthErodedHalfSquared
						         ifTrue: [ 16r7F ]
						         ifFalse: [ 
							         (auxStrokeWidthDilatedHalf
							          - distanceToAxisSquared sqrt
							          * auxAntiAliasingWidthScaledInverse) rounded ].
					alpha > (alphaWord at: 2) ifTrue: [ 
						alphaWord at: 2 put: alpha.
						doUpdate := true ] ].
				"Blue"
				dxp := dx + subPixelDelta.
				dxSquared := dxp * dxp.
				distanceToAxisSquared := dxSquared + dySquared.
				distanceToAxisSquared < auxStrokeWidthDilatedHalfSquared ifTrue: [ 
					alpha := distanceToAxisSquared <= auxStrokeWidthErodedHalfSquared
						         ifTrue: [ 16r7F ]
						         ifFalse: [ 
							         (auxStrokeWidthDilatedHalf
							          - distanceToAxisSquared sqrt
							          * auxAntiAliasingWidthScaledInverse) rounded ].
					alpha > (alphaWord at: 1) ifTrue: [ 
						alphaWord at: 1 put: alpha.
						doUpdate := true ] ].
				doUpdate ifTrue: [ alphaMask bytesAt: pixelIndex put: alphaWord ] ] ] ]
]

{ #category : #'primitive algorithms - aux' }
VectorEngineSubPixel >> updateEdgeCountAtX: x y: y [

	| thisYTruncated pixelY pixelIndexBase redPixelIndex greenPixelIndex bluePixelIndex increment countWord redCount greenCount blueCount redOffset greenOffset blueOffset |
	thisYTruncated := y truncated.
	(thisYTruncated between: clipTop - 1 and: clipBottom) ifFalse: [ 
		^ self ].
	prevYTruncated ifNil: [ ^ prevYTruncated := thisYTruncated ].
	thisYTruncated = prevYTruncated ifTrue: [ ^ self ].

	thisYTruncated > prevYTruncated
		ifTrue: [ 
			pixelY := thisYTruncated.
			increment := 1 ]
		ifFalse: [ 
			pixelY := prevYTruncated.
			increment := -1 ].
	prevYTruncated := thisYTruncated.

	"All edge count at the left of the clipRect are added there (at the left of the clipRect).
	The effect is the same, and we need to clean up less stuff afterwards.
	More important, it avoids trying to acess pixels outside our form, i.e. invalid array acesses."
	pixelIndexBase := pixelY * targetWidth.
	redOffset := (x + subPixelDelta) truncated + 1 max: clipLeft.
	greenOffset := x truncated + 1 max: clipLeft.
	blueOffset := (x - subPixelDelta) truncated + 1 max: clipLeft.
	redPixelIndex := pixelIndexBase + redOffset + 1.
	greenPixelIndex := pixelIndexBase + greenOffset + 1.
	bluePixelIndex := pixelIndexBase + blueOffset + 1.

	"Three possible cases here: RGB in one word (pixel); RG in one, and G in another; R in one, GB in another"
	redPixelIndex = bluePixelIndex
		ifTrue: [ "First case: RGB in the same word"
			redOffset <= clipRight ifTrue: [ 
				countWord := edgeCounts bytesAt: redPixelIndex.
				redCount := (countWord at: 3) + increment bitAnd: 16rFF.
				countWord at: 3 put: redCount.
				greenCount := (countWord at: 2) + increment bitAnd: 16rFF.
				countWord at: 2 put: greenCount.
				blueCount := (countWord at: 1) + increment bitAnd: 16rFF.
				countWord at: 1 put: blueCount.
				edgeCounts bytesAt: redPixelIndex put: countWord ] ]
		ifFalse: [ 
			redPixelIndex = greenPixelIndex
				ifTrue: [ "Second case: RG in one word, B in previous"
					redOffset <= clipRight ifTrue: [ 
						countWord := edgeCounts bytesAt: redPixelIndex.
						redCount := (countWord at: 3) + increment bitAnd: 16rFF.
						countWord at: 3 put: redCount.
						greenCount := (countWord at: 2) + increment bitAnd: 16rFF.
						countWord at: 2 put: greenCount.
						edgeCounts bytesAt: redPixelIndex put: countWord ].

					blueOffset <= clipRight ifTrue: [ 
						countWord := edgeCounts bytesAt: bluePixelIndex.
						blueCount := (countWord at: 1) + increment bitAnd: 16rFF.
						countWord at: 1 put: blueCount.
						edgeCounts bytesAt: bluePixelIndex put: countWord ] ]
				ifFalse: [ "Third case: R in one word, GB in the previous"
					redOffset <= clipRight ifTrue: [ 
						countWord := edgeCounts bytesAt: redPixelIndex.
						redCount := (countWord at: 3) + increment bitAnd: 16rFF.
						countWord at: 3 put: redCount.
						edgeCounts bytesAt: redPixelIndex put: countWord ].

					blueOffset <= clipRight ifTrue: [ 
						countWord := edgeCounts bytesAt: bluePixelIndex.
						greenCount := (countWord at: 2) + increment bitAnd: 16rFF.
						countWord at: 2 put: greenCount.
						blueCount := (countWord at: 1) + increment bitAnd: 16rFF.
						countWord at: 1 put: blueCount.
						edgeCounts bytesAt: bluePixelIndex put: countWord ] ] ]
]

{ #category : #'as yet unclassified' }
VectorEngineSubPixel >> updateEdgesAndBoundsForX: x y: y [

	"
Inlinear en senders. Extraer afectar bounds si es posible (linea, circulo)
"

	blendLeft := blendLeft min: x.
	blendTop := blendTop min: y.
	blendRight := blendRight max: x.
	blendBottom := blendBottom max: y.

	"Compute edges intersecting with this horizontal line, for fills."
	fillColor notNil ifTrue: [ self updateEdgeCountAtX: x y: y ]
]
