module TestRunner

import Core.TypesTest
import Adapters.AITest
import Ports.CLITest
import Integration.DebateTest
import Integration.TimeoutTest
import Integration.LLMConnectivityTest

main : IO ()
main = do
  putStrLn "🚀 Tensor-Kombat Test Suite"
  putStrLn "============================"
  putStrLn ""

  -- Run all tests
  runAllTypesTests
  putStrLn ""
  runAITests
  putStrLn ""
  runCLITests
  putStrLn ""
  runIntegrationTests
  putStrLn ""
  runTimeoutTests
  putStrLn ""
  runLLMConnectivityTests

  putStrLn ""
  putStrLn "✅ All test suites completed!"
