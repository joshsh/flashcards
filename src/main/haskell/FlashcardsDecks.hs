module FlashcardsDecks
  ( countryCapitalsDeck
  , categoryTheoryDeck ) where

import Flashcards

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


hasNull :: [[a]] -> Bool
hasNull vals = L.foldl (\m v -> m || L.null v) False vals

loadDeck :: FilePath -> ([String] -> Maybe a) -> ([a] -> Deck) -> IO Deck
loadDeck file fromEntry toDeck = do
  rows <- loadTsv True file
  putStrLn $ "loaded " ++ (show $ L.length rows) ++ " rows"
  let entries = Y.catMaybes $ fmap fromEntry rows
  putStrLn $ "created " ++ (show $ L.length entries) ++ " entries"
  let deck = toDeck entries
  putStrLn $ "created deck of " ++ (show $ L.length $ M.elems $ deckCards deck) ++ " cards"
  return deck

toDeck :: String -> (Deck -> a -> Card) -> [a] -> Deck
toDeck deckId toCard entries = deck
  where
    deck = Deck deckId cardMap
    cards = fmap (toCard deck) entries
    cardMap = L.foldl (\m c -> M.insert (cardId c) c m) M.empty cards

{------------------------------------------------------------------------------}

data CountryCapital = CountryCapital
  { ccCountryIri   :: String
  , ccCapitalIri   :: String
  , ccCountryLabel :: String
  , ccCapitalLabel :: String } deriving Show

capitalsDeckId = "jx6tbUdmmHmX8Qms"

toCountryCapitalEntry :: [String] -> Maybe CountryCapital
toCountryCapitalEntry (_:_:capitalLabel:capital:country:countryLabel:_)
  = if hasNull [capitalLabel, capital, country, countryLabel]
  then Nothing
  else Just $ CountryCapital country capital countryLabel capitalLabel
toCountryCapitalEntry _ = Nothing

toCountryCapitalCard :: Deck -> CountryCapital -> Card
toCountryCapitalCard deck (CountryCapital country _ countryLabel capitalLabel) = Card id deck front reverse
  where
    id = country
    front = "What is the capital of " ++ countryLabel ++ "?"
    reverse = capitalLabel

countryCapitalsDeck :: IO Deck
countryCapitalsDeck = loadDeck "/tmp/country-capitals.tsv" toCountryCapitalEntry
  $ toDeck capitalsDeckId toCountryCapitalCard

{------------------------------------------------------------------------------}

data Question
  = DefinitionQuestion String String
  | FreeFormQuestion String String

categoryTheoryDeckId = "sYTqbtAGaWtVhrAn"

toQuestion :: [String] -> Maybe Question
toQuestion (_:_:qtype:question:answer:_) = if hasNull [qtype, question, answer]
  then Nothing
  else Just $ if qtype == "definition"
    then DefinitionQuestion question answer
    else FreeFormQuestion question answer
toQuestion _ = Nothing

toQuestionCard :: Deck -> Question -> Card
toQuestionCard deck (DefinitionQuestion term answer) = Card id deck front reverse
  where
    id = term -- TODO
    front = "Define '" ++ term ++ "'"
    reverse = answer
toQuestionCard deck (FreeFormQuestion question answer) = Card id deck question answer
  where
    id = question -- TODO

categoryTheoryDeck :: IO Deck
categoryTheoryDeck = loadDeck "/tmp/flashcards from Category Theory for Programmers - Sheet1.tsv"
  toQuestion $ toDeck categoryTheoryDeckId toQuestionCard

{------------------------------------------------------------------------------}
