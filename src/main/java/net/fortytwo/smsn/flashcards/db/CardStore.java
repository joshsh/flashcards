package net.fortytwo.smsn.flashcards.db;

import net.fortytwo.smsn.flashcards.Card;
import net.fortytwo.smsn.flashcards.Deck;

import java.io.IOException;

/**
 * @author Joshua Shinavier (http://fortytwo.net)
 */
public interface CardStore<Q, A> {
    void add(Card<Q, A> card) throws IOException;

    Card<Q, A> find(Deck<Q, A> deck,
                    String cardName);

    CloseableIterator<Card<Q, A>> findAll(Deck<Q, A> deck);

    void clear();
}
