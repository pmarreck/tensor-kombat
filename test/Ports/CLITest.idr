module Ports.CLITest

import Ports.CLI
import Core.Types
import Data.String
import Data.List1
import System

-- Test framework helper
export
assertEqual : (Show a, Eq a) => String -> a -> a -> IO ()
assertEqual testName expected actual =
  if expected == actual
    then putStrLn ("✅ " ++ testName ++ ": PASS")
    else do
      putStrLn ("❌ " ++ testName ++ ": FAIL")
      putStrLn ("  Expected: " ++ show expected)
      putStrLn ("  Actual: " ++ show actual)

-- Test model name to model conversion
export
testNameToModel : IO ()
testNameToModel = do
  putStrLn "=== Testing Name to Model Conversion ==="

  assertEqual "ChatGPT 4o conversion" (Just ChatGPT4o) (nameToModel "ChatGPT 4o")
  assertEqual "ChatGPT 4.1 conversion" (Just ChatGPT4_1) (nameToModel "ChatGPT 4.1")
  assertEqual "ChatGPT 4.5 conversion" (Just ChatGPT4_5) (nameToModel "ChatGPT 4.5")
  assertEqual "ChatGPT o3 conversion" (Just ChatGPTo3) (nameToModel "ChatGPT o3")
  assertEqual "ChatGPT 4o Mini conversion" (Just ChatGPTo4Mini) (nameToModel "ChatGPT 4o Mini")
  assertEqual "Claude 4 conversion" (Just Claude4) (nameToModel "Claude 4")
  assertEqual "Gemini Pro conversion" (Just GeminiPro) (nameToModel "Gemini Pro")
  assertEqual "Gemini Flash conversion" (Just GeminiFlash) (nameToModel "Gemini Flash")
  assertEqual "Grok conversion" (Just Grok) (nameToModel "Grok")
  assertEqual "Groq Llama conversion" (Just GroqLlama) (nameToModel "Groq Llama")
  assertEqual "Invalid model conversion" Nothing (nameToModel "Invalid Model")

-- Test model selection processing (the core of the Claude bug fix)
export
testModelSelectionProcessing : IO ()
testModelSelectionProcessing = do
  putStrLn "=== Testing Model Selection Processing ==="

  let options = getModelOptions

  -- Test valid selection (the Claude bug scenario)
  case processModelSelection options "ChatGPT 4o" "Claude 4" "Gemini Flash" of
    Nothing => putStrLn "❌ Valid selection returned Nothing"
    Just (p1, p2, judge) => do
      assertEqual "Participant 1 model" ChatGPT4o p1
      assertEqual "Participant 2 model" Claude4 p2
      assertEqual "Judge model" GeminiFlash judge

      -- Critical test: ensure Claude is preserved
      if p2 == Claude4
        then putStrLn "✅ Claude selection preserved: PASS"
        else putStrLn ("❌ Claude selection lost: got " ++ show p2)

      -- Ensure participants are different
      if p1 /= p2
        then putStrLn "✅ Participants are different: PASS"
        else putStrLn "❌ Participants are the same: FAIL"

  -- Test invalid selections
  case processModelSelection options "Invalid Model" "Claude 4" "Gemini Pro" of
    Nothing => putStrLn "✅ Invalid P1 correctly rejected: PASS"
    Just _ => putStrLn "❌ Invalid P1 should be rejected: FAIL"

-- Test selection count validation (another bug fix)
export
testSelectionCountValidation : IO ()
testSelectionCountValidation = do
  putStrLn "=== Testing Selection Count Validation ==="

  -- Test insufficient selections (the bug scenario)
  let insufficientSelections = ["Yes", "AI Topic", "ChatGPT 4o", "Claude 4"]
  let sufficientSelections = ["Yes", "AI Topic", "ChatGPT 4o", "Claude 4", "Gemini Flash"]

  putStrLn ("Insufficient selections count: " ++ show (length insufficientSelections))
  putStrLn ("Sufficient selections count: " ++ show (length sufficientSelections))

  -- Test selection fallback behavior
  let state1 = MkSelectionState insufficientSelections 0 "0.01s"
  let state2 = MkSelectionState sufficientSelections 0 "0.01s"
  let options = getModelOptions

  -- Use up all insufficient selections
  let (_, s1) = getNextSelection state1 ["Yes", "No"]
  let (_, s2) = getNextSelection s1 ["AI Topic", "Other"]
  let (_, s3) = getNextSelection s2 options
  let (_, s4) = getNextSelection s3 options
  let (fallback, _) = getNextSelection s4 options  -- This should fallback

  putStrLn ("Fallback selection: " ++ fallback)
  case options of
    (first :: _) =>
      if fallback == first
        then putStrLn "✅ Fallback to first option: PASS"
        else putStrLn "❌ Unexpected fallback behavior: FAIL"
    [] => putStrLn "❌ No model options available"

-- Test topic selection improvements
export
testTopicSelection : IO ()
testTopicSelection = do
  putStrLn "=== Testing Topic Selection ==="

  -- Test that stock topics are properly formatted
  let stockTopics = [
    "Should social media platforms prioritize free speech over content moderation?",
    "Will AI eventually surpass human intelligence in most domains?",
    "Should nuclear energy be prioritized over renewable energy sources?"
  ]

  -- Check pro/con clarity
  traverse_ checkTopicClarity stockTopics

  where
    checkTopicClarity : String -> IO ()
    checkTopicClarity topic = do
      if isInfixOf "Should" topic || isInfixOf "Will" topic || isInfixOf "Is" topic
        then putStrLn ("✅ Clear pro/con topic: " ++ substr 0 50 topic ++ "...")
        else putStrLn ("⚠️  Ambiguous topic: " ++ substr 0 50 topic ++ "...")

-- Test debate participant creation
export
testDebateParticipantCreation : IO ()
testDebateParticipantCreation = do
  putStrLn "=== Testing Debate Participant Creation ==="

  let participant1 = MkParticipant ChatGPT4o Pro "ChatGPT Pro"
  let participant2 = MkParticipant Claude4 Con "Claude Con"

  assertEqual "Participant 1 model" ChatGPT4o participant1.model
  assertEqual "Participant 1 side" Pro participant1.side
  assertEqual "Participant 2 model" Claude4 participant2.model
  assertEqual "Participant 2 side" Con participant2.side

  -- Ensure participants have different models and sides
  if participant1.model /= participant2.model
    then putStrLn "✅ Participants have different models: PASS"
    else putStrLn "❌ Participants have same model: FAIL"

  if participant1.side /= participant2.side
    then putStrLn "✅ Participants have different sides: PASS"
    else putStrLn "❌ Participants have same side: FAIL"

-- Main test runner for CLI/Ports tests
export
runCLITests : IO ()
runCLITests = do
  putStrLn "🧪 Running CLI/Ports Tests"
  putStrLn "=========================="
  testNameToModel
  testModelSelectionProcessing
  testSelectionCountValidation
  testTopicSelection
  testDebateParticipantCreation
  putStrLn "=== CLI/Ports Tests Complete ==="
