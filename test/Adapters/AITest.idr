module Adapters.AITest

import Adapters.AI
import Core.Types
import Data.String
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

-- Mock API responses for testing
openaiResponse : String
openaiResponse = """
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "gpt-4",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Hello! This is a test response from OpenAI."
    },
    "finish_reason": "stop"
  }]
}
"""

claudeResponse : String
claudeResponse = """
{
  "id": "msg_123",
  "type": "message",
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "Hello! This is a test response from Claude."
    }
  ],
  "model": "claude-3-haiku-20240307"
}
"""

geminiResponse : String
geminiResponse = """
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "Hello! This is a test response from Gemini."
          }
        ],
        "role": "model"
      },
      "finishReason": "STOP"
    }
  ]
}
"""

-- Test JSON content extraction
export
testJSONExtraction : IO ()
testJSONExtraction = do
  putStrLn "=== Testing JSON Content Extraction ==="

  -- Test OpenAI response parsing
  case extractContent ChatGPT4o openaiResponse of
    Left err => do
      putStrLn ("❌ OpenAI extraction failed: " ++ err)
    Right content => do
      assertEqual "OpenAI content extraction" "Hello! This is a test response from OpenAI." content

  -- Test Claude response parsing
  case extractContent Claude4 claudeResponse of
    Left err => do
      putStrLn ("❌ Claude extraction failed: " ++ err)
    Right content => do
      assertEqual "Claude content extraction" "Hello! This is a test response from Claude." content

  -- Test Gemini response parsing
  case extractContent GeminiPro geminiResponse of
    Left err => do
      putStrLn ("❌ Gemini extraction failed: " ++ err)
    Right content => do
      assertEqual "Gemini content extraction" "Hello! This is a test response from Gemini." content

  -- Test Gemini Flash response parsing
  case extractContent GeminiFlash geminiResponse of
    Left err => do
      putStrLn ("❌ Gemini Flash extraction failed: " ++ err)
    Right content => do
      assertEqual "Gemini Flash content extraction" "Hello! This is a test response from Gemini." content

-- Test API endpoint configuration
export
testAPIEndpoints : IO ()
testAPIEndpoints = do
  putStrLn "=== Testing API Endpoints ==="

  assertEqual "ChatGPT4o endpoint" "https://api.openai.com/v1/chat/completions" (getAPIEndpoint ChatGPT4o)
  assertEqual "ChatGPT4_1 endpoint" "https://api.openai.com/v1/chat/completions" (getAPIEndpoint ChatGPT4_1)
  assertEqual "Claude4 endpoint" "https://api.anthropic.com/v1/messages" (getAPIEndpoint Claude4)
  assertEqual "GeminiPro endpoint" "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro-preview-06-05:generateContent" (getAPIEndpoint GeminiPro)
  assertEqual "GeminiFlash endpoint" "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent" (getAPIEndpoint GeminiFlash)

-- Test API key variable configuration
export
testAPIKeyVars : IO ()
testAPIKeyVars = do
  putStrLn "=== Testing API Key Variables ==="

  assertEqual "ChatGPT4o key var" "OPENAI_API_KEY" (getAPIKeyVar ChatGPT4o)
  assertEqual "ChatGPT4_1 key var" "OPENAI_API_KEY" (getAPIKeyVar ChatGPT4_1)
  assertEqual "Claude4 key var" "ANTHROPIC_API_KEY" (getAPIKeyVar Claude4)
  assertEqual "GeminiPro key var" "GOOGLE_GEMINI_API_KEY" (getAPIKeyVar GeminiPro)
  assertEqual "GeminiFlash key var" "GOOGLE_GEMINI_API_KEY" (getAPIKeyVar GeminiFlash)

-- Test request body creation
export
testRequestBodies : IO ()
testRequestBodies = do
  putStrLn "=== Testing Request Body Creation ==="

  let testPrompt = "Hello, world!"
  let openaiBody = createRequestBody ChatGPT4o testPrompt
  let claudeBody = createRequestBody Claude4 testPrompt
  let geminiFlashBody = createRequestBody GeminiFlash testPrompt
  let o3Body = createRequestBody ChatGPTo3 testPrompt

  -- Check that bodies contain expected elements
  if isInfixOf "gpt-4" openaiBody && isInfixOf testPrompt openaiBody
    then putStrLn "✅ OpenAI request body: PASS"
    else putStrLn "❌ OpenAI request body: FAIL"

  if isInfixOf "claude" claudeBody && isInfixOf testPrompt claudeBody
    then putStrLn "✅ Claude request body: PASS"
    else putStrLn "❌ Claude request body: FAIL"

  -- Test o3 model uses correct parameter
  if isInfixOf "o3-mini" o3Body && isInfixOf "max_completion_tokens" o3Body && isInfixOf testPrompt o3Body
    then putStrLn "✅ o3 request body uses max_completion_tokens: PASS"
    else putStrLn "❌ o3 request body missing max_completion_tokens: FAIL"

-- Main test runner for AI adapter tests
export
runAITests : IO ()
runAITests = do
  putStrLn "🧪 Running AI Adapter Tests"
  putStrLn "============================"
  testJSONExtraction
  testAPIEndpoints
  testAPIKeyVars
  testRequestBodies
  putStrLn "=== AI Adapter Tests Complete ==="
