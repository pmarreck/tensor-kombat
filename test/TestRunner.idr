module TestRunner

import Core.TypesTest
import Adapters.AITest
import Application.JudgingTest
import Ports.CLITest
import Ports.TUITest
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
  runJudgingTests
  putStrLn ""
  runCLITests
  putStrLn ""
  runTUITests
  putStrLn ""
  runIntegrationTests
  putStrLn ""
  runTimeoutTests
  putStrLn ""
  runLLMConnectivityTests

  putStrLn ""
  putStrLn "✅ All test suites completed!"
