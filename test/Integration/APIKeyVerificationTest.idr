module Integration.APIKeyVerificationTest

import System
import Data.String
import Adapters.HTTP
import Adapters.AI
import Core.Types

-- Simple test request that verifies API key is accepted
-- Uses minimal prompts to avoid consuming tokens unnecessarily
testAPIKey : HTTPClient => AIModel -> IO (Either String String)
testAPIKey model = do
  putStrLn ("🔑 Testing " ++ show model ++ " API key...")
  
  -- Use a very simple prompt to minimize token usage
  let testPrompt = "Hi"
  
  result <- generateResponse model testPrompt
  case result of
    Left err => do
      putStrLn ("❌ " ++ show model ++ " failed: " ++ show err)
      pure (Left (show err))
    Right response => do
      let responsePreview = if length response.content > 50 
                           then substr 0 50 response.content ++ "..."
                           else response.content
      putStrLn ("✅ " ++ show model ++ " working: \"" ++ responsePreview ++ "\"")
      pure (Right responsePreview)

-- Helper to test a model and return the result pair
testModelPair : HTTPClient => (AIModel, String) -> IO (AIModel, Either String String)
testModelPair (model, _) = do
  result <- testAPIKey model
  pure (model, result)

-- Test all available API keys
testAllAvailableAPIKeys : HTTPClient => IO (List (AIModel, Either String String))
testAllAvailableAPIKeys = do
  putStrLn "🧪 API Key Verification Test"
  putStrLn "============================="
  putStrLn ""
  
  -- Check which API keys are available
  openaiKey <- getEnv "OPENAI_API_KEY"
  anthropicKey <- getEnv "ANTHROPIC_API_KEY"
  geminiKey <- getEnv "GOOGLE_GEMINI_API_KEY"
  grokKey <- getEnv "GROK_API_KEY"
  groqKey <- getEnv "GROQ_API_KEY" 
  openrouterKey <- getEnv "OPENROUTER_API_KEY"
  
  let availableModels = catMaybes [
    map (\_ => (ChatGPT4o, "OPENAI_API_KEY")) openaiKey,
    map (\_ => (Claude4, "ANTHROPIC_API_KEY")) anthropicKey,
    map (\_ => (GeminiPro, "GOOGLE_GEMINI_API_KEY")) geminiKey,
    map (\_ => (Grok, "GROK_API_KEY")) grokKey,
    map (\_ => (GroqLlama, "GROQ_API_KEY")) groqKey,
    map (\_ => (OpenRouterGPT4o, "OPENROUTER_API_KEY")) openrouterKey
  ]
  
  if null availableModels
    then do
      putStrLn "⚠️  No API keys found in environment variables"
      putStrLn ""
      putStrLn "Please set at least one of these environment variables:"
      putStrLn "  - OPENAI_API_KEY"
      putStrLn "  - ANTHROPIC_API_KEY" 
      putStrLn "  - GOOGLE_GEMINI_API_KEY"
      putStrLn "  - GROK_API_KEY"
      putStrLn "  - GROQ_API_KEY"
      putStrLn "  - OPENROUTER_API_KEY"
      pure []
    else do
      putStrLn ("Found " ++ show (length availableModels) ++ " API key(s) to test:")
      traverse_ (\(model, keyName) => putStrLn ("  ✓ " ++ keyName ++ " -> " ++ show model)) availableModels
      putStrLn ""
      
      -- Test each available model
      results <- traverse testModelPair availableModels
      
      putStrLn ""
      putStrLn "📊 Test Summary:"
      putStrLn "================="
      
      let successes = length (filter (\(_, result) => case result of Right _ => True; Left _ => False) results)
      let failures = length (filter (\(_, result) => case result of Left _ => True; Right _ => False) results)
      
      putStrLn ("✅ Working: " ++ show successes)
      putStrLn ("❌ Failed:  " ++ show failures)
      
      if failures > 0
        then do
          putStrLn ""
          putStrLn "💡 Troubleshooting failed API keys:"
          putStrLn "   1. Check that API keys are correctly set in environment"
          putStrLn "   2. Verify API keys are valid (not expired/revoked)"
          putStrLn "   3. Ensure your account has sufficient credits/quota"
          putStrLn "   4. Check network connectivity"
        else pure ()
      
      pure results
  where
    catMaybes : List (Maybe a) -> List a
    catMaybes [] = []
    catMaybes (Nothing :: xs) = catMaybes xs
    catMaybes (Just x :: xs) = x :: catMaybes xs

-- Main test function
export
runAPIKeyVerificationTest : HTTPClient => IO Bool
runAPIKeyVerificationTest = do
  results <- testAllAvailableAPIKeys
  
  if null results
    then do
      putStrLn ""
      putStrLn "⚠️  No API keys to test - this is not a failure, just no configuration"
      pure True  -- Not a test failure, just no keys configured
    else do
      let allSuccessful = all (\(_, result) => case result of Right _ => True; Left _ => False) results
      putStrLn ""
      if allSuccessful
        then putStrLn "🎉 All configured API keys are working!"
        else putStrLn "⚠️  Some API keys failed verification"
      pure allSuccessful