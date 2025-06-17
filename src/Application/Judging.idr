module Application.Judging

import Core.Types
import Core.Config
import Adapters.AI
import Adapters.HTTP
import Data.List
import Data.String
import Data.String.Extra

-- Define error types for judging operations
public export
data JudgingError : Type where
  ParsingError : String -> JudgingError
  AIProviderError : String -> JudgingError
  NetworkError : String -> JudgingError

public export
Show JudgingError where
  show (ParsingError msg) = "Parsing Error: " ++ msg
  show (AIProviderError msg) = "AI Provider Error: " ++ msg
  show (NetworkError msg) = "Network Error: " ++ msg

-- Score criteria record
public export
record CriteriaScore where
  constructor MkCriteriaScore
  relevance : Double
  quality : Double
  evidence : Double
  coherence : Double

public export
Eq CriteriaScore where
  (==) cs1 cs2 = cs1.relevance == cs2.relevance &&
                 cs1.quality == cs2.quality &&
                 cs1.evidence == cs2.evidence &&
                 cs1.coherence == cs2.coherence

-- Individual participant score
public export
record Score where
  constructor MkScore
  participant : DebateParticipant
  criteria : CriteriaScore
  totalScore : Double

-- Format a double to 1 decimal place
public export
formatScore : Double -> String
formatScore score =
  let multiplied = score * 10.0
      rounded = cast {to=Integer} (multiplied + 0.5)
      wholePart = rounded `div` 10
      decimalPart = rounded `mod` 10
  in show wholePart ++ "." ++ show decimalPart

public export
Show Score where
  show score =
    "🤖 " ++ show score.participant.model ++ " (" ++ show score.participant.side ++ ")\n" ++
    "   📊 Total Score: " ++ formatScore score.totalScore ++ "/40.0\n" ++
    "   📈 Breakdown: Relevance(" ++ formatScore score.criteria.relevance ++ ") " ++
    "Quality(" ++ formatScore score.criteria.quality ++ ") " ++
    "Evidence(" ++ formatScore score.criteria.evidence ++ ") " ++
    "Coherence(" ++ formatScore score.criteria.coherence ++ ")"

-- Result containing scores and verbal assessment
public export
record JudgeResult where
  constructor MkJudgeResult
  scores : List Score
  verbalAssessment : String

-- Calculate total score from criteria
public export
calculateTotalScore : CriteriaScore -> Double
calculateTotalScore criteria =
  criteria.relevance + criteria.quality + criteria.evidence + criteria.coherence

-- Generate scoring prompt for the judge
generateScoringPrompt : String -> String -> String -> String -> String
generateScoringPrompt topic debateContent p1Name p2Name =
  "You are a professional debate judge analyzing this debate on the topic: " ++ topic ++ "\n\n" ++
  "DEBATE TRANSCRIPT:\n" ++ debateContent ++ "\n\n" ++
  "Evaluate each participant based on these criteria (score 0-10 each):\n" ++
  "- RELEVANCE: How well arguments address the topic\n" ++
  "- ARGUMENT QUALITY: Strength and persuasiveness of reasoning\n" ++
  "- EVIDENCE QUALITY: Use of logical examples and reasoning\n" ++
  "- COHERENCE: Clarity and logical flow\n\n" ++
  "Provide a detailed verbal assessment for each participant, then include the exact scores.\n\n" ++
  "Include these exact score lines somewhere in your response:\n" ++
  "Participant 1 (" ++ p1Name ++ "): R=X.X Q=X.X E=X.X C=X.X\n" ++
  "Participant 2 (" ++ p2Name ++ "): R=X.X Q=X.X E=X.X C=X.X\n" ++
  "Use scores with one decimal place (e.g., 7.5, 8.0)."

-- Helper function to extract a decimal number after a pattern like "R="
extractScoreAfter : String -> String -> Maybe Double  
extractScoreAfter pattern line =
  -- Very basic approach using character-by-character parsing
  let chars = unpack line
      patternChars = unpack pattern
      findAndExtract : List Char -> Maybe Double
      findAndExtract [] = Nothing
      findAndExtract cs = 
        if take (length patternChars) cs == patternChars
          then -- Found pattern, extract digits after it
               let afterPattern = drop (length patternChars) cs
                   scoreChars = takeWhile (\c => isDigit c || c == '.') afterPattern
               in if null scoreChars
                  then findAndExtract (drop 1 cs)  -- Try next position
                  else parseDouble (pack scoreChars)
          else findAndExtract (drop 1 cs)
  in findAndExtract chars

-- Parse a score line from the judge's response
export
parseScoreLine : DebateParticipant -> DebateParticipant -> String -> Either JudgingError Score
parseScoreLine participant1 participant2 line =
  if isInfixOf "Participant 1" line
    then case (extractScoreAfter "R=" line, extractScoreAfter "Q=" line, 
               extractScoreAfter "E=" line, extractScoreAfter "C=" line) of
      (Just r, Just q, Just e, Just c) => 
        let criteria = MkCriteriaScore r q e c
            totalScore = calculateTotalScore criteria
        in Right (MkScore participant1 criteria totalScore)
      _ => Left (ParsingError ("Could not parse scores from Participant 1 line: " ++ line))
    else if isInfixOf "Participant 2" line
      then case (extractScoreAfter "R=" line, extractScoreAfter "Q=" line,
                 extractScoreAfter "E=" line, extractScoreAfter "C=" line) of
        (Just r, Just q, Just e, Just c) =>
          let criteria = MkCriteriaScore r q e c
              totalScore = calculateTotalScore criteria
          in Right (MkScore participant2 criteria totalScore)
        _ => Left (ParsingError ("Could not parse scores from Participant 2 line: " ++ line))
      else Left (ParsingError ("Line does not contain Participant 1 or Participant 2: " ++ line))

-- Parse the judge's response to extract scores and assessment
parseJudgeResponse : DebateParticipant -> DebateParticipant -> String -> Either JudgingError JudgeResult
parseJudgeResponse participant1 participant2 response = do
  let responseLines = lines response
      -- Look for lines that contain both "Participant" and scoring pattern (R= Q= E= C=)
      scoreLines = filter (\line => isInfixOf "Participant" line && 
                                   isInfixOf "R=" line && 
                                   isInfixOf "Q=" line && 
                                   isInfixOf "E=" line && 
                                   isInfixOf "C=" line) responseLines

  case scoreLines of
    [line1, line2] => do
      score1 <- parseScoreLine participant1 participant2 line1
      score2 <- parseScoreLine participant1 participant2 line2
      Right (MkJudgeResult [score1, score2] response)
    [] => 
      -- No scoring lines found, try to find any lines with Participant1/Participant2
      let allParticipantLines = filter (isInfixOf "Participant") responseLines
          participant1Lines = filter (isInfixOf "Participant 1") responseLines
          participant2Lines = filter (isInfixOf "Participant 2") responseLines
          errorMsg = "Could not find scoring lines with format 'Participant 1/2: R=X.X Q=X.X E=X.X C=X.X'. " ++
                     "Found " ++ show (length allParticipantLines) ++ " lines with 'Participant': " ++
                     show allParticipantLines ++ 
                     "\nParticipant 1 lines: " ++ show participant1Lines ++
                     "\nParticipant 2 lines: " ++ show participant2Lines ++
                     "\n\nFull response: " ++ response
      in Left (ParsingError errorMsg)
    _ => 
      let errorMsg = "Found " ++ show (length scoreLines) ++ " scoring lines, expected exactly 2: " ++
                     show scoreLines ++ "\n\nFull response: " ++ response
      in Left (ParsingError errorMsg)

-- Main judging function
public export
judgeDebate : HTTPClient => Debate -> AIModel -> IO (Either JudgingError JudgeResult)
judgeDebate debate judgeModel = do
  -- Build debate content from messages
  let debateContent = concat (map (\msg => "[" ++ show msg.speaker ++ "]: " ++ msg.content ++ "\n\n") debate.messages)
  let p1Name = show debate.participant1.model ++ " (" ++ show debate.participant1.side ++ ")"
  let p2Name = show debate.participant2.model ++ " (" ++ show debate.participant2.side ++ ")"

  -- Generate the prompt
  let scoringPrompt = generateScoringPrompt debate.topic debateContent p1Name p2Name

  -- Get judgment from AI
  putStrLn ("🤖 " ++ show judgeModel ++ " is now judging the debate...")
  result <- generateResponse judgeModel scoringPrompt

  case result of
    Left err => pure (Left (AIProviderError (show err)))
    Right aiResponse => pure (parseJudgeResponse debate.participant1 debate.participant2 aiResponse.content)

-- Generate dramatic winner declaration
public export
getApplicationLayerWinnerDeclaration : HTTPClient => Debate -> AIModel -> String -> List Score -> IO (Either JudgingError String)
getApplicationLayerWinnerDeclaration debate judgeModel topic scores = do
  case scores of
    [score1, score2] => do
      if score1.totalScore == score2.totalScore
        then do
          -- Handle tie case
          let participant1Name = show score1.participant.model ++ " (" ++ show score1.participant.side ++ ")"
          let participant2Name = show score2.participant.model ++ " (" ++ show score2.participant.side ++ ")"

          let tiePrompt =
            "The topic was: " ++ topic ++ "\n" ++
            "RESULT: TIE between " ++ participant1Name ++ " and " ++ participant2Name ++ "\n\n" ++
            "Generate a dramatic tie announcement in the style of a wrestling announcer. " ++
            "Emphasize that both participants fought valiantly and it was too close to call. " ++
            "Use hyperbolic language and ALL CAPS for emphasis. " ++
            "Keep it to 2-3 sentences maximum."

          result <- generateResponse judgeModel tiePrompt
          case result of
            Left err => pure (Left (AIProviderError (show err)))
            Right response => pure (Right response.content)
        else do
          -- Handle winner/loser case
          let (winner, loser) = if score1.totalScore > score2.totalScore
                               then (score1.participant, score2.participant)
                               else (score2.participant, score1.participant)

          let winnerName = show winner.model ++ " (" ++ show winner.side ++ ")"
          let loserName = show loser.model ++ " (" ++ show loser.side ++ ")"

          let declarationPrompt =
            "The topic was: " ++ topic ++ "\n" ++
            "WINNER: " ++ winnerName ++ "\n" ++
            "LOSER: " ++ loserName ++ "\n\n" ++
            "Generate a dramatic, over-the-top winner announcement in the style of a wrestling announcer. " ++
            "Use hyperbolic language, ALL CAPS for emphasis, and creative metaphors. " ++
            "Make it entertaining and tailored to this specific debate topic. " ++
            "Keep it to 2-3 sentences maximum."

          result <- generateResponse judgeModel declarationPrompt
          case result of
            Left err => pure (Left (AIProviderError (show err)))
            Right aiResponse => pure (Right aiResponse.content)

    _ => pure (Right "🏆 The debate concludes with honor to all participants!")
