module Adapters.HTTP

import System
import System.File
import System.File.Process
import System.Clock
import Data.String
import Data.IORef

-- HTTP response record
public export
record HTTPResponse where
  constructor MkHTTPResponse
  statusCode : Int
  body : String
  headers : String

public export
Show HTTPResponse where
  show resp = "HTTPResponse(status=" ++ show resp.statusCode ++ ", bodyLength=" ++ show (length resp.body) ++ ")"

-- HTTP client interface
public export
interface HTTPClient where
  httpPost : String -> List (String, String) -> String -> IO (Either String HTTPResponse)
  getEnvVar : String -> IO (Maybe String)

-- Simple string replacement for escaping
simpleReplace : Char -> String -> String -> String
simpleReplace c replacement s =
  let chars = unpack s
      replaceChar : Char -> String
      replaceChar ch = if ch == c then replacement else singleton ch
  in concat (map replaceChar chars)

-- Escape string for shell command
escapeShell : String -> String
escapeShell s = "'" ++ (simpleReplace '\'' "'\"'\"'" s) ++ "'"

-- Convert headers to curl arguments
headersToArgs : List (String, String) -> String
headersToArgs [] = ""
headersToArgs ((key, value) :: rest) =
  " -H " ++ escapeShell (key ++ ": " ++ value) ++ headersToArgs rest

-- Implementation using system curl command with process pipes (no temp files)
public export
HTTPClient where
  httpPost url headers body = do
    -- Build curl command using stdin for body
    let headerArgs = headersToArgs headers
    let curlCmd = "printf '%s' " ++ escapeShell body ++ " | curl -s -w '\\n%{http_code}' -X POST" ++ headerArgs ++
                  " -d @- '" ++ url ++ "'"

    -- Use runProcessingOutput to capture curl output directly
    outputRef <- newIORef ""
    exitCode <- runProcessingOutput (\line => modifyIORef outputRef (++ line ++ "\n")) curlCmd

    output <- readIORef outputRef

    -- Parse output - last line should be status code
    let outputLines = lines output
    case reverse outputLines of
      [] => pure (Left "Empty curl output")
      (statusLine :: bodyLines) =>
        let statusCode = case parseInteger (trim statusLine) of
                           Just code => cast code
                           Nothing => 0
            responseBody = unlines (reverse bodyLines)
        in pure (Right (MkHTTPResponse statusCode responseBody ""))

  where
    takeLast : Nat -> String -> String
    takeLast n s =
      let chars = unpack s
          len = length chars
      in if len >= n
         then pack (reverse (take n (reverse chars)))
         else s

    dropLast : Nat -> String -> String
    dropLast n s =
      let chars = unpack s
          len = length chars
      in if len >= n
         then pack (reverse (drop n (reverse chars)))
         else s

  getEnvVar name = do
    -- Debug output to see what's happening
    debugMode <- system "test \"${DEBUG:-}\" = \"true\" -o \"${DEBUG:-}\" = \"1\""
    case debugMode of
      0 => putStrLn ("🐛 DEBUG HTTP: Getting env var " ++ name)
      _ => pure ()

    -- Use current time in nanoseconds for unique filename
    time <- clockTime UTC
    let uniqueId = show (nanoseconds time)
    let envFile = "/tmp/tensor_kombat_env_" ++ uniqueId ++ ".txt"
    result <- System.system ("printf \"%s\" \"$" ++ name ++ "\" > " ++ envFile ++ " 2>/dev/null")
    envContent <- readFile envFile
    ignore $ System.system ("rm -f " ++ envFile)

    case envContent of
      Right content => do
        let trimmedContent = trim content
        case debugMode of
          0 => putStrLn ("🐛 DEBUG HTTP: " ++ name ++ " = '" ++ trimmedContent ++ "' (length: " ++ show (length trimmedContent) ++ ")")
          _ => pure ()
        if length trimmedContent == 0
          then pure Nothing
          else pure (Just trimmedContent)
      Left _ => do
        case debugMode of
          0 => putStrLn ("🐛 DEBUG HTTP: " ++ name ++ " = ERROR reading file")
          _ => pure ()
        pure Nothing
