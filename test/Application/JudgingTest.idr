module Application.JudgingTest

import Application.Judging
import Core.Types
import Data.List
import Data.String

-- Simple test framework
assertEqual : Eq a => Show a => String -> a -> a -> IO ()
assertEqual testName given expected =
  if given == expected
    then putStrLn ("✓ " ++ testName ++ ": PASS")
    else do
      putStrLn ("✗ " ++ testName ++ ": FAIL")
      putStrLn ("  Expected: " ++ show expected)
      putStrLn ("  Got:      " ++ show given)

-- Test that score parsing actually parses real values instead of returning hardcoded ones
testScoreParsingNotHardcoded : IO ()
testScoreParsingNotHardcoded = do
  putStrLn "=== Testing Real Score Parsing (No Hardcoded Values) ==="

  -- Test case 1: Different scores should produce different results
  let scoreLine1 = "PARTICIPANT1 (Claude 4 (Pro)): R=8.5 Q=8.0 E=7.5 C=8.0"
  let scoreLine2 = "PARTICIPANT1 (Claude 4 (Pro)): R=6.0 Q=5.5 E=6.5 C=7.0"
  let participant1 = MkParticipant Claude4 Pro "Participant 1"
  let participant2 = MkParticipant ChatGPT4o Con "Participant 2"

  case (parseScoreLine participant1 participant2 scoreLine1, parseScoreLine participant1 participant2 scoreLine2) of
    (Right score1, Right score2) => do
      -- These should be different if parsing is real
      if score1.criteria == score2.criteria
        then putStrLn "✗ HARDCODED VALUES DETECTED: Different input produced identical scores"
        else putStrLn "✓ Real parsing: Different inputs produce different scores"

      -- Test that total matches breakdown
      let expectedTotal1 = 8.5 + 8.0 + 7.5 + 8.0  -- 32.0
      let expectedTotal2 = 6.0 + 5.5 + 6.5 + 7.0  -- 25.0

      assertEqual "Score1 total matches breakdown" score1.totalScore expectedTotal1
      assertEqual "Score2 total matches breakdown" score2.totalScore expectedTotal2

      -- Test participant names are not hardcoded
      assertEqual "Participant1 name not hardcoded" score1.participant.name "Participant 1"

    (Left err1, _) => putStrLn ("✗ Failed to parse scoreLine1: " ++ show err1)
    (_, Left err2) => putStrLn ("✗ Failed to parse scoreLine2: " ++ show err2)

-- Test PARTICIPANT2 parsing
testParticipant2Parsing : IO ()
testParticipant2Parsing = do
  putStrLn "=== Testing PARTICIPANT2 Parsing ==="

  let scoreLine = "PARTICIPANT2 (Gemini Pro (Con)): R=7.0 Q=8.5 E=6.0 C=9.0"
  let participant1 = MkParticipant Claude4 Pro "Participant 1"
  let participant2 = MkParticipant GeminiPro Con "Participant 2"

  case parseScoreLine participant1 participant2 scoreLine of
    Right score => do
      let expectedTotal = 7.0 + 8.5 + 6.0 + 9.0  -- 30.5
      assertEqual "PARTICIPANT2 total matches breakdown" score.totalScore expectedTotal
      assertEqual "PARTICIPANT2 name not hardcoded" score.participant.name "Participant 2"
      assertEqual "PARTICIPANT2 side" score.participant.side Con
    Left err => putStrLn ("✗ Failed to parse PARTICIPANT2: " ++ show err)

-- Test edge cases
testEdgeCases : IO ()
testEdgeCases = do
  putStrLn "=== Testing Edge Cases ==="

  -- Test with decimal scores
  let scoreLineDecimals = "PARTICIPANT1 (ChatGPT 4o (Pro)): R=8.5 Q=7.2 E=9.1 C=6.8"
  let testParticipant1 = MkParticipant ChatGPT4o Pro "Participant 1"
  let testParticipant2 = MkParticipant Claude4 Con "Participant 2"

  case parseScoreLine testParticipant1 testParticipant2 scoreLineDecimals of
    Right score => do
      let expectedTotal = 8.5 + 7.2 + 9.1 + 6.8  -- 31.6
      assertEqual "Decimal scores total" score.totalScore expectedTotal
    Left err => putStrLn ("✗ Failed to parse decimal scores: " ++ show err)

  -- Test invalid format should fail
  let invalidLine = "This is not a valid score line"
  case parseScoreLine testParticipant1 testParticipant2 invalidLine of
    Left _ => putStrLn "✓ Invalid format correctly rejected"
    Right _ => putStrLn "✗ Invalid format should have been rejected"

-- Run all judging tests
export
runJudgingTests : IO ()
runJudgingTests = do
  putStrLn "🧪 Running Application.Judging Tests"
  putStrLn "===================================="

  testScoreParsingNotHardcoded
  putStrLn ""

  testParticipant2Parsing
  putStrLn ""

  testEdgeCases
  putStrLn ""

  putStrLn "=== Application.Judging Tests Complete ==="
