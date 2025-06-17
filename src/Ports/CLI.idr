module Ports.CLI

import Adapters.HTTP
import Adapters.AI
import Application.Judging
import Core.Types
import System
import System.File
import System.File.Process
import System.Clock
import Data.String
import Data.List
import Data.List1
import Data.IORef


-- Import all the types and functions we need from SimpleTest
-- (In a real application, these would be moved to proper modules)
public export
record DebateConfig where
  constructor MkDebateConfig
  maxRounds : Nat
  warningThreshold : Double

public export
record DebateTurn where
  constructor MkTurn
  turnNumber : Nat
  speaker : AIModel
  message : String
  timestamp : String

public export
record DebateSession where
  constructor MkSession
  topic : String
  participant1 : DebateParticipant
  participant2 : DebateParticipant
  judge : AIModel
  config : DebateConfig
  turns : List DebateTurn
  currentSpeaker : AIModel
  isComplete : Bool

-- Topic validation from SimpleTest
public export
record DebateTopic where
  constructor MkTopic
  topic : String
  isValid : Bool

public export
validateTopic : String -> DebateTopic
validateTopic topic =
  let trimmed = Data.String.trim topic
      isEmpty = length trimmed == 0
      tooShort = length trimmed < 3
      tooLong = length trimmed > 200
      isValid = not (isEmpty || tooShort || tooLong)
  in MkTopic trimmed isValid

-- Functions from SimpleTest that we need
-- Note: Parameter is actually currentTurns, not currentRounds
shouldShowWarning : DebateConfig -> Nat -> Bool
shouldShowWarning config currentTurns =
  let maxTurns = config.maxRounds * 2  -- Convert rounds to turns
      current = cast currentTurns
      threshold = config.warningThreshold
      maxTurnsFloat = cast maxTurns
  in current >= (maxTurnsFloat * threshold)

hasReachedMaxLength : DebateConfig -> Nat -> Bool
hasReachedMaxLength config currentTurns =
  let maxTurns = config.maxRounds * 2  -- Convert rounds to turns
  in currentTurns >= maxTurns

addTurn : DebateSession -> String -> DebateSession
addTurn session message =
  let newTurn = MkTurn (length session.turns + 1) session.currentSpeaker message "2024-01-01T00:00:00Z"
      newTurns = session.turns ++ [newTurn]
      nextSpeaker = if session.currentSpeaker == session.participant1.model
                      then session.participant2.model
                      else session.participant1.model
      shouldEnd = hasReachedMaxLength session.config (length newTurns)
  in MkSession session.topic session.participant1 session.participant2 session.judge session.config newTurns nextSpeaker shouldEnd

generateTurnContext : DebateSession -> String
generateTurnContext session =
  let recentTurns = takeLast 3 session.turns
      formatTurn = \turn => show turn.speaker ++ ": " ++ turn.message
  in joinWith "\n" (map formatTurn recentTurns)
  where
    takeLast : Nat -> List a -> List a
    takeLast n xs = reverse (take n (reverse xs))

    joinWith : String -> List String -> String
    joinWith sep [] = ""
    joinWith sep [x] = x
    joinWith sep (x :: xs) = x ++ sep ++ joinWith sep xs

public export
generateDebatePrompt : String -> DebateSide -> String -> String
generateDebatePrompt topic side context =
  let sideText = case side of
        Pro => "arguing FOR"
        Con => "arguing AGAINST"
      basePrompt = "DEBATE TOPIC: '" ++ topic ++ "'. "
      rolePrompt = "You are " ++ sideText ++ " this position. "
      contextPrompt = if length context > 0
                      then "Previous arguments: " ++ context ++ " "
                      else ""
      instructions = "Make your case in 2-3 sharp paragraphs maximum. Be direct, compelling, and decisive. No pleasantries or thank-yous. Attack the opposing position and defend yours with conviction. This is competitive debate, not polite conversation."
  in basePrompt ++ rolePrompt ++ contextPrompt ++ instructions

-- Scoring and winner declaration logic moved to Application.Judging

-- Random generation interface
interface RandomGen where
  coinFlip : IO Bool

RandomGen where
  coinFlip = do
    time <- clockTime Monotonic
    let baseSeed = nanoseconds time
    procTime <- clockTime Process
    let procNanos = nanoseconds procTime
    let seed = baseSeed + procNanos
    let randomValue = (seed * 1664525 + 1013904223) `mod` 4294967296
    pure ((randomValue `div` 2147483648) == 1)

-- CLI Configuration
public export
record CLIConfig where
  constructor MkCLIConfig
  useColor : Bool
  verbose : Bool
  maxTurns : Nat
  warningThreshold : Double

public export
defaultCLIConfig : CLIConfig
defaultCLIConfig = MkCLIConfig True True 10 0.9

-- Interface for user input (for testability)
public export
interface UserInput where
  getUserChoice : List String -> String -> IO (Maybe String)
  getUserInput : String -> IO (Maybe String)
  getUserConfirmation : String -> IO Bool

-- CLI validation functions
public export
isValidCLITopic : String -> Bool
isValidCLITopic topic =
  let validated = validateTopic topic
  in validated.isValid

public export
validateModelSelection : List AIModel -> AIModel -> Bool
validateModelSelection models selected = elem selected models

public export
canOrchestrateCLIDebate : String -> DebateConfig -> Bool
canOrchestrateCLIDebate topic config =
  let topicValid = isValidCLITopic topic
      configValid = config.maxRounds > 0 && config.warningThreshold > 0.0
  in topicValid && configValid

-- Pure model selection logic (testable)
public export
nameToModel : String -> Maybe AIModel
nameToModel "ChatGPT 4o" = Just ChatGPT4o
nameToModel "ChatGPT 4.1" = Just ChatGPT4_1
nameToModel "ChatGPT 4.5" = Just ChatGPT4_5
nameToModel "ChatGPT o3" = Just ChatGPTo3
nameToModel "ChatGPT 4o Mini" = Just ChatGPTo4Mini
nameToModel "Claude 4" = Just Claude4
nameToModel "Gemini Pro" = Just GeminiPro
nameToModel "Gemini Flash" = Just GeminiFlash
nameToModel "Grok" = Just Grok
nameToModel "Groq Llama" = Just GroqLlama
nameToModel "Ollama Local" = Just OllamaLocal
nameToModel "OpenRouter Gemini 2.5 Pro" = Just OpenRouterGemini25Pro
nameToModel "OpenRouter Gemini 2.0 Flash" = Just OpenRouterGemini20Flash
nameToModel "OpenRouter Claude 3.5" = Just OpenRouterClaude35
nameToModel "OpenRouter GPT-4o" = Just OpenRouterGPT4o
nameToModel _ = Nothing

public export
processModelSelection : List String -> String -> String -> String -> Maybe (AIModel, AIModel, AIModel)
processModelSelection modelOptions p1Name p2Name judgeName = do
  p1Model <- nameToModel p1Name
  p2Model <- nameToModel p2Name
  judgeModel <- nameToModel judgeName
  pure (p1Model, p2Model, judgeModel)

public export
getModelOptions : List String
getModelOptions = [
  "ChatGPT 4o",
  "ChatGPT 4.1",
  "ChatGPT 4.5",
  "ChatGPT o3",
  "ChatGPT 4o Mini",
  "Claude 4",
  "Gemini Pro",
  "Gemini Flash",
  "Grok",
  "Groq Llama",
  "Ollama Local",
  "OpenRouter Gemini 2.5 Pro",
  "OpenRouter Gemini 2.0 Flash",
  "OpenRouter Claude 3.5",
  "OpenRouter GPT-4o"
]

-- State management for default selections in testing
public export
record SelectionState where
  constructor MkSelectionState
  defaultSelections : List String
  currentIndex : Nat
  timeout : String

-- Debug helper function
debugPrint : String -> IO ()
debugPrint msg = do
  debugMode <- System.system "test \"${DEBUG:-}\" = \"true\" -o \"${DEBUG:-}\" = \"1\""
  case debugMode of
    0 => putStrLn ("🐛 DEBUG: " ++ msg)
    _ => pure ()

-- Initialize selection state from environment variables without filesystem operations
public export
initSelectionState : IO SelectionState
initSelectionState = do
  debugPrint "initSelectionState called"

  -- Read KOMBAT_DEFAULT_SELECTIONS value using getEnv like API keys
  maybeSelections <- getEnv "KOMBAT_DEFAULT_SELECTIONS"
  let selectionValue = case maybeSelections of
                         Nothing => ""
                         Just val => val
  debugPrint ("KOMBAT_DEFAULT_SELECTIONS value: '" ++ selectionValue ++ "'")

  -- Read KOMBAT_SELECTION_TIMEOUT value
  maybeTimeout <- getEnv "KOMBAT_SELECTION_TIMEOUT"
  let timeoutValue = case maybeTimeout of
                       Nothing => ""
                       Just val => val
  debugPrint ("KOMBAT_SELECTION_TIMEOUT value: '" ++ timeoutValue ++ "'")

  if selectionValue == ""
    then do
      let finalTimeout = if timeoutValue == "" then "30s" else timeoutValue
      debugPrint ("No selections provided - normal mode, timeout: " ++ finalTimeout)
      pure (MkSelectionState [] 0 finalTimeout)
    else do
      let selections = toList (split (== ';') selectionValue)
      -- Auto-set small timeout when selections are provided
      let finalTimeout = if timeoutValue == "" then "0.01s" else timeoutValue
      -- Validate that we have enough selections for a complete debate setup
      if length selections < 5
        then do
          debugPrint ("⚠️  WARNING: Only " ++ show (length selections) ++ " selections provided, need 5 minimum")
          debugPrint ("   Expected: Ready;Topic;Participant1;Participant2;Judge")
          debugPrint ("   Got: " ++ show selections)
          debugPrint ("   Auto-timeout: " ++ finalTimeout)
          pure (MkSelectionState selections 0 finalTimeout)
        else do
          debugPrint ("Parsed selections: " ++ show selections ++ ", auto-timeout: " ++ finalTimeout)
          pure (MkSelectionState selections 0 finalTimeout)

-- Get next default selection and update state
public export
getNextSelection : SelectionState -> List String -> (String, SelectionState)
getNextSelection state options =
  case drop state.currentIndex state.defaultSelections of
    (selection :: _) =>
      if elem selection options
        then (selection, { currentIndex := state.currentIndex + 1 } state)
        else -- Selection not found in options - this is the bug!
             -- Instead of falling back to first option, we should preserve the intended selection
             -- and let the TUI wrapper handle the validation
             (selection, { currentIndex := state.currentIndex + 1 } state)
    [] => case options of
            (first :: _) => (first, state)
            [] => ("", state)

-- Use hardcoded testing-friendly defaults with state management
-- These make the functions work deterministically for testing while still
-- allowing environment variable overrides when needed

-- Gum-based implementation of UserInput interface using state management
public export
gumChooseWithState : SelectionState -> List String -> String -> IO (Maybe String, SelectionState)
gumChooseWithState state options prompt = do
  debugPrint ("gumChooseWithState called - prompt: " ++ prompt)
  debugPrint ("State: timeout=" ++ state.timeout ++ ", index=" ++ show state.currentIndex)
  debugPrint ("Available selections: " ++ show state.defaultSelections)

  let (selectedOption, newState) = getNextSelection state options

  debugPrint ("Selected option: " ++ selectedOption ++ ", new index: " ++ show newState.currentIndex)

  -- Escape single quotes in strings for shell safety
  let escapeSingleQuotes : String -> String
      escapeSingleQuotes s = pack (concatMap escapeChar (unpack s))
        where
          escapeChar : Char -> List Char
          escapeChar '\'' = ['\'', '"', '\'', '"', '\'']  -- Replace ' with '"'"
          escapeChar c = [c]

  let escapedOptions = map escapeSingleQuotes options
  let optionsList = concat (map (\opt => opt ++ "\\n") escapedOptions)
  let escapedPrompt = escapeSingleQuotes prompt
  let escapedSelection = escapeSingleQuotes selectedOption

  let baseCmd = "printf '" ++ optionsList ++ "' | gum choose --header='" ++ escapedPrompt ++ "'"
  let stderrRedirect = if state.timeout == "0.01s" then " 2>/dev/null" else ""
  let cmd = baseCmd ++ " --timeout=" ++ state.timeout ++ " --selected='" ++ escapedSelection ++ "'" ++ stderrRedirect

  debugPrint ("Executing command: " ++ cmd)

  resultRef <- newIORef ""
  exitCode <- runProcessingOutput (\line => do
    current <- readIORef resultRef
    if current == "" && trim line /= ""
      then writeIORef resultRef (trim line)
      else pure ()) cmd

  result <- readIORef resultRef
  debugPrint ("Command result - exit code: " ++ show exitCode ++ ", output: '" ++ result ++ "'")

  case (exitCode, result) of
    (0, choice) => if choice == ""
                   then do
                     debugPrint ("Empty result, using fallback: " ++ selectedOption)
                     pure (Just selectedOption, newState)
                   else do
                     debugPrint ("Got choice: " ++ choice)
                     pure (Just choice, newState)
    (_, _) => do
      debugPrint ("Command failed, using fallback: " ++ selectedOption)
      pure (Just selectedOption, newState)

-- Legacy interface for backward compatibility
public export
gumChoose : List String -> String -> IO (Maybe String)
gumChoose options prompt = do
  state <- initSelectionState
  (result, _) <- gumChooseWithState state options prompt
  pure result

public export
gumInput : String -> IO (Maybe String)
gumInput prompt = do
  -- Check if we're in test mode to use shorter timeout
  testMode <- getEnvVar "KOMBAT_TEST_MODE"
  let timeout = case testMode of
                  Just "true" => "0.01s"  -- Fast timeout for tests
                  _ => "60s"              -- Full minute for real user input
  let baseCmd = "gum input --placeholder '" ++ prompt ++ "'"
  let cmd = baseCmd ++ " --timeout=" ++ timeout

  resultRef <- newIORef ""
  exitCode <- runProcessingOutput (\line => do
    current <- readIORef resultRef
    if current == ""
      then writeIORef resultRef (trim line)
      else pure ()  -- Already captured first line, ignore rest
    ) cmd

  result <- readIORef resultRef
  case (exitCode, result) of
    (0, input) => if input == "" then pure Nothing else pure (Just input)
    (_, _) => pure Nothing

-- Confirm with state management for testing - using gumChoose instead of gum confirm
public export
gumConfirmWithState : SelectionState -> String -> IO (Bool, SelectionState)
gumConfirmWithState state prompt = do
  debugPrint ("gumConfirmWithState called - prompt: " ++ prompt)

  -- Use gumChoose with Yes/No options instead of gum confirm
  let confirmOptions = ["Yes", "No"]
  (choiceResult, newState) <- gumChooseWithState state confirmOptions prompt

  debugPrint ("Confirm choice result: " ++ show choiceResult)

  case choiceResult of
    Just "Yes" => do
      debugPrint "Returning True"
      pure (True, newState)
    _ => do
      debugPrint "Returning False"
      pure (False, newState)  -- Default to False for "No" or Nothing

-- Legacy interface for backward compatibility
public export
gumConfirm : String -> IO Bool
gumConfirm prompt = do
  state <- initSelectionState
  (result, _) <- gumConfirmWithState state prompt
  pure result

-- Gum implementation of UserInput interface
UserInput where
  getUserChoice = gumChoose
  getUserInput = gumInput
  getUserConfirmation = gumConfirm

-- Glow helpers for markdown rendering
glowMarkdown : String -> IO ()
glowMarkdown content = do
  -- Use current time in nanoseconds for unique filename
  time <- clockTime UTC
  let uniqueId = show (nanoseconds time)
  let markdownFile = "/tmp/tensor_kombat_content_" ++ uniqueId ++ ".md"
  Right () <- writeFile markdownFile content
    | Left err => putStrLn ("Error writing markdown: " ++ show err)

  ignore $ System.system ("glow " ++ markdownFile)
  ignore $ System.system ("rm -f " ++ markdownFile)

-- CLI interface functions with state management
public export
selectDebateTopicWithState : SelectionState -> IO (Maybe String, SelectionState)
selectDebateTopicWithState state = do
  putStrLn "🎯 Debate Topic Selection"
  putStrLn "========================"
  putStrLn ""

  let suggestions = [
    -- Technology & Society
    "Should social media platforms prioritize free speech over content moderation?",
    "Should artificial intelligence development be heavily regulated by government?", 
    "Should nuclear energy be prioritized over renewable energy sources?",
    "Should genetic engineering be permitted for human enhancement purposes?",
    "Should cryptocurrency replace traditional banking systems?",
    "Should companies be required to allow permanent remote work options?",
    
    -- Politics & Policy  
    "Should Palestine have the right to armed resistance against occupation?",
    "Should Donald Trump be permanently banned from all social media platforms?",
    "Should hate speech be criminally prosecuted rather than protected speech?",
    "Should transgender athletes be allowed to compete in their gender identity category?",
    "Should abortion access be guaranteed as a fundamental human right?",
    "Should Western countries accept unlimited refugees regardless of capacity?",
    "Should civil disobedience be legally protected for climate activism?",
    
    -- Economics & Justice
    "Should billionaires face wealth caps through progressive taxation?",
    "Should reparations be paid to descendants of American slavery?", 
    "Should DEI programs be mandated in all major corporations?",
    "Should universities be required to maintain race-conscious admissions?",
    "Should parents have the right to refuse mandatory childhood vaccinations?",
    
    -- Social & Cultural
    "Should cultural appropriation be legally restricted and penalized?",
    "Should traditional gender roles be actively promoted in education?",
    "Should polyamorous relationships receive the same legal recognition as marriage?",
    "Should social media usage be restricted for users under 16?",
    "Should violent video games be banned to reduce societal aggression?",
    "Should religious symbols be prohibited in all public institutions?",
    
    "Custom Topic (enter your own)"
  ]

  (choice, newState) <- gumChooseWithState state suggestions "Choose a debate topic:"
  case choice of
    Nothing => pure (Nothing, newState)
    Just "Custom Topic (enter your own)" => do
      putStrLn "\nEnter your custom debate topic:"
      customTopic <- gumInput "Custom topic"
      case customTopic of
        Nothing => pure (Nothing, newState)
        Just topic =>
          if isValidCLITopic topic
            then pure (Just topic, newState)
            else do
              putStrLn "❌ Invalid topic. Topic must be 3-200 characters."
              pure (Nothing, newState)
    Just selectedTopic =>
      -- Check if it's a stock topic or treat as custom
      if elem selectedTopic suggestions
        then do
          putStrLn ("✓ Topic: " ++ selectedTopic)  -- Echo selection
          pure (Just selectedTopic, newState)
        else
          -- Treat as custom topic
          if isValidCLITopic selectedTopic
            then do
              putStrLn ("✓ Custom topic: " ++ selectedTopic)  -- Echo selection
              pure (Just selectedTopic, newState)
            else do
              putStrLn "❌ Invalid topic. Topic must be 3-200 characters."
              pure (Nothing, newState)

-- Legacy interface for backward compatibility
public export
selectDebateTopicWithInput : UserInput => IO (Maybe String)
selectDebateTopicWithInput = do
  state <- initSelectionState
  (result, _) <- selectDebateTopicWithState state
  pure result

-- Model selection with state management
public export
selectAIModelsWithState : SelectionState -> IO (Maybe (AIModel, AIModel, AIModel), SelectionState)
selectAIModelsWithState state = do
  putStrLn "\n🤖 AI Model Selection"
  putStrLn "====================="
  putStrLn ""

  -- Select Pro participant
  putStrLn "Select who will be arguing for the Pro position:"
  (participant1Choice, state1) <- gumChooseWithState state getModelOptions "Pro participant:"

  case participant1Choice of
    Nothing => pure (Nothing, state1)
    Just p1Name => do
      debugPrint ("🐛 DEBUG: P1 selected: " ++ p1Name)
      putStrLn ("✓ Pro: " ++ p1Name)  -- Echo selection
      -- Select second participant
      putStrLn "\nSelect who will be arguing for the Con position:"
      (participant2Choice, state2) <- gumChooseWithState state1 getModelOptions "Con participant:"

      case participant2Choice of
        Nothing => pure (Nothing, state2)
        Just p2Name => do
          debugPrint ("🐛 DEBUG: P2 selected: " ++ p2Name)
          putStrLn ("✓ Con: " ++ p2Name)  -- Echo selection
          -- Select judge
          putStrLn "\nSelect debate judge:"
          (judgeChoice, state3) <- gumChooseWithState state2 getModelOptions "Judge:"

          case judgeChoice of
            Nothing => pure (Nothing, state3)
            Just judgeName => do
              debugPrint ("🐛 DEBUG: Judge selected: " ++ judgeName)
              putStrLn ("✓ Judge: " ++ judgeName)  -- Echo selection
              debugPrint ("🐛 DEBUG: About to process: P1=" ++ p1Name ++ ", P2=" ++ p2Name ++ ", Judge=" ++ judgeName)
              case processModelSelection getModelOptions p1Name p2Name judgeName of
                Nothing => do
                  debugPrint ("🐛 DEBUG: processModelSelection returned Nothing!")
                  pure (Nothing, state3)
                Just result => do
                  let (p1Model, p2Model, judgeModel) = result
                  debugPrint ("🐛 DEBUG: processModelSelection result: P1=" ++ show p1Model ++ ", P2=" ++ show p2Model ++ ", Judge=" ++ show judgeModel)
                  pure (Just result, state3)

-- Pure testable model selection logic
public export
selectAIModelsWithInput : UserInput => IO (Maybe (AIModel, AIModel, AIModel))
selectAIModelsWithInput = do
  state <- initSelectionState
  (result, _) <- selectAIModelsWithState state
  pure result

-- Wrapper for compatibility
public export
selectDebateTopic : IO (Maybe String)
selectDebateTopic = selectDebateTopicWithInput

public export
selectAIModels : IO (Maybe (AIModel, AIModel, AIModel))
selectAIModels = selectAIModelsWithInput

public export
configureDebateWithInput : UserInput => IO (Maybe DebateConfig)
configureDebateWithInput = do
  putStrLn "\n⚙️  Debate Configuration"
  putStrLn "========================"
  putStrLn ""

  -- Quick config or custom?
  useQuick <- getUserConfirmation "Use quick configuration? (5 rounds, 80% warning)"
  if useQuick
    then pure (Just (MkDebateConfig 5 0.8))
    else do
      -- Custom configuration
      putStrLn "Custom configuration:"

      maxRoundsStr <- getUserInput "Maximum number of rounds (default: 5)"
      let maxRounds = case maxRoundsStr of
                       Nothing => 5
                       Just str => case parseInteger str of
                                     Just n => cast n
                                     Nothing => 5

      warningStr <- getUserInput "Warning threshold 0.0-1.0 (default: 0.8)"
      let warningThreshold = case warningStr of
                               Nothing => 0.8
                               Just str => 
                                 let cleanStr = if isPrefixOf "." str then "0" ++ str else str
                                 in case parseDouble cleanStr of
                                      Just d => if d >= 0.0 && d <= 1.0 then d else 0.8
                                      Nothing => 0.8

      pure (Just (MkDebateConfig maxRounds warningThreshold))

-- Wrapper for compatibility
public export
configureDebate : IO (Maybe DebateConfig)
configureDebate = configureDebateWithInput

-- Normalize text by removing single linefeeds but keeping double linefeeds (paragraph breaks)
public export
normalizeText : String -> String
normalizeText text =
  let chars = unpack text
      normalized = normalizeChars chars []
  in pack (reverse normalized)
  where
    normalizeChars : List Char -> List Char -> List Char
    normalizeChars [] acc = acc
    -- Handle paragraph breaks (double newlines)
    normalizeChars ('\n' :: '\n' :: rest) acc =
      normalizeChars rest ('\n' :: '\n' :: acc)
    -- Handle single newlines (replace with space)
    normalizeChars ('\n' :: rest) acc =
      normalizeChars rest (' ' :: acc)
    -- Handle carriage returns (Windows/mixed line endings)
    normalizeChars ('\r' :: '\n' :: rest) acc =
      normalizeChars rest (' ' :: acc)
    normalizeChars ('\r' :: rest) acc =
      normalizeChars rest (' ' :: acc)
    -- Handle multiple spaces (collapse to single space)
    normalizeChars (' ' :: ' ' :: rest) acc =
      normalizeChars (' ' :: rest) acc
    -- Handle tabs (convert to space)
    normalizeChars ('\t' :: rest) acc =
      normalizeChars rest (' ' :: acc)
    -- Regular characters
    normalizeChars (c :: rest) acc =
      normalizeChars rest (c :: acc)

-- Format debate turn as markdown
formatTurnMarkdown : DebateTurn -> String
formatTurnMarkdown turn =
  "## Turn " ++ show turn.turnNumber ++ " - " ++ show turn.speaker ++ "\n\n" ++
  normalizeText turn.message ++ "\n\n"

-- Helper function for correct turn grammar
formatTurnCount : Nat -> String
formatTurnCount 1 = "1 turn"
formatTurnCount n = show n ++ " turns"

-- Helper function for correct round progress display
formatRoundProgress : Nat -> Nat -> String
formatRoundProgress turns maxRounds =
  let maxTurns = maxRounds * 2
      completeRounds = cast ((cast turns) `div` 2)
      isHalfRound = turns > (completeRounds * 2)
      roundStr = if isHalfRound
                   then show completeRounds ++ ".5"
                   else show completeRounds ++ ".0"
  in "Round " ++ roundStr ++ " of " ++ show maxRounds ++ " (" ++ show maxTurns ++ " turns max)"

-- Display only new turns since last shown (incremental display)
public export
displayNewTurns : HTTPClient => DebateSession -> Nat -> IO ()
displayNewTurns session lastShownIndex = do
  let newTurns = drop lastShownIndex session.turns
  if null newTurns
    then pure ()
    else do
      let markdown = concat (map formatTurnMarkdown newTurns)
      glowMarkdown markdown

-- Display full debate progress (for completion/summary)
public export
displayDebateProgress : HTTPClient => DebateSession -> IO ()
displayDebateProgress session = do
  let turnCount = length session.turns
  let markdown = "# 🎭 " ++ session.topic ++ "\n\n" ++
                 "**Participants:** " ++ show session.participant1 ++ " vs " ++ show session.participant2 ++ "\n\n" ++
                 "**Judge:** " ++ show session.judge ++ "\n\n" ++
                 "**Progress:** " ++ formatTurnCount turnCount ++ " (" ++ formatRoundProgress turnCount session.config.maxRounds ++ ")\n\n" ++
                 "---\n\n" ++
                 concat (map formatTurnMarkdown session.turns)

  glowMarkdown markdown

-- Check if warning should be shown
shouldShowTurnWarning : DebateSession -> Bool
shouldShowTurnWarning session = shouldShowWarning session.config (length session.turns)

-- Run a complete debate
public export
runDebate : HTTPClient => String -> AIModel -> AIModel -> AIModel -> DebateConfig -> IO ()
runDebate topic participant1Model participant2Model judgeModel config = do
  putStrLn "\n🎬 Starting Debate!"
  putStrLn "==================="
  putStrLn ""

  -- Initial setup - preserve Pro/Con assignments, only randomize first speaker
  putStrLn "🎲 Determining first speaker..."
  firstSpeaker <- coinFlip

  -- Always assign sides consistently: participant1Model = Pro, participant2Model = Con
  let proParticipant = MkParticipant participant1Model Pro "Participant 1"
  let conParticipant = MkParticipant participant2Model Con "Participant 2"

  -- Coin flip only determines who speaks first, not who argues which side
  let firstToSpeak = if firstSpeaker then proParticipant else conParticipant
  let secondToSpeak = if firstSpeaker then conParticipant else proParticipant

  putStrLn ("✓ " ++ firstToSpeak.name ++ " (" ++ show firstToSpeak.model ++ ") will argue " ++ show firstToSpeak.side ++ " (goes first)")
  putStrLn ("✓ " ++ secondToSpeak.name ++ " (" ++ show secondToSpeak.model ++ ") will argue " ++ show secondToSpeak.side ++ " (goes second)")
  putStrLn ""

  -- Create initial session with consistent participant assignments and first speaker
  let session = MkSession topic proParticipant conParticipant judgeModel config [] firstToSpeak.model False

  -- Main debate loop
  debateLoop session

  where
    debateLoop : DebateSession -> IO ()
    debateLoop session = do
      if session.isComplete
        then do
          putStrLn "🏁 Debate Complete!"
          displayDebateProgress session

          -- Score the debate
          putStrLn "\n📊 Scoring debate..."
          -- Convert DebateSession to Debate and call the judgeDebate function from the Application layer
          let debate = MkDebate session.topic session.participant1 session.participant2 session.judge InProgress
                       (map (\turn => MkMessage turn.speaker turn.message turn.timestamp) session.turns)
                       (Just session.currentSpeaker)
          judgeResult <- Application.Judging.judgeDebate debate session.judge
          case judgeResult of
            Left err => putStrLn ("❌ Scoring error: " ++ show err)
            Right (MkJudgeResult scores verbalAssessment) => do
              putStrLn "🏆 FINAL DEBATE RESULTS"
              putStrLn "======================="
              putStrLn ("📋 Topic: " ++ session.topic)
              -- Display the judge's full response, from which scores are parsed
              putStrLn "\n📝 Judge's Full Response:"
              putStrLn "--------------------------"
              putStrLn verbalAssessment
              putStrLn "--------------------------\n"

              putStrLn "📊 Final Scores Summary:"
              -- Display the scores parsed from the response above
              traverse_ (\score => putStrLn (show score ++ "\n")) scores
              putStrLn "======================="
              putStrLn ("📋 Topic: " ++ session.topic)
              putStrLn ""
              putStrLn ("🎯 Judged by: " ++ show session.judge)

              putStrLn "\n🎙️ Judge is making the winner announcement..."
              -- Get the raw AI-generated winner announcement from the application layer
              declarationResult <- Application.Judging.getApplicationLayerWinnerDeclaration debate session.judge session.topic scores

              case declarationResult of
                Left err => putStrLn ("❌ Winner declaration error: " ++ show err)
                Right rawDeclaration => do
                  -- Determine the header based on whether it's a tie
                  let finalFormattedDeclaration = case scores of
                        [s1, s2] =>
                          let header = if s1.totalScore == s2.totalScore
                                       then "\n🚨 IT'S A TIE! 🚨\n"
                                       else "\n🚨 THE JUDGE HAS SPOKEN! 🚨\n"
                          in header ++
                             "═══════════════════════════════════════════════\n" ++
                             rawDeclaration ++ "\n" ++
                             "═══════════════════════════════════════════════\n"
                        _ => "🏆 The debate concludes with honor to all participants!"

                  putStrLn finalFormattedDeclaration
        else do
          -- Generate prompt for current speaker
          let context = generateTurnContext session
          let speakerSide = if session.currentSpeaker == session.participant1.model
                              then session.participant1.side
                              else session.participant2.side

          -- Include warning in prompt if approaching max turns
          let warningPrefix = if shouldShowTurnWarning session
                             then "⚠️ IMPORTANT: This debate is approaching maximum length! Please consider wrapping up your argument in this turn.\n\n"
                             else ""

          let basePrompt = generateDebatePrompt topic speakerSide context
          let prompt = warningPrefix ++ basePrompt

          -- Also show warning to user
          when (shouldShowTurnWarning session) $ do
            putStrLn "⚠️  Debate approaching maximum length! Please consider wrapping up your argument!"
            putStrLn ""

          putStrLn ("💭 " ++ show session.currentSpeaker ++ " is thinking...")

          -- Get response from AI
          result <- generateResponse session.currentSpeaker prompt
          case result of
            Left err => do
              putStrLn ("❌ Error: " ++ show err)
              putStrLn "Ending debate due to error."
            Right response => do
              -- Add turn to session
              let newSession = addTurn session response.content

              -- Display only new turn (incremental)
              displayNewTurns newSession (length session.turns)

              -- Continue or ask user
              if hasReachedMaxLength config (length newSession.turns)
                then debateLoop (MkSession newSession.topic newSession.participant1 newSession.participant2
                                           newSession.judge newSession.config newSession.turns
                                           newSession.currentSpeaker True)
                else do
                  putStrLn "\n🤔 Do you want to continue this debate for more rounds?"
                  continue <- gumConfirm "Continue debate?"
                  if continue
                    then debateLoop newSession
                    else debateLoop (MkSession newSession.topic newSession.participant1 newSession.participant2
                                               newSession.judge newSession.config newSession.turns
                                               newSession.currentSpeaker True)

-- Main CLI entry point with state management
public export
runCLI : HTTPClient => IO ()
runCLI = do
  -- Initialize selection state for the entire session
  initialState <- initSelectionState
  -- ASCII art banner
  let banner = """
  ████████╗███████╗███╗   ██╗███████╗ ██████╗ ██████╗
  ╚══██╔══╝██╔════╝████╗  ██║██╔════╝██╔═══██╗██╔══██╗
     ██║   █████╗  ██╔██╗ ██║███████╗██║   ██║██████╔╝
     ██║   ██╔══╝  ██║╚██╗██║╚════██║██║   ██║██╔══██╗
     ██║   ███████╗██║ ╚████║███████║╚██████╔╝██║  ██║
     ╚═╝   ╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝

  ██╗  ██╗ ██████╗ ███╗   ███╗██████╗  █████╗ ████████╗
  ██║ ██╔╝██╔═══██╗████╗ ████║██╔══██╗██╔══██╗╚══██╔══╝
  █████╔╝ ██║   ██║██╔████╔██║██████╔╝███████║   ██║
  ██╔═██╗ ██║   ██║██║╚██╔╝██║██╔══██╗██╔══██║   ██║
  ██║  ██╗╚██████╔╝██║ ╚═╝ ██║██████╔╝██║  ██║   ██║
  ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝

  🤖 AI Debate Platform - Where Ideas Clash! 🥊
  """

  putStrLn banner
  putStrLn ""

  -- Check API keys
  putStrLn "🔑 Checking API keys..."
  openaiKey <- getEnvVar "OPENAI_API_KEY"
  claudeKey <- getEnvVar "ANTHROPIC_API_KEY"
  geminiKey <- getEnvVar "GOOGLE_GEMINI_API_KEY"

  let hasKeys = case (openaiKey, claudeKey, geminiKey) of
                  (Just _, _, _) => True
                  (_, Just _, _) => True
                  (_, _, Just _) => True
                  _ => False

  if not hasKeys
    then do
      putStrLn "❌ No API keys found! Please set at least one:"
      putStrLn "   export OPENAI_API_KEY='your-key'"
      putStrLn "   export ANTHROPIC_API_KEY='your-key'"
      putStrLn "   export GOOGLE_GEMINI_API_KEY='your-key'"
    else do
      putStrLn "✓ API keys detected"
      putStrLn ""

      -- Welcome and topic selection with state management
      (welcome, state1) <- gumConfirmWithState initialState "Welcome to Tensor-Kombat! Ready to watch AIs debate?"
      if not welcome
        then putStrLn "👋 Come back when you're ready for some AI action!"
        else do
          -- Select topic
          (maybeTopic, state2) <- selectDebateTopicWithState state1
          case maybeTopic of
            Nothing => putStrLn "❌ No topic selected. Exiting."
            Just topic => do
              -- Select models
              (maybeModels, state3) <- selectAIModelsWithState state2
              case maybeModels of
                Nothing => putStrLn "❌ Model selection cancelled. Exiting."
                Just (p1, p2, judge) => do
                  -- Show selected models in user-friendly format
                  putStrLn ("🤖 So we have " ++ show p1 ++ " arguing for the Pro position, " ++ show p2 ++ " for the Con, and " ++ show judge ++ " for the judge!")
                  -- Configure debate
                  maybeConfig <- configureDebate
                  case maybeConfig of
                    Nothing => putStrLn "❌ Configuration cancelled. Exiting."
                    Just config => do
                      -- Final confirmation
                      let warningPercent = cast {to=Int} (config.warningThreshold * 100)
                          summary = "🎭 **Debate:** " ++ topic ++ "\n" ++
                                   "🤖 **Participants:** " ++ show p1 ++ " vs " ++ show p2 ++ "\n" ++
                                   "⚖️  **Judge:** " ++ show judge ++ "\n" ++
                                   "⚙️  **Config:** " ++ show config.maxRounds ++ " rounds, " ++ show warningPercent ++ "% warning"

                      glowMarkdown summary

                      ready <- gumConfirm "Start the debate?"
                      if ready
                        then runDebate topic p1 p2 judge config
                        else putStrLn "👋 Debate cancelled. See you next time!"
