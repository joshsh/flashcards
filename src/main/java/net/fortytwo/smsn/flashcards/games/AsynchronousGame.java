package net.fortytwo.smsn.flashcards.games;

import net.fortytwo.smsn.flashcards.Card;
import net.fortytwo.smsn.flashcards.Game;
import net.fortytwo.smsn.flashcards.GameplayException;
import net.fortytwo.smsn.flashcards.Pile;
import net.fortytwo.smsn.flashcards.Trial;
import net.fortytwo.smsn.flashcards.db.GameHistory;

/**
 * @author Joshua Shinavier (http://fortytwo.net)
 */
public abstract class AsynchronousGame<Q, A> extends Game<Q, A> {
    private Card<Q, A> current;

    public AsynchronousGame(final Pile<Q, A> pile,
                            final GameHistory history) {
        super(pile, history);
    }

    public abstract void nextQuestion(Card<Q, A> current);

    @Override
    public void play() throws GameplayException {
        nextCard();
    }

    private void nextCard() {
        // Only if no cards have yet been drawn, or if the previous card has been replaced, do we draw a new card.
        // This is not the case at the beginning of the game, or when the user has left and subsequently restarted the game.
        if (null == current) {
            current = drawCard();
        }

        nextQuestion(current);
    }

    public void correct() throws GameplayException {
        logAndReplace(current, Trial.Result.Correct);
        current = null;
        nextCard();
    }

    public void incorrect() throws GameplayException {
        logAndReplace(current, Trial.Result.Incorrect);
        current = null;
        nextCard();
    }
}
