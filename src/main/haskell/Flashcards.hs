module Flashcards
  ( DeckId
  , CardId
  , Deck(..)
  , Card(..)
  , loadTsv, trim -- TODO: move to utilities
  , flashcards ) where

import qualified Control.Exception     as CE
import qualified Control.Monad         as CM
import qualified System.Directory      as D
import qualified Data.Int              as I
import qualified System.IO             as IO
import qualified Data.List             as L
import qualified Data.List.Split       as LS
import qualified Data.Map              as M
import qualified System.Random.Shuffle as RS
import qualified Data.Set              as S
import qualified Data.Time.Clock.POSIX as TCP
import qualified Data.Maybe            as Y


-- TODO: use Text instead of String
-- TODO: use file handles

type DeckId = String
type CardId = String
type UnixTime = I.Int64
type TimeStep = I.Int64
type Delay = I.Int64
type Stack = [CardInStack]

data LogEntry = LogEntry
  { logEntryTime  :: UnixTime
  , logEntryDeck  :: Deck
  , logEntryCard  :: Card
  , logEntryDelay :: Delay } deriving Show

data Deck = Deck
  { deckId    :: DeckId
  , deckCards :: M.Map CardId Card }
instance Show Deck
  where
    show d = "deck:" ++ deckId d

data Card = Card
  { cardId      :: CardId
  , cardDeck    :: Deck
  , cardFront   :: String
  , cardReverse :: String }
instance Show Card
  where
    show c = "card:" ++ (deckId $ cardDeck c) ++ ":" ++ cardId c
instance Eq Card where
  c1 == c2 = (cardId c1 == cardId c2)
instance Ord Card where
  c1 `compare` c2 = (cardId c1) `compare` (cardId c2)

data CardInStack = CardInStack
  { inStackCard    :: Card
  , inStackDueTime :: TimeStep
  , inStackPeriod  :: Delay } deriving Show

data Game = Game
  { timeStep  :: TimeStep
  , usedCards :: S.Set Card
  , gameQueue :: [Card]
  , gameStack :: [CardInStack] }
instance Show Game
  where
    show (Game ts _ _ _) = "game:" ++ show ts

data FlashcardsError
  = NoSuchDeck DeckId
  | NoSuchCard Deck CardId
  | InvalidResponse String deriving Show
instance CE.Exception FlashcardsError

data Response = Correct | Incorrect | Quit deriving Eq

trim :: String -> String
trim = trimHead . L.reverse . trimHead . L.reverse
  where
    trimHead [] = []
    trimHead (' ':rest) = rest
    trimHead s = s

loadTsv :: Bool -> FilePath -> IO [[String]]
loadTsv skipHeader path = do
  contents <- IO.readFile path
  let entries = fmap (\line -> LS.splitOn "\t" $ trim line) $ L.lines contents
  let rows = fmap (fmap trim) $ (if skipHeader then L.tail entries else entries)
  return rows

toEntry :: M.Map DeckId Deck -> [String] -> Maybe LogEntry
toEntry decks row = toE row
  where
    toE [ts, d, c, l] = Just $ LogEntry time deck card delay
      where
        time = read ts
        deck = Y.fromMaybe noSuchDeck $ M.lookup d decks
        delay = read l
        card = Y.fromMaybe noSuchCard $ M.lookup c $ deckCards deck
        noSuchDeck = CE.throw $ NoSuchDeck d
        noSuchCard = CE.throw $ NoSuchCard deck c
    toE _ = Nothing -- note: silent fail on non-empty by badly-formatted lines

loadHistory :: FilePath -> M.Map DeckId Deck -> IO [LogEntry]
loadHistory logFile decks = do
  IO.putStrLn $ "loading log from file " ++ logFile
  lines <- loadTsv False logFile
  let entries = Y.catMaybes $ fmap (toEntry decks) lines
  return entries

tryLoadingHistory :: FilePath -> M.Map DeckId Deck -> IO [LogEntry]
tryLoadingHistory logFile decks = do
  exists <- D.doesFileExist logFile
  result <- if exists
    then loadHistory logFile decks
    else do {
      IO.putStrLn $ "log file not found at " ++ logFile;
      return [] }
  return result

addHistory :: [LogEntry] -> Game -> Game
addHistory history game = L.foldl advance game history

insertIntoStack :: [CardInStack] -> Card -> TimeStep -> Delay -> [CardInStack]
insertIntoStack stack card dueTime delay = forStack stack
  where
    cis = CardInStack card dueTime delay
    forStack [] = [cis]
    forStack (first:rest) = if (dueTime < inStackDueTime first)
      then cis:first:rest
      else first:(forStack rest)

advance :: Game -> LogEntry -> Game
advance (Game ts used queue stack) (LogEntry time deck card delay)
  = incrementTimeStep $ Game ts used' queue stack'
  where
    ts' = ts + 1
    used' = S.insert card used
    stack' = insertIntoStack stack card (ts + delay) delay

incrementTimeStep :: Game -> Game
incrementTimeStep (Game ts used unused stack)
  = Game (ts + 1) used unused stack

shuffle :: [Deck] -> IO [Card]
shuffle decks = do
  let allCards = L.concat $ fmap (M.elems . deckCards) decks
  shuffled <- RS.shuffleM allCards
  return shuffled

decksToMap :: [Deck] -> M.Map DeckId Deck
decksToMap decks = L.foldl addDeck M.empty decks
  where
    addDeck m d = M.insert (deckId d) d m

pickCard :: Game -> (CardInStack, Game)
pickCard game = if stackIsReady then pickFromStack else pickFromQueue
  where
    Game ts used queue stack = game
    stackIsReady = if L.null stack
      then False
      else (inStackDueTime $ L.head stack) <= ts
    -- Expired card exists at the top of the stack. Choose this card without pulling from the queue.
    pickFromStack = (L.head stack, Game ts used queue (L.tail stack))
    -- Stack is empty, or topmost card on the stack is not expired. Try to pull from the queue.
    pickFromQueue = Y.maybe earlyPickFromStack fromTop top
      where
        (top, queue') = fromQueue queue
        fromQueue :: [Card] -> (Maybe Card, [Card])
        fromQueue [] = (Nothing, [])
        fromQueue (first:rest) = if (S.member first used) then (fromQueue rest) else (Just first, rest)
        fromTop c = (CardInStack c ts 1, Game ts used queue' stack)
    -- Queue is empty. Pull from the stack even though the topmost item is not expired.
    earlyPickFromStack = (L.head stack, Game ts used queue (L.tail stack))

readResponse :: String -> Response
readResponse "yes" = Correct
readResponse "y" = Correct
readResponse "i" = Correct
readResponse "no" = Incorrect
readResponse "n" = Incorrect
readResponse "quit" = Quit
readResponse "q" = Quit
readResponse s = CE.throw $ InvalidResponse s

forResponse :: UnixTime -> CardInStack -> Bool -> LogEntry
forResponse time picked correct = LogEntry time deck card delay
  where
    deck = cardDeck card
    card = inStackCard picked
    delay = if correct then 3 * (inStackPeriod picked) else 1

markAsUsed :: CardInStack -> Game -> Game
markAsUsed (CardInStack c _ _) (Game ts used queue stack) = Game ts (S.insert c used) queue stack

getCurrentTime :: IO UnixTime
getCurrentTime = do
  t <- TCP.getPOSIXTime
  let ms = floor $ t * 1000
  return ms

loop :: Game -> IO Game
loop game0 = do
  let (picked, game1) = pickCard game0
  let game2 = markAsUsed picked game1
  putStr $ "Q: " ++ (cardFront $ inStackCard picked)
  getLine
  putStrLn $ "A: " ++ (cardReverse $ inStackCard picked)
  putStr "Correct (y/n/q)? "
  responseLine <- getLine
  let response = readResponse responseLine
  currentTime <- getCurrentTime
  result <- if response == Quit
    then do { return game0 }
    else do
      let entry = forResponse currentTime picked (response == Correct) :: LogEntry
      let game3 = advance game2 entry
      game4 <- loop game3
      return game4
  return result

prettyPrintDeck :: Deck -> String
prettyPrintDeck (Deck id cards) = L.foldl appendCard id $ M.elems cards
  where
    appendCard s c = s ++ "\n  " ++ showCard c
    showCard (Card id _ front reverse) = show [id, front, reverse]

flashcards :: Deck -> IO Game
flashcards deck = do
  let logFile = "/tmp/flashcards.log.tsv"
  -- IO.putStrLn $ prettyPrintDeck deck
  let decks = [deck]
  let deckMap = decksToMap decks
  history <- tryLoadingHistory logFile deckMap
  queue <- shuffle decks
  let game0 = Game 0 S.empty queue []
  let game1 = addHistory history game0
  game2 <- loop game1
  return game2
