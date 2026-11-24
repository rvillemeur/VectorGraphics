"
I hold VGInteriorQuestionBudget to the census it reads and to arithmetic: it times every stage
the census counts but the one that is no test, it times each stage over the questions the census
says reach it, and the whole predicate costs at least as much as the dearest stage inside it.

I pass two passes where a reading of the real figures passes twenty: the facts here are about
what is timed, not about how long it takes.
"
Class {
	#name : 'VGInteriorQuestionBudgetTest',
	#superclass : 'TestCase',
	#category : 'VectorGraphics-Vulkan-Tests-Tests',
	#package : 'VectorGraphics-Vulkan-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
VGInteriorQuestionBudgetTest >> testEachStageIsTimedOverTheQuestionsTheCensusSaysReachIt [
	"A stage is paid by every question that gets to it, so the loop timed for a stage walks the
	 pairs the census recorded under it. That is the whole link between the counting and the
	 timing: if they walked different pairs the microseconds would say nothing about the table."
	| budget |
	budget := VGInteriorQuestionBudget
		          overFrames: { #cards }
		          extent: VGFrameDeviceBenchmark extentOfItsFrames
		          passes: 2.
	budget rows do: [ :row |
		VGInteriorQuestionBudgetRow timedStages do: [ :stage |
			self
				assert: (row pairCountOf: stage)
				equals: (row census pairsReaching: stage) size ] ]
]

{ #category : 'tests' }
VGInteriorQuestionBudgetTest >> testTheStagesTimedAreTheStagesCountedExceptTheOneThatIsNoTest [
	"Every stage of the census is a test of the predicate that a question pays, except the last:
	 covered is where a question comes out, not a test it is charged for. So that one is not
	 timed and every other one is."
	self
		assert: VGInteriorQuestionBudgetRow timedStages
		equals:
		(VGInteriorQuestionCensusRow stageNames copyWithout:
			 VGInteriorQuestionCensusRow coveredStage)
]

{ #category : 'tests' }
VGInteriorQuestionBudgetTest >> testTheWholePredicateCostsAtLeastItsDearestStage [
	"The whole predicate runs every stage a question reaches, so its floor cannot be under the
	 floor of any one stage. The reverse is what the unit is for: how far over the sum of the
	 stages the whole predicate sits is what the descent itself costs."
	| budget |
	budget := VGInteriorQuestionBudget
		          overFrames: { #cards }
		          extent: VGFrameDeviceBenchmark extentOfItsFrames
		          passes: 2.
	budget rows do: [ :row |
		self assert: row wholeFloor >= (VGInteriorQuestionBudgetRow timedStages
				 inject: 0
				 into: [ :dearest :stage |
					 dearest max: (row floorOf: stage) ]) ]
]
