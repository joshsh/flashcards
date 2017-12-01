package net.fortytwo.smsn.flashcards.db;

import net.fortytwo.smsn.flashcards.Card;
import net.fortytwo.smsn.flashcards.Deck;

import java.io.IOException;

/**
 * @author Joshua Shinavier (http://fortytwo.net)
 */
public interface CardSerializer<Q, A> {
    String serialize(Card<Q, A> card) throws IOException;

    Card<Q, A> deserialize(String name,
                           Deck<Q, A> deck,
                           String data) throws IOException;
}
