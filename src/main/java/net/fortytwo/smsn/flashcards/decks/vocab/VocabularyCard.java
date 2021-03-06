package net.fortytwo.smsn.flashcards.decks.vocab;

import net.fortytwo.smsn.flashcards.Card;
import net.fortytwo.smsn.flashcards.Deck;
import net.fortytwo.smsn.flashcards.decks.Answer;
import net.fortytwo.smsn.flashcards.decks.AnswerFormatter;
import net.fortytwo.smsn.flashcards.decks.QuestionFormatter;

import java.util.List;

/**
 * @author Joshua Shinavier (http://fortytwo.net)
 */
class VocabularyCard extends Card<String, String> {
    private final List<Term> definitions;
    private VocabularyDeck.Format format;

    public VocabularyCard(final String name,
                          final Deck deck,
                          final List<Term> definitions,
                          final VocabularyDeck.Format format) {
        super(name, deck);
        this.definitions = definitions;
        this.format = format;
    }

    public List<Term> getDefinitions() {
        return definitions;
    }

    @Override
    public String getQuestion() {
        String question = definitions.get(0).getForms().get(0) + " = ?";

        QuestionFormatter f = new QuestionFormatter(deck, format);
        f.setQuestion(question);
        return f.format();
    }

    @Override
    public String getAnswer() {
        AnswerFormatter f = new AnswerFormatter(format);

        for (Term t : definitions) {
            Answer a = new Answer();
            f.addAnswer(a);
            if (null != t.getSource()) {
                a.setSource(t.getSource());
            }

            for (String form : t.getForms()) {
                a.addForm(form);
            }

            a.setPronuncation(t.getPronunciation());
            a.setType(t.getType());
            a.setMeaning(t.getMeaning());
        }

        return f.format();
    }

    @Override
    public String toString() {
        return definitions.get(0).getForms().get(0);
    }
}
