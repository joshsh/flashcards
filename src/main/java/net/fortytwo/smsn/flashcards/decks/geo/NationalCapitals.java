package net.fortytwo.smsn.flashcards.decks.geo;

import net.fortytwo.smsn.flashcards.Card;
import net.fortytwo.smsn.flashcards.Deck;
import net.fortytwo.smsn.flashcards.db.CloseableIterator;
import net.fortytwo.smsn.flashcards.db.TrivialCloseableIterator;
import net.fortytwo.smsn.flashcards.decks.Answer;
import net.fortytwo.smsn.flashcards.decks.AnswerFormatter;
import net.fortytwo.smsn.flashcards.decks.QuestionFormatter;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * @author Joshua Shinavier (http://fortytwo.net)
 */
public class NationalCapitals extends Deck<String, String> {
    private final Map<String, Card<String, String>> cards = new HashMap<String, Card<String, String>>();
    private final Format format;

    public NationalCapitals(final Format format) throws IOException {
        super("national_capitals", "national capitals");
        this.format = format;

        for (Countries.Country c : Countries.getInstance().getCountries()) {
            Card<String, String> card = new LocalCard(c, this);
            cards.put(card.getName(), card);
        }
    }

    @Override
    public Card<String, String> getCard(final String name) {
        return cards.get(name);
    }

    @Override
    public CloseableIterator<Card<String, String>> getCards() {
        return new TrivialCloseableIterator<Card<String, String>>(cards.values().iterator());
    }

    private class LocalCard extends Card<String, String> {
        private final Countries.Country country;

        public LocalCard(final Countries.Country country,
                         final Deck deck) {
            super(country.code, deck);
            this.country = country;
        }

        @Override
        public String getQuestion() {
            String question = "What is the capital city of " + country.name + "?";
            QuestionFormatter f = new QuestionFormatter(deck, format);
            f.setQuestion(question);
            return f.format();
        }

        @Override
        public String getAnswer() {
            String answer = country.capitalCity.name;

            AnswerFormatter f = new AnswerFormatter(format);
            Answer a = new Answer();
            a.setSource(Countries.getInstance().getSource());
            a.addForm(answer);
            f.addAnswer(a);
            return f.format();
        }

        @Override
        public String toString() {
            return country.name;
        }
    }
}
