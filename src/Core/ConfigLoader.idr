module Core.ConfigLoader

import Core.Config
import System.Environment (getEnvVar)
import Data.String (parsePositive) -- For parsing String to Nat
import Basics (Nat)
import Maybe

%access public export

-- Helper function to get an environment variable and parse it as a Nat
getEnvNat : String -> IO (Maybe Nat)
getEnvNat varName = do
  maybeStr <- getEnvVar varName
  pure $ case maybeStr of
    Nothing => Nothing
    Just s => parsePositive s

-- Loads all application configuration from environment variables
public export
loadAppConfig : IO AppConfig
loadAppConfig = do
  -- API Keys
  apiKeyOpenAI <- getEnvVar "OPENAI_API_KEY"
  apiKeyAnthropic <- getEnvVar "ANTHROPIC_API_KEY"
  apiKeyGoogleGemini <- getEnvVar "GOOGLE_GEMINI_API_KEY"
  apiKeyGrok <- getEnvVar "GROK_API_KEY"
  apiKeyGroq <- getEnvVar "GROQ_API_KEY"
  apiKeyOpenRouter <- getEnvVar "OPENROUTER_API_KEY"

  -- Default Model Names
  defModelOpenAI <- getEnvVar "OPENAI_DEFAULT_MODEL"
  defModelGoogle <- getEnvVar "GOOGLE_DEFAULT_MODEL"
  defModelAnthropic <- getEnvVar "ANTHROPIC_DEFAULT_MODEL"
  defModelGrok <- getEnvVar "GROK_DEFAULT_MODEL"
  defModelGroq <- getEnvVar "GROQ_DEFAULT_MODEL"
  defModelOllama <- getEnvVar "OLLAMA_DEFAULT_MODEL"
  defModelOpenRouter <- getEnvVar "OPENROUTER_DEFAULT_MODEL"

  -- Context Lengths
  ctxLenOpenAI <- getEnvNat "OPENAI_CONTEXT_LENGTH"
  ctxLenAnthropic <- getEnvNat "ANTHROPIC_CONTEXT_LENGTH"
  ctxLenGoogle <- getEnvNat "GOOGLE_CONTEXT_LENGTH"
  ctxLenGrok <- getEnvNat "GROK_CONTEXT_LENGTH"
  ctxLenGroq <- getEnvNat "GROQ_CONTEXT_LENGTH"
  ctxLenOllama <- getEnvNat "OLLAMA_CONTEXT_LENGTH"
  ctxLenOpenRouter <- getEnvNat "OPENROUTER_CONTEXT_LENGTH"

  -- Max Tokens
  maxTokOpenAI <- getEnvNat "OPENAI_MAX_TOKENS"
  maxTokAnthropic <- getEnvNat "ANTHROPIC_MAX_TOKENS"
  maxTokGoogle <- getEnvNat "GOOGLE_MAX_TOKENS"
  maxTokGrok <- getEnvNat "GROK_MAX_TOKENS"
  maxTokGroq <- getEnvNat "GROQ_MAX_TOKENS"
  maxTokOllama <- getEnvNat "OLLAMA_MAX_TOKENS"
  maxTokOpenRouter <- getEnvNat "OPENROUTER_MAX_TOKENS"

  pure (MkAppConfig
    -- API Keys
    apiKeyOpenAI
    apiKeyAnthropic
    apiKeyGoogleGemini
    apiKeyGrok
    apiKeyGroq
    apiKeyOpenRouter
    -- Default Model Names
    defModelOpenAI
    defModelGoogle
    defModelAnthropic
    defModelGrok
    defModelGroq
    defModelOllama
    defModelOpenRouter
    -- Context Lengths
    ctxLenOpenAI
    ctxLenAnthropic
    ctxLenGoogle
    ctxLenGrok
    ctxLenGroq
    ctxLenOllama
    ctxLenOpenRouter
    -- Max Tokens
    maxTokOpenAI
    maxTokAnthropic
    maxTokGoogle
    maxTokGrok
    maxTokGroq
    maxTokOllama
    maxTokOpenRouter
  )
