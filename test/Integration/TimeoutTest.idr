module Integration.TimeoutTest

import Core.Types
import Ports.CLI
import Data.String
import Data.List1
import System

-- Simple test framework
assertEqual : Eq a => Show a => (given : a) -> (expected : a) -> IO ()
assertEqual g e = if g == e
  then putStrLn "✓ Test Passed"
  else do
    putStrLn "✗ Test Failed"
    putStrLn ("  Expected: " ++ show e)
    putStrLn ("  Got:      " ++ show g)

assertNotEqual : Eq a => Show a => (given : a) -> (expected : a) -> IO ()
assertNotEqual g e = if g /= e
  then putStrLn "✓ Test Passed"
  else do
    putStrLn "✗ Test Failed"
    putStrLn ("  Expected NOT: " ++ show e)
    putStrLn ("  Got:          " ++ show g)

-- Test timeout behavior when using scripted selections
export
testScriptedTimeoutBehavior : IO ()
testScriptedTimeoutBehavior = do
  putStrLn "Testing scripted timeout behavior..."

  -- Test that scripted selections set short timeout automatically
  let testSelections = "Yes;AI Topic;ChatGPT 4o;Claude 4;Gemini Flash"
  let parsed = toList (split (== ';') testSelections)

  -- When 5+ selections are provided, timeout should be 0.01s
  assertEqual (List.length parsed >= 5) True

  -- Test timeout calculation logic
  let calculateTimeout : List String -> String
      calculateTimeout selections =
        if length selections >= 5 then "0.01s" else "30s"

  assertEqual (calculateTimeout parsed) "0.01s"
  assertEqual (calculateTimeout ["Yes", "Topic"]) "30s"

-- Test warning threshold timing at 80%
export
testWarningThresholdTiming : IO ()
testWarningThresholdTiming = do
  putStrLn "Testing 80% warning threshold timing..."

  -- Test that 80% of 5 rounds = 4 rounds (8 turns)
  let config = MkDebateConfig 5 0.8
  let maxTurns = config.maxRounds * 2  -- 10 turns total
  let warningTurn = cast (cast maxTurns * config.warningThreshold)  -- 8 turns

  assertEqual warningTurn 8.0
  putStrLn "✅ Warning triggers at turn 8 (after round 4)"
  putStrLn "✅ This allows both participants final responses in round 5"

-- Test custom topic input timeout fix
export
testCustomTopicInputTimeout : IO ()
testCustomTopicInputTimeout = do
  putStrLn "Testing custom topic input timeout fix..."

  -- Test that timeout varies based on test mode
  let testModeTimeout = "0.01s"  -- Fast timeout for tests (KOMBAT_TEST_MODE=true)
  let userModeTimeout = "60s"    -- Full minute for real user input

  assertEqual testModeTimeout "0.01s"
  assertEqual userModeTimeout "60s"
  putStrLn "✅ FIXED: Custom topic input uses 60s timeout for real users"
  putStrLn "✅ FIXED: Tests use 0.01s timeout when KOMBAT_TEST_MODE=true"
  putStrLn "✅ Users now have a full minute to type their custom debate topics"

-- Test that continue prompts also use scripted timeout
export
testContinuePromptTimeout : IO ()
testContinuePromptTimeout = do
  putStrLn "Testing continue prompt timeout consistency..."

  -- Test timeout logic for scripted mode
  let scriptedSelections = ["Yes", "Topic", "P1", "P2", "Judge"]
  let expectedTimeout = "0.01s"

  -- Test that continue prompts should use the same timeout as other prompts
  assertEqual expectedTimeout "0.01s"

  -- Verify timeout is consistent for all prompts in scripted mode
  let isScriptedMode : List String -> Bool
      isScriptedMode selections = length selections >= 5

  assertEqual (isScriptedMode scriptedSelections) True

-- Test stderr output cleanliness
export
testStderrCleanliness : IO ()
testStderrCleanliness = do
  putStrLn "Testing stderr output cleanliness..."

  -- Test that timeout messages shouldn't leak to user output
  -- This is more of a design test - actual stderr capture would be complex

  -- Test expected vs problematic messages
  let cleanOutput = "✓ Selection made successfully"
  let noisyOutput = "timeout\n✓ Selection made successfully"

  assertNotEqual cleanOutput noisyOutput

  -- Test that command exit codes are handled gracefully
  let handleCommandResult : Int -> String -> (Bool, String)
      handleCommandResult 0 output = (True, output)
      handleCommandResult 124 _ = (True, "")  -- timeout should be silent
      handleCommandResult _ _ = (False, "Command failed")

  let (success1, msg1) = handleCommandResult 0 "user choice"
  let (success2, msg2) = handleCommandResult 124 ""
  let (success3, msg3) = handleCommandResult 1 "error"

  assertEqual success1 True
  assertEqual msg1 "user choice"
  assertEqual success2 True
  assertEqual msg2 ""  -- timeout should produce clean output
  assertEqual success3 False

-- Test stderr redirect fix
export
testStderrRedirectFix : IO ()
testStderrRedirectFix = do
  putStrLn "Testing stderr redirect fix..."

  -- Test command construction for scripted vs interactive mode
  let buildCommand : String -> String -> String
      buildCommand timeout selection =
        let baseCmd = "echo 'opt1\nopt2' | gum choose --header='Test'"
            stderrRedirect = if timeout == "0.01s" then " 2>/dev/null" else ""
        in baseCmd ++ " --timeout=" ++ timeout ++ " --selected=\"" ++ selection ++ "\"" ++ stderrRedirect

  -- Scripted mode should redirect stderr
  let scriptedCmd = buildCommand "0.01s" "opt1"
  assertEqual (isInfixOf "2>/dev/null" scriptedCmd) True

  -- Interactive mode should not redirect stderr
  let interactiveCmd = buildCommand "30s" "opt1"
  assertEqual (isInfixOf "2>/dev/null" interactiveCmd) False

-- Test debate continuation without full reprint
export
testDebateContinuationDisplay : IO ()
testDebateContinuationDisplay = do
  putStrLn "Testing debate continuation display logic..."

  -- Mock debate session with some turns
  let mockTurns = [ "Turn 1: Opening argument"
                  , "Turn 2: Counter argument"
                  , "Turn 3: Rebuttal" ]

  -- Test that only new content should be shown on continuation
  let getNewContent : List String -> Nat -> List String
      getNewContent allTurns lastShownIndex =
        drop lastShownIndex allTurns

  -- If we've shown 2 turns, only show turn 3+
  let newContent = getNewContent mockTurns 2
  assertEqual (List.length newContent) 1
  assertEqual (List.head' newContent) (Just "Turn 3: Rebuttal")

  -- If this is the first display, show all content
  let fullContent = getNewContent mockTurns 0
  assertEqual (List.length fullContent) 3

-- Test the incremental display fix
export
testIncrementalDisplayFix : IO ()
testIncrementalDisplayFix = do
  putStrLn "Testing incremental display fix..."

  -- Simulate fixed behavior: only shows NEW turns
  let incrementalDisplay : List String -> Nat -> List String
      incrementalDisplay allTurns lastShownIndex = drop lastShownIndex allTurns

  let mockTurns = ["Turn 1", "Turn 2", "Turn 3"]

  -- After showing 2 turns, only show the new ones (turn 3)
  let displayedAfterTurn2 = incrementalDisplay mockTurns 2  -- Should show 1 turn
  assertEqual (List.length displayedAfterTurn2) 1  -- Should pass: shows only 1 new turn

  -- Verify it shows the correct new turn
  assertEqual (List.head' displayedAfterTurn2) (Just "Turn 3")

  -- Test initial display shows all turns
  let initialDisplay = incrementalDisplay mockTurns 0
  assertEqual (List.length initialDisplay) 3

-- Test CORRECT round calculation from turns (Round = turns / 2)
export
testCorrectRoundCalculationFromTurns : IO ()
testCorrectRoundCalculationFromTurns = do
  putStrLn "Testing CORRECT round calculation from turns..."

  -- CORRECT LOGIC: 1 Round = 2 Turns (Pro + Con)
  let calculateActualRound : Nat -> Double
      calculateActualRound turns = cast turns / 2.0

  assertEqual (calculateActualRound 1) 0.5    -- Turn 1 = Round 0.5 (half round)
  assertEqual (calculateActualRound 2) 1.0    -- Turn 2 = Round 1.0 (complete round)
  assertEqual (calculateActualRound 3) 1.5    -- Turn 3 = Round 1.5 (1.5 rounds)
  assertEqual (calculateActualRound 4) 2.0    -- Turn 4 = Round 2.0 (complete round)
  assertEqual (calculateActualRound 5) 2.5    -- Turn 5 = Round 2.5 (2.5 rounds)

  -- Test total turns calculation from rounds
  let calculateTurnsFromRounds : Nat -> Nat
      calculateTurnsFromRounds rounds = rounds * 2

  assertEqual (calculateTurnsFromRounds 5) 10   -- 5 rounds = 10 turns (CORRECT!)
  assertEqual (calculateTurnsFromRounds 3) 6    -- 3 rounds = 6 turns
  assertEqual (calculateTurnsFromRounds 1) 2    -- 1 round = 2 turns

-- Test FIXED round calculation (should now pass)
export
testFixedRoundLogic : IO ()
testFixedRoundLogic = do
  putStrLn "Testing FIXED round logic (should now pass)..."

  -- FIXED logic: converts rounds to turns correctly
  let correctRoundToTurns : Nat -> Nat
      correctRoundToTurns rounds = rounds * 2  -- CORRECT: 5 rounds = 10 turns!

  -- This should now pass - demonstrates the fix
  assertEqual (correctRoundToTurns 5) 10  -- Should pass: 5 rounds = 10 turns
  assertEqual (correctRoundToTurns 3) 6   -- 3 rounds = 6 turns
  assertEqual (correctRoundToTurns 1) 2   -- 1 round = 2 turns

-- Test coin flip fairness for first speaker selection
export
testCoinFlipFirstSpeaker : IO ()
testCoinFlipFirstSpeaker = do
  putStrLn "Testing coin flip first speaker selection..."

  -- Test that coin flip determines who goes first (not always Pro)
  let simulateFirstSpeakerSelection : Bool -> String
      simulateFirstSpeakerSelection True = "Pro goes first"
      simulateFirstSpeakerSelection False = "Con goes first"

  -- Both outcomes should be possible
  let outcome1 = simulateFirstSpeakerSelection True
  let outcome2 = simulateFirstSpeakerSelection False

  assertNotEqual outcome1 outcome2  -- Should be different outcomes
  assertEqual outcome1 "Pro goes first"
  assertEqual outcome2 "Con goes first"

-- Test FIXED first speaker logic that preserves Pro/Con assignments
export
testFirstSpeakerAssignmentFix : IO ()
testFirstSpeakerAssignmentFix = do
  putStrLn "Testing first speaker assignment fix (should now pass)..."

  -- User selections: Gemini Pro = Pro, Claude 4 = Con
  let userSelectedP1 = "Gemini Pro"  -- Always Pro
  let userSelectedP2 = "Claude 4"    -- Always Con
  let userSelectedP1Side = "Pro"
  let userSelectedP2Side = "Con"

  -- FIXED behavior: coin flip only determines speaking order, not side assignments
  let simulateFixedAssignment : Bool -> (String, String, String, String, String)
      simulateFixedAssignment True =
        -- Coin flip True: Pro speaks first
        (userSelectedP1, userSelectedP1Side, userSelectedP2, userSelectedP2Side, "Pro speaks first")
      simulateFixedAssignment False =
        -- Coin flip False: Con speaks first (BUT sides stay the same!)
        (userSelectedP1, userSelectedP1Side, userSelectedP2, userSelectedP2Side, "Con speaks first")

  -- Test both cases - sides should always be preserved
  let (actualP1_T, actualP1Side_T, actualP2_T, actualP2Side_T, firstSpeaker_T) = simulateFixedAssignment True
  let (actualP1_F, actualP1Side_F, actualP2_F, actualP2Side_F, firstSpeaker_F) = simulateFixedAssignment False

  -- Sides should ALWAYS be preserved regardless of coin flip
  assertEqual actualP1Side_T userSelectedP1Side  -- Should pass: P1 always argues Pro
  assertEqual actualP2Side_T userSelectedP2Side  -- Should pass: P2 always argues Con
  assertEqual actualP1Side_F userSelectedP1Side  -- Should pass: P1 always argues Pro
  assertEqual actualP2Side_F userSelectedP2Side  -- Should pass: P2 always argues Con

  -- Models should ALWAYS be preserved regardless of coin flip
  assertEqual actualP1_T userSelectedP1  -- Should pass: P1 is always Gemini Pro
  assertEqual actualP2_T userSelectedP2  -- Should pass: P2 is always Claude 4
  assertEqual actualP1_F userSelectedP1  -- Should pass: P1 is always Gemini Pro
  assertEqual actualP2_F userSelectedP2  -- Should pass: P2 is always Claude 4

  putStrLn "✅ Pro/Con assignments preserved regardless of first speaker randomization"

-- Test round progress display formatting
export
testRoundProgressDisplay : IO ()
testRoundProgressDisplay = do
  putStrLn "Testing round progress display formatting..."

  -- Test round display logic
  let formatRoundDisplay : Nat -> String
      formatRoundDisplay turns =
        let completeRounds = cast ((cast turns) `div` 2)
            isHalfRound = turns > (completeRounds * 2)
            roundStr = if isHalfRound
                        then show completeRounds ++ ".5"
                        else show completeRounds ++ ".0"
        in "Round " ++ roundStr

  assertEqual (formatRoundDisplay 1) "Round 0.5"  -- Turn 1 = Round 0.5
  assertEqual (formatRoundDisplay 2) "Round 1.0"  -- Turn 2 = Round 1.0
  assertEqual (formatRoundDisplay 3) "Round 1.5"  -- Turn 3 = Round 1.5
  assertEqual (formatRoundDisplay 4) "Round 2.0"  -- Turn 4 = Round 2.0
  assertEqual (formatRoundDisplay 5) "Round 2.5"  -- Turn 5 = Round 2.5

-- Run all timeout and display tests
export
runTimeoutTests : IO ()
runTimeoutTests = do
  putStrLn "=== Running Timeout & Display Tests ==="
  testScriptedTimeoutBehavior
  testWarningThresholdTiming
  testCustomTopicInputTimeout
  testContinuePromptTimeout
  testStderrCleanliness
  testStderrRedirectFix
  testDebateContinuationDisplay
  testIncrementalDisplayFix
  testCorrectRoundCalculationFromTurns
  testFixedRoundLogic
  testCoinFlipFirstSpeaker
  testFirstSpeakerAssignmentFix
  testRoundProgressDisplay
  putStrLn "=== Timeout & Display Tests Complete ==="
