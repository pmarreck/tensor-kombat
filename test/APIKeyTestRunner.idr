module APIKeyTestRunner

import System
import Adapters.HTTP
import Integration.APIKeyVerificationTest

export
main : IO ()
main = do
  success <- runAPIKeyVerificationTest
  
  putStrLn ""
  if success
    then do
      putStrLn "✅ API Key verification completed successfully"
      exitSuccess
    else do
      putStrLn "❌ Some API keys failed verification"
      exitWith (ExitFailure 1)