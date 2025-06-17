module Ports.TUI

import System
import System.Info
import System.File.Process
import Data.String
import Data.Maybe
import Data.IORef
import Core.Types
import System.Random
import Data.List

%default partial

-- A helper function for debug printing, controlled by the KOMBAT_DEBUG_MODE env var.
-- This is useful for tracing the behavior of the TUI functions.
debugPrint : HasIO io => String -> io ()
debugPrint msg = do
  debugMode <- getEnv "KOMBAT_DEBUG_MODE"
  when (isJust debugMode) (putStrLn ("[DEBUG] " ++ msg))

-- Helper to escape single quotes for safe insertion into shell commands.
escapeSingleQuotes : String -> String
escapeSingleQuotes s = pack (go (unpack s))
  where
    go : List Char -> List Char
    go [] = []
    go ('\'' :: xs) = '\'' :: '\\' :: '\'' :: '\'' :: go xs
    go (x :: xs) = x :: go xs

-- A robust wrapper around 'gum choose' that handles its quirks.
--
-- @param prompt The header prompt to display to the user.
-- @param options The list of choices for the user.
-- @param defaultOption The default value to return if the choice times out. Must be one of the options.
-- @param timeoutHundredths The timeout in hundredths of a second. A value of 0 is coerced to 1 (0.01s).
-- @param echo If true, the final chosen option is printed to the console.
public export
TUIUserChoose : (prompt : String) ->
                (options : List String) ->
                (defaultOption : String) ->
                (timeoutHundredths : Nat) ->
                (echo : Bool) ->
                IO String
TUIUserChoose prompt options defaultOption timeoutHundredths echo = do
  debugPrint ("TUIUserChoose called with prompt: '" ++ prompt ++ "', default: '" ++ defaultOption ++ "'")

  -- Validate that default option is in the options list, fallback to first option if not
  let validatedDefault = if elem defaultOption options
                         then defaultOption
                         else case options of
                                (first :: _) => first
                                [] => defaultOption  -- Keep original if no options (will error later)

  debugPrint ("Validated default: '" ++ validatedDefault ++ "'")

  -- 1. Coerce timeout of 0 to 1, as gum ignores a 0s timeout.
  let effectiveTimeout = if timeoutHundredths == 0 then 1 else timeoutHundredths
  let timeoutStr = show (cast effectiveTimeout / 100.0) ++ "s"

  -- Prepare strings for the shell command
  let optionsList = unlines options
  let escapedPrompt = escapeSingleQuotes prompt
  let escapedSelection = escapeSingleQuotes validatedDefault

  -- In test mode, redirect stderr to /dev/null to keep test output clean.
  isTestMode <- getEnv "KOMBAT_TEST_MODE"
  let stderrRedirect = if isJust isTestMode then " 2>/dev/null" else ""

  -- Construct the full gum command
  let cmd = "printf '" ++ optionsList ++ "' | gum choose --header='" ++ escapedPrompt ++ "' --timeout=" ++ timeoutStr ++ " --selected='" ++ escapedSelection ++ "'" ++ stderrRedirect
  debugPrint ("Executing gum command: " ++ cmd)

  -- Execute the command and capture output
  resultRef <- newIORef ""
  exitCode <- runProcessingOutput (\line => do
    current <- readIORef resultRef
    if current == ""
      then writeIORef resultRef (trim line)
      else pure ()  -- Already captured first line, ignore rest
    ) cmd

  result <- readIORef resultRef
  debugPrint ("Gum returned (raw): '" ++ result ++ "'")

  let trimmedResult = if result == "" then validatedDefault else result
  debugPrint ("Final result (after default fallback): '" ++ trimmedResult ++ "'")

  -- 3. Handle gum's blank output on timeout by returning the default.
  let finalChoice = if trimmedResult == ""
                      then validatedDefault
                      else trimmedResult
  debugPrint ("Final choice: '" ++ finalChoice ++ "'")

  -- 4. Echo the result back to the screen if requested.
  when echo (putStrLn finalChoice)

  pure finalChoice

-- A robust wrapper around 'gum confirm' that returns a Bool.
--
-- @param prompt The prompt to display to the user.
-- @param defaultOption The default boolean value to return on timeout.
-- @param timeoutHundredths The timeout in hundredths of a second.
-- @param echo If true, the final choice ("Yes" or "No") is printed.
public export
TUIUserConfirm : (prompt : String) ->
                 (defaultOption : Bool) ->
                 (timeoutHundredths : Nat) ->
                 (echo : Bool) ->
                 IO Bool
TUIUserConfirm prompt defaultOption timeoutHundredths echo = do
  let defaultStr = if defaultOption then "Yes" else "No"
  let options = ["Yes", "No"]

  -- Use our robust chooser for the implementation
  resultStr <- TUIUserChoose prompt options defaultStr timeoutHundredths echo

  pure (resultStr == "Yes")
