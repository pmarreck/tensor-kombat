module Core.Config

import Prelude -- For Nat and other basic types

-- Application Configuration Record
-- This record holds all configuration values typically loaded from environment variables.
-- Fields are Maybe types to represent that an environment variable might not be set
-- or might not parse correctly (for numeric values).
public export
record AppConfig where
  constructor MkAppConfig

  -- API Keys
  openAIAPIKey : Maybe String
  anthropicAPIKey : Maybe String
  googleGeminiAPIKey : Maybe String
  grokAPIKey : Maybe String
  groqAPIKey : Maybe String
  openRouterAPIKey : Maybe String

  -- Default Model Names (per provider type)
  openAIDefaultModel : Maybe String
  googleDefaultModel : Maybe String      -- For Gemini models
  anthropicDefaultModel : Maybe String   -- For Claude models
  grokDefaultModel : Maybe String
  groqDefaultModel : Maybe String
  ollamaDefaultModel : Maybe String
  openRouterDefaultModel : Maybe String

  -- Context Lengths (per provider type)
  openAIContextLength : Maybe Nat
  anthropicContextLength : Maybe Nat
  googleContextLength : Maybe Nat
  grokContextLength : Maybe Nat
  groqContextLength : Maybe Nat
  ollamaContextLength : Maybe Nat
  openRouterContextLength : Maybe Nat

  -- Max Tokens (per provider type)
  openAIMaxTokens : Maybe Nat
  anthropicMaxTokens : Maybe Nat
  googleMaxTokens : Maybe Nat
  grokMaxTokens : Maybe Nat
  groqMaxTokens : Maybe Nat
  ollamaMaxTokens : Maybe Nat
  openRouterMaxTokens : Maybe Nat
