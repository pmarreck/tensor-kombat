module Core.Types

-- | Supported AI models for debates
public export
data AIModel : Type where
  ChatGPT4o : AIModel
  ChatGPT4_1 : AIModel
  ChatGPT4_5 : AIModel
  ChatGPTo3 : AIModel
  ChatGPTo4Mini : AIModel
  GeminiPro : AIModel
  GeminiFlash : AIModel
  Claude4 : AIModel
  Grok : AIModel
  GroqLlama : AIModel
  OllamaLocal : AIModel

public export
Eq AIModel where
  ChatGPT4o == ChatGPT4o = True
  ChatGPT4_1 == ChatGPT4_1 = True
  ChatGPT4_5 == ChatGPT4_5 = True
  ChatGPTo3 == ChatGPTo3 = True
  ChatGPTo4Mini == ChatGPTo4Mini = True
  Claude4 == Claude4 = True
  GeminiPro == GeminiPro = True
  GeminiFlash == GeminiFlash = True
  Grok == Grok = True
  GroqLlama == GroqLlama = True
  OllamaLocal == OllamaLocal = True
  _ == _ = False

public export
Show AIModel where
  show ChatGPT4o = "ChatGPT 4o"
  show ChatGPT4_1 = "ChatGPT 4.1"
  show ChatGPT4_5 = "ChatGPT 4.5"
  show ChatGPTo3 = "ChatGPT o3"
  show ChatGPTo4Mini = "ChatGPT 4o Mini"
  show Claude4 = "Claude 4"
  show GeminiPro = "Gemini Pro"
  show GeminiFlash = "Gemini Flash"
  show Grok = "Grok"
  show GroqLlama = "Groq Llama"
  show OllamaLocal = "Ollama Local"

-- | Which side of the debate an AI is arguing
public export
data DebateSide : Type where
  Pro : DebateSide
  Con : DebateSide

public export
Eq DebateSide where
  Pro == Pro = True
  Con == Con = True
  _ == _ = False

public export
Show DebateSide where
  show Pro = "Pro"
  show Con = "Con"

-- | A debate participant with their model and assigned side
public export
record DebateParticipant where
  constructor MkParticipant
  model : AIModel
  side : DebateSide
  name : String

public export
Show DebateParticipant where
  show p = p.name ++ " (" ++ show p.model ++ ", " ++ show p.side ++ ")"

-- | Current state of a debate
public export
data DebateState : Type where
  NotStarted : DebateState
  InProgress : DebateState
  Completed : DebateState

public export
Eq DebateState where
  NotStarted == NotStarted = True
  InProgress == InProgress = True
  Completed == Completed = True
  _ == _ = False

public export
Show DebateState where
  show NotStarted = "Not Started"
  show InProgress = "In Progress"
  show Completed = "Completed"

-- | A single message in a debate
public export
record DebateMessage where
  constructor MkMessage
  speaker : AIModel
  content : String
  timestamp : String  -- We'll improve this later

public export
Show DebateMessage where
  show msg = "[" ++ show msg.speaker ++ "] " ++ msg.content

-- | The complete debate information
public export
record Debate where
  constructor MkDebate
  topic : String
  participant1 : DebateParticipant
  participant2 : DebateParticipant
  judge : AIModel
  state : DebateState
  messages : List DebateMessage
  currentTurn : Maybe AIModel

public export
Show Debate where
  show d = "Debate: " ++ d.topic ++ " (" ++ show d.state ++ ")"

-- API Error types
public export
data APIError : Type where
  NetworkError : String -> APIError
  ParseError : String -> APIError
  AuthError : String -> APIError

public export
Eq APIError where
  (NetworkError s1) == (NetworkError s2) = s1 == s2
  (ParseError s1) == (ParseError s2) = s1 == s2
  (AuthError s1) == (AuthError s2) = s1 == s2
  _ == _ = False

public export
Show APIError where
  show (NetworkError msg) = "NetworkError: " ++ msg
  show (ParseError msg) = "ParseError: " ++ msg
  show (AuthError msg) = "AuthError: " ++ msg

-- AI response from API call
public export
record AIResponse where
  constructor MkAIResponse
  content : String
  model : AIModel
  tokensUsed : Nat

public export
Show AIResponse where
  show resp = "AIResponse(" ++ resp.content ++ " from " ++ show resp.model ++ ")"

-- AI client interface
public export
interface AIClient where
  -- Generate response from AI model
  generateResponse : AIModel -> String -> IO (Either APIError AIResponse)
  -- Test if API key is valid
  testConnection : AIModel -> IO (Either APIError Bool)
