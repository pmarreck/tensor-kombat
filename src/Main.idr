module Main

import Adapters.HTTP
import Adapters.AI
import Ports.CLI
import Core.Types

main : IO ()
main = do
  -- Run the amazing CLI interface with gum and glow!
  runCLI
