package net.fortytwo.smsn.flashcards.decks.tech;

import net.fortytwo.smsn.flashcards.Card;
import net.fortytwo.smsn.flashcards.Deck;
import net.fortytwo.smsn.flashcards.db.CardStore;
import net.fortytwo.smsn.flashcards.db.CloseableIterator;
import net.fortytwo.smsn.flashcards.decks.Answer;
import net.fortytwo.smsn.flashcards.decks.AnswerFormatter;
import net.fortytwo.smsn.flashcards.decks.InformationSource;
import net.fortytwo.smsn.flashcards.decks.QuestionFormatter;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

/**
 * @author Joshua Shinavier (http://fortytwo.net)
 */
public class MorseCode extends Deck<String, String> {
    private final CardStore<String, String> store;
    private final InformationSource source;

    public MorseCode(final Format format,
                     final CardStore<String, String> store) throws IOException {
        super("morse_code", "Morse Code");
        this.store = store;

        source = new InformationSource("Morse Code Character Table");
        source.setUrl("http://www.csgnetwork.com/morsecodechrtbl.html");

        InputStream is = MorseCode.class.getResourceAsStream("morse_code.txt");
        try {
            BufferedReader br = new BufferedReader(new InputStreamReader(is));
            String l;
            while ((l = br.readLine()) != null) {
                l = l.trim();
                if (0 < l.length()) {
                    String a[] = l.split(" ");
                    final String symbol = a[0];
                    final String code = a[1];

                    Card<String, String> card1 = new Card<String, String>(symbol, this) {
                        @Override
                        public String getQuestion() {
                            String sb = "\"" + symbol + "\" = <code>?";

                            QuestionFormatter f = new QuestionFormatter(deck, format);
                            f.setQuestion(sb);
                            return f.format();
                        }

                        @Override
                        public String getAnswer() {
                            AnswerFormatter f = new AnswerFormatter(format);
                            Answer a = new Answer();
                            f.addAnswer(a);
                            a.setSource(source);
                            a.setMeaning(code);
                            return f.format();
                        }
                    };

                    Card<String, String> card2 = new Card<String, String>(code, this) {
                        @Override
                        public String getQuestion() {
                            String sb = "<symbol>? = " + code;

                            QuestionFormatter f = new QuestionFormatter(deck, format);
                            f.setQuestion(sb);
                            return f.format();
                        }

                        @Override
                        public String getAnswer() {
                            AnswerFormatter f = new AnswerFormatter(format);
                            Answer a = new Answer();
                            f.addAnswer(a);
                            a.setSource(source);
                            a.setMeaning(symbol);
                            return f.format();
                        }
                    };

                    store.add(card1);
                    store.add(card2);
                }
            }
        } finally {
            is.close();
        }
    }

    @Override
    public Card<String, String> getCard(final String name) {
        return store.find(this, name);
    }

    @Override
    public CloseableIterator<Card<String, String>> getCards() {
        return store.findAll(this);
    }
}
