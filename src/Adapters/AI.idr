module Adapters.AI

import Adapters.HTTP
import Core.Types
import Data.String
import System

-- Helper function to find position of substring
findSubstring : String -> String -> Maybe Nat
findSubstring needle haystack = findSubstringHelper 0 needle haystack
  where
    findSubstringHelper : Nat -> String -> String -> Maybe Nat
    findSubstringHelper pos needle haystack =
      if length haystack < length needle
        then Nothing
        else if isPrefixOf needle haystack
          then Just pos
          else case unpack haystack of
                 [] => Nothing
                 (_ :: rest) => findSubstringHelper (pos + 1) needle (pack rest)

-- Helper function to extract JSON string value after a pattern
findJSONString : String -> String -> Maybe String
findJSONString pattern text =
  case findSubstring pattern text of
    Nothing => Nothing
    Just pos =>
      let afterPattern = substr (cast (pos + length pattern)) (length text) text
          -- Skip any whitespace and find the opening quote
          trimmed = ltrim afterPattern
      in case unpack trimmed of
           ('"' :: rest) => Just (extractUntilQuote "" rest)
           _ => Nothing
  where
    -- Extract content until closing quote, handling basic escapes
    extractUntilQuote : String -> List Char -> String
    extractUntilQuote acc [] = acc
    extractUntilQuote acc ('"' :: _) = acc  -- Found closing quote
    extractUntilQuote acc ('\\' :: '"' :: rest) = extractUntilQuote (acc ++ "\"") rest  -- Escaped quote
    extractUntilQuote acc ('\\' :: 'n' :: rest) = extractUntilQuote (acc ++ "\n") rest  -- Escaped newline
    extractUntilQuote acc ('\\' :: 'r' :: rest) = extractUntilQuote (acc ++ "\r") rest  -- Escaped carriage return
    extractUntilQuote acc ('\\' :: '\\' :: rest) = extractUntilQuote (acc ++ "\\") rest  -- Escaped backslash
    extractUntilQuote acc (c :: rest) = extractUntilQuote (acc ++ singleton c) rest

-- AI client implementation using HTTP
public export
RealAIClient : HTTPClient => Type
RealAIClient = ()

-- Get API endpoint for model
public export
getAPIEndpoint : AIModel -> String
getAPIEndpoint ChatGPT4o = "https://api.openai.com/v1/chat/completions"
getAPIEndpoint ChatGPT4_1 = "https://api.openai.com/v1/chat/completions"
getAPIEndpoint ChatGPT4_5 = "https://api.openai.com/v1/chat/completions"
getAPIEndpoint ChatGPTo3 = "https://api.openai.com/v1/chat/completions"
getAPIEndpoint ChatGPTo4Mini = "https://api.openai.com/v1/chat/completions"
getAPIEndpoint GeminiPro = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"
getAPIEndpoint GeminiFlash = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"
getAPIEndpoint Claude4 = "https://api.anthropic.com/v1/messages"
getAPIEndpoint Grok = "https://api.x.ai/v1/chat/completions"
getAPIEndpoint GroqLlama = "https://api.groq.com/openai/v1/chat/completions"
getAPIEndpoint OllamaLocal = "http://localhost:11434/api/chat"

-- Get environment variable name for API key
public export
getAPIKeyVar : AIModel -> String
getAPIKeyVar ChatGPT4o = "OPENAI_API_KEY"
getAPIKeyVar ChatGPT4_1 = "OPENAI_API_KEY"
getAPIKeyVar ChatGPT4_5 = "OPENAI_API_KEY"
getAPIKeyVar ChatGPTo3 = "OPENAI_API_KEY"
getAPIKeyVar ChatGPTo4Mini = "OPENAI_API_KEY"
getAPIKeyVar GeminiPro = "GOOGLE_GEMINI_API_KEY"
getAPIKeyVar GeminiFlash = "GOOGLE_GEMINI_API_KEY"
getAPIKeyVar Claude4 = "ANTHROPIC_API_KEY"
getAPIKeyVar Grok = "GROK_API_KEY"
getAPIKeyVar GroqLlama = "GROQ_API_KEY"
getAPIKeyVar OllamaLocal = "OLLAMA_API_KEY"

-- Get environment variable name for default model selection
public export
getDefaultModelVar : AIModel -> String
getDefaultModelVar ChatGPT4o = "OPENAI_DEFAULT_MODEL"
getDefaultModelVar ChatGPT4_1 = "OPENAI_DEFAULT_MODEL"
getDefaultModelVar ChatGPT4_5 = "OPENAI_DEFAULT_MODEL"
getDefaultModelVar ChatGPTo3 = "OPENAI_DEFAULT_MODEL"
getDefaultModelVar ChatGPTo4Mini = "OPENAI_DEFAULT_MODEL"
getDefaultModelVar GeminiPro = "GOOGLE_DEFAULT_MODEL"
getDefaultModelVar GeminiFlash = "GOOGLE_DEFAULT_MODEL"
getDefaultModelVar Claude4 = "ANTHROPIC_DEFAULT_MODEL"
getDefaultModelVar Grok = "GROK_DEFAULT_MODEL"
getDefaultModelVar GroqLlama = "GROQ_DEFAULT_MODEL"
getDefaultModelVar OllamaLocal = "OLLAMA_DEFAULT_MODEL"

-- Get default model name (for Ollama, this could be "llama3.3:70b", "mistral", etc.)
public export
getDefaultModelName : AIModel -> String
getDefaultModelName ChatGPT4o = "gpt-4o"
getDefaultModelName ChatGPT4_1 = "gpt-4-turbo"
getDefaultModelName ChatGPT4_5 = "gpt-4"
getDefaultModelName ChatGPTo3 = "o3-mini"
getDefaultModelName ChatGPTo4Mini = "gpt-4o-mini"
getDefaultModelName GeminiPro = "gemini-2.0-flash-exp"
getDefaultModelName GeminiFlash = "gemini-2.0-flash-exp"
getDefaultModelName Claude4 = "claude-3-5-sonnet-20241022"
getDefaultModelName Grok = "grok-3"
getDefaultModelName GroqLlama = "llama-3.1-70b-versatile"
getDefaultModelName OllamaLocal = "llama3.3:70b"

-- Get environment variable name for context length
public export
getContextLengthVar : AIModel -> String
getContextLengthVar ChatGPT4o = "OPENAI_CONTEXT_LENGTH"
getContextLengthVar ChatGPT4_1 = "OPENAI_CONTEXT_LENGTH"
getContextLengthVar ChatGPT4_5 = "OPENAI_CONTEXT_LENGTH"
getContextLengthVar ChatGPTo3 = "OPENAI_CONTEXT_LENGTH"
getContextLengthVar ChatGPTo4Mini = "OPENAI_CONTEXT_LENGTH"
getContextLengthVar GeminiPro = "GOOGLE_CONTEXT_LENGTH"
getContextLengthVar GeminiFlash = "GOOGLE_CONTEXT_LENGTH"
getContextLengthVar Claude4 = "ANTHROPIC_CONTEXT_LENGTH"
getContextLengthVar Grok = "GROK_CONTEXT_LENGTH"
getContextLengthVar GroqLlama = "GROQ_CONTEXT_LENGTH"
getContextLengthVar OllamaLocal = "OLLAMA_CONTEXT_LENGTH"

-- Get default context length for each provider
public export
getDefaultContextLength : AIModel -> Nat
getDefaultContextLength ChatGPT4o = 128000
getDefaultContextLength ChatGPT4_1 = 128000
getDefaultContextLength ChatGPT4_5 = 8192
getDefaultContextLength ChatGPTo3 = 65536
getDefaultContextLength ChatGPTo4Mini = 128000
getDefaultContextLength GeminiPro = 1048576
getDefaultContextLength GeminiFlash = 1048576
getDefaultContextLength Claude4 = 200000
getDefaultContextLength Grok = 8192
getDefaultContextLength GroqLlama = 8192
getDefaultContextLength OllamaLocal = 16384

-- Get environment variable name for max response tokens
public export
getMaxResponseTokensVar : AIModel -> String
getMaxResponseTokensVar ChatGPT4o = "OPENAI_MAX_TOKENS"
getMaxResponseTokensVar ChatGPT4_1 = "OPENAI_MAX_TOKENS"
getMaxResponseTokensVar ChatGPT4_5 = "OPENAI_MAX_TOKENS"
getMaxResponseTokensVar ChatGPTo3 = "OPENAI_MAX_TOKENS"
getMaxResponseTokensVar ChatGPTo4Mini = "OPENAI_MAX_TOKENS"
getMaxResponseTokensVar GeminiPro = "GOOGLE_MAX_TOKENS"
getMaxResponseTokensVar GeminiFlash = "GOOGLE_MAX_TOKENS"
getMaxResponseTokensVar Claude4 = "ANTHROPIC_MAX_TOKENS"
getMaxResponseTokensVar Grok = "GROK_MAX_TOKENS"
getMaxResponseTokensVar GroqLlama = "GROQ_MAX_TOKENS"
getMaxResponseTokensVar OllamaLocal = "OLLAMA_MAX_TOKENS"

-- Get default max response tokens for each provider
public export
getDefaultMaxResponseTokens : AIModel -> Nat
getDefaultMaxResponseTokens ChatGPT4o = 4000
getDefaultMaxResponseTokens ChatGPT4_1 = 4000
getDefaultMaxResponseTokens ChatGPT4_5 = 2000
getDefaultMaxResponseTokens ChatGPTo3 = 4000
getDefaultMaxResponseTokens ChatGPTo4Mini = 2000
getDefaultMaxResponseTokens GeminiPro = 8192
getDefaultMaxResponseTokens GeminiFlash = 8192
getDefaultMaxResponseTokens Claude4 = 3000
getDefaultMaxResponseTokens Grok = 2000
getDefaultMaxResponseTokens GroqLlama = 2000
getDefaultMaxResponseTokens OllamaLocal = 2000

-- Parse a positive integer from string
parsePositive : String -> Maybe Nat
parsePositive str =
  case parseInteger str of
    Nothing => Nothing
    Just n => if n > 0 then Just (cast n) else Nothing

-- Get actual context length from environment variable or default
public export
getContextLength : AIModel -> IO Nat
getContextLength model = do
  let envVar = getContextLengthVar model
  let defaultLength = getDefaultContextLength model
  maybeLength <- getEnvVar envVar
  case maybeLength of
    Nothing => pure defaultLength
    Just lengthStr => case parsePositive lengthStr of
      Nothing => pure defaultLength
      Just length => pure length

-- Get actual max response tokens from environment variable or default
public export
getMaxResponseTokens : AIModel -> IO Nat
getMaxResponseTokens model = do
  let envVar = getMaxResponseTokensVar model
  let defaultTokens = getDefaultMaxResponseTokens model
  maybeTokens <- getEnvVar envVar
  case maybeTokens of
    Nothing => pure defaultTokens
    Just tokensStr => case parsePositive tokensStr of
      Nothing => pure defaultTokens
      Just tokens => pure tokens

-- Create HTTP headers for API call
public export
createHeaders : AIModel -> String -> List (String, String)
createHeaders ChatGPT4o apiKey = [("Authorization", "Bearer " ++ apiKey), ("Content-Type", "application/json")]
createHeaders ChatGPT4_1 apiKey = [("Authorization", "Bearer " ++ apiKey), ("Content-Type", "application/json")]
createHeaders ChatGPT4_5 apiKey = [("Authorization", "Bearer " ++ apiKey), ("Content-Type", "application/json")]
createHeaders ChatGPTo3 apiKey = [("Authorization", "Bearer " ++ apiKey), ("Content-Type", "application/json")]
createHeaders ChatGPTo4Mini apiKey = [("Authorization", "Bearer " ++ apiKey), ("Content-Type", "application/json")]
createHeaders GeminiPro apiKey = [("x-goog-api-key", apiKey), ("Content-Type", "application/json")]
createHeaders GeminiFlash apiKey = [("x-goog-api-key", apiKey), ("Content-Type", "application/json")]
createHeaders Claude4 apiKey = [("x-api-key", apiKey), ("anthropic-version", "2023-06-01"), ("Content-Type", "application/json")]
createHeaders Grok apiKey = [("Authorization", "Bearer " ++ apiKey), ("Content-Type", "application/json")]
createHeaders GroqLlama apiKey = [("Authorization", "Bearer " ++ apiKey), ("Content-Type", "application/json")]
createHeaders OllamaLocal apiKey = [("Content-Type", "application/json")]

-- Simple JSON escaping
escapeJSON : String -> String
escapeJSON s =
  let chars = unpack s
      escapeChar : Char -> String
      escapeChar '"' = "\\\""
      escapeChar '\n' = "\\n"
      escapeChar '\r' = "\\r"
      escapeChar c = singleton c
  in concat (map escapeChar chars)

-- Create request body for API call (synchronous version with default values)
public export
createRequestBody : AIModel -> String -> String
createRequestBody ChatGPT4o prompt =
  "{\"model\":\"gpt-4o\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":4000}"
createRequestBody ChatGPT4_1 prompt =
  "{\"model\":\"gpt-4-turbo\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":4000}"
createRequestBody ChatGPT4_5 prompt =
  "{\"model\":\"gpt-4\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":2000}"
createRequestBody ChatGPTo3 prompt =
  "{\"model\":\"o3-mini\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_completion_tokens\":4000}"
createRequestBody ChatGPTo4Mini prompt =
  "{\"model\":\"gpt-4o-mini\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":2000}"
createRequestBody GeminiPro prompt =
  "{\"contents\":[{\"parts\":[{\"text\":\"" ++ escapeJSON prompt ++ "\"}]}],\"generationConfig\":{\"maxOutputTokens\":3000}}"
createRequestBody GeminiFlash prompt =
  "{\"contents\":[{\"parts\":[{\"text\":\"" ++ escapeJSON prompt ++ "\"}]}],\"generationConfig\":{\"maxOutputTokens\":8192}}"
createRequestBody Claude4 prompt =
  "{\"model\":\"claude-3-5-sonnet-20241022\",\"max_tokens\":3000,\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}]}"
createRequestBody Grok prompt =
  "{\"model\":\"grok-3\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":2000}"
createRequestBody GroqLlama prompt =
  "{\"model\":\"llama-3.1-70b-versatile\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":2000}"
createRequestBody OllamaLocal prompt =
  "{\"model\":\"llama3.3:70b\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"stream\":false}"

-- Create request body with configurable model name, context length, and max tokens
public export
createRequestBodyWithConfig : AIModel -> String -> String -> Nat -> Nat -> String
createRequestBodyWithConfig ChatGPT4o prompt modelName contextLength maxTokens =
  "{\"model\":\"" ++ modelName ++ "\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":" ++ show maxTokens ++ "}"
createRequestBodyWithConfig ChatGPT4_1 prompt modelName contextLength maxTokens =
  "{\"model\":\"" ++ modelName ++ "\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":" ++ show maxTokens ++ "}"
createRequestBodyWithConfig ChatGPT4_5 prompt modelName contextLength maxTokens =
  "{\"model\":\"" ++ modelName ++ "\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":" ++ show maxTokens ++ "}"
createRequestBodyWithConfig ChatGPTo3 prompt modelName contextLength maxTokens =
  "{\"model\":\"" ++ modelName ++ "\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_completion_tokens\":" ++ show maxTokens ++ "}"
createRequestBodyWithConfig ChatGPTo4Mini prompt modelName contextLength maxTokens =
  "{\"model\":\"" ++ modelName ++ "\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":" ++ show maxTokens ++ "}"
createRequestBodyWithConfig GeminiPro prompt modelName contextLength maxTokens =
  "{\"contents\":[{\"parts\":[{\"text\":\"" ++ escapeJSON prompt ++ "\"}]}],\"generationConfig\":{\"maxOutputTokens\":" ++ show maxTokens ++ "}}"
createRequestBodyWithConfig GeminiFlash prompt modelName contextLength maxTokens =
  "{\"contents\":[{\"parts\":[{\"text\":\"" ++ escapeJSON prompt ++ "\"}]}],\"generationConfig\":{\"maxOutputTokens\":" ++ show maxTokens ++ "}}"
createRequestBodyWithConfig Claude4 prompt modelName contextLength maxTokens =
  "{\"model\":\"" ++ modelName ++ "\",\"max_tokens\":" ++ show maxTokens ++ ",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}]}"
createRequestBodyWithConfig Grok prompt modelName contextLength maxTokens =
  "{\"model\":\"" ++ modelName ++ "\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":" ++ show maxTokens ++ "}"
createRequestBodyWithConfig GroqLlama prompt modelName contextLength maxTokens =
  "{\"model\":\"" ++ modelName ++ "\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"max_tokens\":" ++ show maxTokens ++ "}"
createRequestBodyWithConfig OllamaLocal prompt modelName contextLength maxTokens =
  "{\"model\":\"" ++ modelName ++ "\",\"messages\":[{\"role\":\"user\",\"content\":\"" ++ escapeJSON prompt ++ "\"}],\"stream\":false,\"options\":{\"num_predict\":" ++ show maxTokens ++ "}}"

-- Get model name from environment variable or default
public export
getModelName : AIModel -> IO String
getModelName model = do
  let envVar = getDefaultModelVar model
  let defaultName = getDefaultModelName model
  maybeName <- getEnvVar envVar
  case maybeName of
    Nothing => pure defaultName
    Just name => pure name

-- Extract content from API response (basic JSON parsing)
public export
extractContent : AIModel -> String -> Either String String
extractContent ChatGPT4o response =
  -- Look for "content": pattern in OpenAI response
  case findJSONString "\"content\":" response of
    Just content => Right content
    Nothing => Left "Could not extract content from OpenAI response"
extractContent ChatGPT4_1 response =
  -- Look for "content": pattern in OpenAI response
  case findJSONString "\"content\":" response of
    Just content => Right content
    Nothing => Left "Could not extract content from OpenAI response"
extractContent ChatGPT4_5 response =
  -- Look for "content": pattern in OpenAI response
  case findJSONString "\"content\":" response of
    Just content => Right content
    Nothing => Left "Could not extract content from OpenAI response"
extractContent ChatGPTo3 response =
  -- Look for "content": pattern in OpenAI response
  case findJSONString "\"content\":" response of
    Just content => Right content
    Nothing => Left "Could not extract content from OpenAI response"
extractContent ChatGPTo4Mini response =
  -- Look for "content": pattern in OpenAI response
  case findJSONString "\"content\":" response of
    Just content => Right content
    Nothing => Left "Could not extract content from OpenAI response"
extractContent GeminiPro response =
  -- Look for "text": pattern in Gemini response
  case findJSONString "\"text\":" response of
    Just content => Right content
    Nothing => Left "Could not extract content from Gemini response"
extractContent GeminiFlash response =
  -- Look for "text": pattern in Gemini response
  case findJSONString "\"text\":" response of
    Just content => Right content
    Nothing => Left "Could not extract content from Gemini response"
extractContent Claude4 response =
  -- Look for "text": pattern in Claude response
  case findJSONString "\"text\":" response of
    Just content => Right content
    Nothing => Left "Could not extract content from Claude response"
extractContent Grok response =
  -- Look for "content": pattern in Grok response (OpenAI-compatible)
  case findJSONString "\"content\":" response of
    Just content => Right content
    Nothing => Left "Could not extract content from Grok response"
extractContent GroqLlama response =
  -- Look for "content": pattern in Groq response (OpenAI-compatible)
  case findJSONString "\"content\":" response of
    Just content => Right content
    Nothing => Left "Could not extract content from Groq response"
extractContent OllamaLocal response =
  -- Look for "content": pattern in Ollama response (OpenAI-compatible)
  case findJSONString "\"content\":" response of
    Just content => Right content
    Nothing => Left "Could not extract content from Ollama response"

-- Parse API response
public export
parseAPIResponse : AIModel -> HTTPResponse -> Either APIError AIResponse
parseAPIResponse model response =
  if response.statusCode >= 400
    then Left (NetworkError ("HTTP " ++ show response.statusCode ++ ": " ++ response.body))
    else case extractContent model response.body of
      Left err => Left (ParseError err)
      Right content => Right (MkAIResponse content model 100)

-- Real AI client implementation
public export
realGenerateResponse : HTTPClient => AIModel -> String -> IO (Either APIError AIResponse)
realGenerateResponse model prompt = do
  maybeKey <- getEnvVar (getAPIKeyVar model)
  case maybeKey of
    Nothing => pure (Left (AuthError ("Missing API key for " ++ show model)))
    Just apiKey => do
      let endpoint = getAPIEndpoint model
      let headers = createHeaders model apiKey
      let body = createRequestBody model prompt
      result <- httpPost endpoint headers body
      case result of
        Left err => pure (Left (NetworkError err))
        Right httpResponse => pure (parseAPIResponse model httpResponse)

-- Real AI client test connection
public export
realTestConnection : HTTPClient => AIModel -> IO (Either APIError Bool)
realTestConnection model = do
  result <- realGenerateResponse model "Hello"
  case result of
    Left (AuthError _) => pure (Left (AuthError ("Invalid API key for " ++ show model)))
    Left err => pure (Left err)
    Right _ => pure (Right True)

-- Instance of AIClient using real HTTP calls
public export
HTTPClient => AIClient where
  generateResponse = realGenerateResponse
  testConnection = realTestConnection
